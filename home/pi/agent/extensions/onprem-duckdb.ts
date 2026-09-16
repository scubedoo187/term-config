import { spawn } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const DEFAULT_CONFIG_PATH = join(homedir(), ".pi", "agent", "onprem-duckdb.json");
const DEFAULT_WRAPPER = join(homedir(), ".local", "bin", "onprem-duckdb-query");
const DEFAULT_EXEC_WRAPPER = join(homedir(), ".local", "bin", "onprem-exec");
const DEFAULT_STATUS_WRAPPER = join(homedir(), ".local", "bin", "onprem-status");
const DEFAULT_TIMEOUT_MS = 300_000;
const DEFAULT_MAX_BYTES = 1_000_000;

const QueryParams = Type.Object({
	sql: Type.String({ description: "Read-only DuckDB SQL to execute on onprem via dlk shell --local." }),
	timeoutMs: Type.Optional(Type.Number({ description: "Timeout in milliseconds. Default 60000." })),
	maxBytes: Type.Optional(Type.Number({ description: "Maximum stdout/stderr bytes returned. Default 200000." })),
});

const CheckParams = Type.Object({});

const ExecParams = Type.Object({
	cwd: Type.String({ description: "Remote working directory to cd into before running the command." }),
	command: Type.String({ description: "Guarded read-oriented command to run. No shell chains, redirects, pipes, or destructive commands." }),
	timeoutMs: Type.Optional(Type.Number({ description: "Timeout in milliseconds. Default 60000." })),
	maxBytes: Type.Optional(Type.Number({ description: "Maximum stdout/stderr bytes returned. Default 200000." })),
});

const StatusParams = Type.Object({
	section: Type.Optional(Type.Union([
		Type.Literal("all"),
		Type.Literal("host"),
		Type.Literal("docker"),
		Type.Literal("redis"),
		Type.Literal("postgres"),
		Type.Literal("storage"),
		Type.Literal("network"),
		Type.Literal("services"),
	], { description: "Status section to collect. Default all." })),
	detail: Type.Optional(Type.Union([Type.Literal("summary"), Type.Literal("detailed")], { description: "Collection detail level. Default summary." })),
	maxScanKeys: Type.Optional(Type.Number({ description: "Maximum Redis keys to scan for detailed Redis checks. Default 10000." })),
	includeSamples: Type.Optional(Type.Boolean({ description: "Whether to include bounded samples when supported. Default false." })),
	timeoutMs: Type.Optional(Type.Number({ description: "Timeout in milliseconds. Default 60000." })),
	maxBytes: Type.Optional(Type.Number({ description: "Maximum stdout/stderr bytes returned. Default 200000." })),
});

function stripSqlComments(sql: string): string {
	return sql.replace(/--.*?(?=\n|$)/g, " ").replace(/\/\*[\s\S]*?\*\//g, " ").trim();
}

function assertReadOnlySql(sql: string) {
	const cleaned = stripSqlComments(sql).replace(/^\(+/, "").trim().toLowerCase();
	const allowedStarts = ["select", "with", "show", "describe", "desc", "explain", "pragma table_info", "pragma database_list", "pragma show", "summarize"];
	const blocked = /\b(insert|update|delete|drop|create|alter|copy|export|attach|install|load|call|truncate|merge|replace|vacuum)\b/i;
	if (!allowedStarts.some((prefix) => cleaned.startsWith(prefix)) || blocked.test(cleaned)) {
		throw new Error("Refusing non-read-only SQL. Allowed starts: SELECT/WITH/SHOW/DESCRIBE/EXPLAIN/limited PRAGMA/SUMMARIZE.");
	}
}

function getConfigSummary(): string {
	const path = process.env.ONPREM_DUCKDB_CONFIG || DEFAULT_CONFIG_PATH;
	if (!existsSync(path)) {
		return `missing config: ${path}`;
	}
	try {
		const cfg = JSON.parse(readFileSync(path, "utf8"));
		const ssh = typeof cfg.ssh === "object" && cfg.ssh ? cfg.ssh : {};
		const host = cfg.host || ssh.host || "<missing-host>";
		const user = cfg.user || ssh.user || "yg.jung";
		return `config=${path}\nmode=${cfg.mode || "ssh-dlk-local"}\ntarget=${user}@${host}\nworkdir=${cfg.workdir || "<missing-workdir>"}\ndlkCommand=${cfg.dlkCommand || "./dlk shell --local"}`;
	} catch (err) {
		return `invalid config ${path}: ${err instanceof Error ? err.message : String(err)}`;
	}
}

async function runWrapper(args: string[], stdin: string | undefined, timeoutMs: number, maxBytes: number, signal?: AbortSignal) {
	const wrapper = process.env.ONPREM_DUCKDB_WRAPPER || DEFAULT_WRAPPER;
	if (!existsSync(wrapper)) {
		throw new Error(`Missing wrapper: ${wrapper}`);
	}

	return await new Promise<{ stdout: string; stderr: string; exitCode: number | null; timedOut: boolean; truncated: boolean }>((resolve, reject) => {
		const child = spawn(wrapper, args, {
			stdio: [stdin === undefined ? "ignore" : "pipe", "pipe", "pipe"],
			env: {
				...process.env,
				ONPREM_DUCKDB_TIMEOUT_SECONDS: String(Math.max(1, Math.ceil(timeoutMs / 1000))),
				ONPREM_DUCKDB_MAX_BYTES: String(maxBytes),
			},
		});

		let stdout = "";
		let stderr = "";
		let truncated = false;
		let settled = false;
		let timedOut = false;

		const append = (kind: "stdout" | "stderr", chunk: Buffer) => {
			const text = chunk.toString("utf8");
			const current = kind === "stdout" ? stdout : stderr;
			if (current.length + text.length > maxBytes) {
				truncated = true;
				const remaining = Math.max(0, maxBytes - current.length);
				if (kind === "stdout") stdout += text.slice(0, remaining);
				else stderr += text.slice(0, remaining);
				return;
			}
			if (kind === "stdout") stdout += text;
			else stderr += text;
		};

		const timer = setTimeout(() => {
			timedOut = true;
			child.kill("SIGTERM");
			setTimeout(() => child.kill("SIGKILL"), 2000).unref();
		}, timeoutMs);
		if (signal) {
			if (signal.aborted) child.kill("SIGTERM");
			signal.addEventListener("abort", () => child.kill("SIGTERM"), { once: true });
		}

		child.stdout.on("data", (chunk) => append("stdout", chunk));
		child.stderr.on("data", (chunk) => append("stderr", chunk));
		child.on("error", (err) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			reject(err);
		});
		child.on("close", (code) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			resolve({ stdout, stderr, exitCode: code, timedOut, truncated });
		});

		if (stdin !== undefined && child.stdin) {
			child.stdin.write(stdin);
			child.stdin.end();
		}
	});
}

async function runStatusWrapper(params: { section?: string; detail?: string; maxScanKeys?: number; includeSamples?: boolean }, timeoutMs: number, maxBytes: number, signal?: AbortSignal) {
	const wrapper = process.env.ONPREM_STATUS_WRAPPER || DEFAULT_STATUS_WRAPPER;
	if (!existsSync(wrapper)) {
		throw new Error(`Missing wrapper: ${wrapper}`);
	}
	const args = ["--section", params.section ?? "all", "--detail", params.detail ?? "summary", "--max-scan-keys", String(params.maxScanKeys ?? 10_000)];
	if (params.includeSamples) args.push("--include-samples");

	return await new Promise<{ stdout: string; stderr: string; exitCode: number | null; timedOut: boolean; truncated: boolean }>((resolve, reject) => {
		const child = spawn(wrapper, args, {
			stdio: ["ignore", "pipe", "pipe"],
			env: {
				...process.env,
				ONPREM_STATUS_TIMEOUT_SECONDS: String(Math.max(1, Math.ceil(timeoutMs / 1000))),
				ONPREM_STATUS_MAX_BYTES: String(maxBytes),
			},
		});

		let stdout = "";
		let stderr = "";
		let truncated = false;
		let settled = false;
		let timedOut = false;

		const append = (kind: "stdout" | "stderr", chunk: Buffer) => {
			const text = chunk.toString("utf8");
			const current = kind === "stdout" ? stdout : stderr;
			if (current.length + text.length > maxBytes) {
				truncated = true;
				const remaining = Math.max(0, maxBytes - current.length);
				if (kind === "stdout") stdout += text.slice(0, remaining);
				else stderr += text.slice(0, remaining);
				return;
			}
			if (kind === "stdout") stdout += text;
			else stderr += text;
		};

		const timer = setTimeout(() => {
			timedOut = true;
			child.kill("SIGTERM");
			setTimeout(() => child.kill("SIGKILL"), 2000).unref();
		}, timeoutMs);
		if (signal) {
			if (signal.aborted) child.kill("SIGTERM");
			signal.addEventListener("abort", () => child.kill("SIGTERM"), { once: true });
		}

		child.stdout.on("data", (chunk) => append("stdout", chunk));
		child.stderr.on("data", (chunk) => append("stderr", chunk));
		child.on("error", (err) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			reject(err);
		});
		child.on("close", (code) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			resolve({ stdout, stderr, exitCode: code, timedOut, truncated });
		});
	});
}

async function runExecWrapper(cwd: string, command: string, timeoutMs: number, maxBytes: number, signal?: AbortSignal) {
	const wrapper = process.env.ONPREM_EXEC_WRAPPER || DEFAULT_EXEC_WRAPPER;
	if (!existsSync(wrapper)) {
		throw new Error(`Missing wrapper: ${wrapper}`);
	}

	return await new Promise<{ stdout: string; stderr: string; exitCode: number | null; timedOut: boolean; truncated: boolean }>((resolve, reject) => {
		const child = spawn(wrapper, ["--cwd", cwd, "--command", command], {
			stdio: ["ignore", "pipe", "pipe"],
			env: {
				...process.env,
				ONPREM_EXEC_TIMEOUT_SECONDS: String(Math.max(1, Math.ceil(timeoutMs / 1000))),
				ONPREM_EXEC_MAX_BYTES: String(maxBytes),
			},
		});

		let stdout = "";
		let stderr = "";
		let truncated = false;
		let settled = false;
		let timedOut = false;

		const append = (kind: "stdout" | "stderr", chunk: Buffer) => {
			const text = chunk.toString("utf8");
			const current = kind === "stdout" ? stdout : stderr;
			if (current.length + text.length > maxBytes) {
				truncated = true;
				const remaining = Math.max(0, maxBytes - current.length);
				if (kind === "stdout") stdout += text.slice(0, remaining);
				else stderr += text.slice(0, remaining);
				return;
			}
			if (kind === "stdout") stdout += text;
			else stderr += text;
		};

		const timer = setTimeout(() => {
			timedOut = true;
			child.kill("SIGTERM");
			setTimeout(() => child.kill("SIGKILL"), 2000).unref();
		}, timeoutMs);
		if (signal) {
			if (signal.aborted) child.kill("SIGTERM");
			signal.addEventListener("abort", () => child.kill("SIGTERM"), { once: true });
		}

		child.stdout.on("data", (chunk) => append("stdout", chunk));
		child.stderr.on("data", (chunk) => append("stderr", chunk));
		child.on("error", (err) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			reject(err);
		});
		child.on("close", (code) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			resolve({ stdout, stderr, exitCode: code, timedOut, truncated });
		});
	});
}

function formatResult(title: string, result: Awaited<ReturnType<typeof runWrapper>>) {
	const parts = [
		`${title}`,
		`exitCode=${result.exitCode}${result.timedOut ? " timedOut=true" : ""}${result.truncated ? " truncated=true" : ""}`,
	];
	if (result.stdout.trim()) parts.push(`stdout:\n${result.stdout}`);
	if (result.stderr.trim()) parts.push(`stderr:\n${result.stderr}`);
	return parts.join("\n\n");
}

export default function onpremDuckdb(pi: ExtensionAPI) {
	pi.registerTool({
		name: "onprem_duckdb_query",
		label: "Onprem DuckDB Query",
		description:
			"Execute a read-only SQL query against the configured onprem DuckDB/dlk environment over SSH and return bounded stdout/stderr. Use for onprem EDA, schema inspection, counts, aggregates, and data-quality checks. Never use for writes or destructive operations.",
		promptSnippet: "Run read-only SQL on the configured onprem DuckDB/dlk environment.",
		parameters: QueryParams,
		async execute(_toolCallId, params, signal) {
			assertReadOnlySql(params.sql);
			const timeoutMs = Math.min(Math.max(params.timeoutMs ?? DEFAULT_TIMEOUT_MS, 1000), 300_000);
			const maxBytes = Math.min(Math.max(params.maxBytes ?? DEFAULT_MAX_BYTES, 1000), 1_000_000);
			const result = await runWrapper([], params.sql, timeoutMs, maxBytes, signal);
			if (result.exitCode !== 0 || result.timedOut) {
				throw new Error(formatResult("onprem_duckdb_query failed", result));
			}
			return {
				content: [{ type: "text", text: formatResult("onprem_duckdb_query", result) }],
				details: result,
			};
		},
	});

	pi.registerTool({
		name: "onprem_duckdb_check",
		label: "Onprem DuckDB Check",
		description: "Check configured onprem DuckDB/dlk SSH integration and report target, workdir, wrapper, and remote dlk visibility.",
		promptSnippet: "Check whether onprem DuckDB/dlk integration is configured and reachable.",
		parameters: CheckParams,
		async execute(_toolCallId, _params, signal) {
			const summary = getConfigSummary();
			const result = await runWrapper(["--check"], undefined, 30_000, 50_000, signal);
			return {
				content: [{ type: "text", text: `${summary}\n\n${formatResult("onprem_duckdb_check", result)}` }],
				details: { summary, ...result },
			};
		},
	});

	pi.registerTool({
		name: "onprem_status",
		label: "Onprem Status",
		description:
			"Collect a readonly JSON status snapshot from the configured onprem server/runtime. Use for CPU load, memory, disk/storage, network, Docker/container health/stats, Redis queue/status, PostgreSQL/PgBouncer, and service health questions. Summary mode avoids heavy Redis scans; detailed Redis checks are bounded by maxScanKeys.",
		promptSnippet: "Collect readonly onprem server/runtime status as JSON.",
		parameters: StatusParams,
		async execute(_toolCallId, params, signal) {
			const timeoutMs = Math.min(Math.max(params.timeoutMs ?? DEFAULT_TIMEOUT_MS, 1000), 300_000);
			const maxBytes = Math.min(Math.max(params.maxBytes ?? DEFAULT_MAX_BYTES, 1000), 1_000_000);
			const maxScanKeys = Math.min(Math.max(params.maxScanKeys ?? 10_000, 0), 100_000);
			const result = await runStatusWrapper(
				{ section: params.section, detail: params.detail, maxScanKeys, includeSamples: params.includeSamples },
				timeoutMs,
				maxBytes,
				signal,
			);
			if (result.exitCode !== 0 || result.timedOut) {
				throw new Error(formatResult("onprem_status failed", result));
			}
			return {
				content: [{ type: "text", text: formatResult("onprem_status", result) }],
				details: result,
			};
		},
	});

	pi.registerTool({
		name: "onprem_exec",
		label: "Onprem Exec",
		description:
			"Run a guarded read-oriented command on the configured onprem host from a specified remote working directory and return bounded stdout/stderr. Use for inspection commands, existing local scripts, and ./dlk interfaces. Blocks destructive commands, shell chains, redirects, pipes, package installs, network transfer tools, and privilege/process-control commands.",
		promptSnippet: "Run a guarded read-oriented command on onprem from a specified path.",
		parameters: ExecParams,
		async execute(_toolCallId, params, signal) {
			const timeoutMs = Math.min(Math.max(params.timeoutMs ?? DEFAULT_TIMEOUT_MS, 1000), 300_000);
			const maxBytes = Math.min(Math.max(params.maxBytes ?? DEFAULT_MAX_BYTES, 1000), 1_000_000);
			const result = await runExecWrapper(params.cwd, params.command, timeoutMs, maxBytes, signal);
			if (result.exitCode !== 0 || result.timedOut) {
				throw new Error(formatResult("onprem_exec failed", result));
			}
			return {
				content: [{ type: "text", text: formatResult("onprem_exec", result) }],
				details: result,
			};
		},
	});

	pi.registerCommand("onprem", {
		description: "Onprem helpers: /onprem check, /onprem status [section], /onprem query <SQL>, /onprem exec <cwd> -- <command>",
		handler: async (args, ctx) => {
			const trimmed = args.trim();
			if (!trimmed || trimmed === "help") {
				ctx.ui.notify("Usage: /onprem check | /onprem status [all|host|docker|redis|postgres|storage|network|services] [detailed] | /onprem query <read-only SQL> | /onprem exec <cwd> -- <command>", "info");
				return;
			}
			if (trimmed === "check") {
				const result = await runWrapper(["--check"], undefined, 30_000, 50_000);
				ctx.ui.notify(formatResult("onprem check", result).slice(0, 4000), result.exitCode === 0 ? "info" : "error");
				return;
			}
			if (trimmed === "status" || trimmed.startsWith("status ")) {
				const parts = trimmed.split(/\s+/).slice(1);
				const section = parts.find((p) => ["all", "host", "docker", "redis", "postgres", "storage", "network", "services"].includes(p)) ?? "all";
				const detail = parts.includes("detailed") ? "detailed" : "summary";
				const result = await runStatusWrapper({ section, detail }, DEFAULT_TIMEOUT_MS, DEFAULT_MAX_BYTES);
				ctx.ui.notify(formatResult("onprem status", result).slice(0, 4000), result.exitCode === 0 ? "info" : "error");
				return;
			}
			if (trimmed.startsWith("query ")) {
				const sql = trimmed.slice("query ".length);
				assertReadOnlySql(sql);
				const result = await runWrapper([], sql, DEFAULT_TIMEOUT_MS, DEFAULT_MAX_BYTES);
				ctx.ui.notify(formatResult("onprem query", result).slice(0, 4000), result.exitCode === 0 ? "info" : "error");
				return;
			}
			if (trimmed.startsWith("exec ")) {
				const spec = trimmed.slice("exec ".length);
				const sep = spec.indexOf(" -- ");
				if (sep === -1) {
					ctx.ui.notify("Usage: /onprem exec <cwd> -- <command>", "error");
					return;
				}
				const cwd = spec.slice(0, sep).trim();
				const command = spec.slice(sep + 4).trim();
				const result = await runExecWrapper(cwd, command, DEFAULT_TIMEOUT_MS, DEFAULT_MAX_BYTES);
				ctx.ui.notify(formatResult("onprem exec", result).slice(0, 4000), result.exitCode === 0 ? "info" : "error");
				return;
			}
			ctx.ui.notify("Unknown /onprem command. Use: /onprem check | /onprem status [section] [detailed] | /onprem query <SQL> | /onprem exec <cwd> -- <command>", "error");
		},
	});
}
