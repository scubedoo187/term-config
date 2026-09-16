import { spawn } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const DEFAULT_CONFIG_PATH = join(homedir(), ".pi", "agent", "queenspark-psql.json");
const DEFAULT_QUERY_WRAPPER = join(homedir(), ".local", "bin", "queenspark-psql-query");
const DEFAULT_CHECK_WRAPPER = join(homedir(), ".local", "bin", "queenspark-psql-check");

const QueryParams = Type.Object({
  sql: Type.String({ description: "Read-only SQL to run against Queenspark PostgreSQL." }),
  timeoutMs: Type.Optional(Type.Number()),
  maxBytes: Type.Optional(Type.Number()),
});

const EmptyParams = Type.Object({});

function stripSqlComments(sql: string): string {
  return sql.replace(/--.*?(?=\n|$)/g, " ").replace(/\/\*[\s\S]*?\*\//g, " ").trim();
}

function assertReadOnlySql(sql: string) {
  const cleaned = stripSqlComments(sql).replace(/^\(+/, "").trim().toLowerCase();
  const allowedStarts = ["select", "with", "show", "describe", "desc", "explain", "values", "table", "pragma"];
  const blocked = /\b(insert|update|delete|drop|create|alter|copy|export|attach|install|load|call|truncate|merge|replace|vacuum|grant|revoke|comment|set\s+role|set\s+transaction)\b/i;
  if (!allowedStarts.some((p) => cleaned.startsWith(p)) || blocked.test(cleaned)) {
    throw new Error("Refusing non-read-only SQL.");
  }
}

function getConfigSummary(): string {
  const path = process.env.QUEENSPARK_PSQL_CONFIG || DEFAULT_CONFIG_PATH;
  if (!existsSync(path)) return `missing config: ${path}`;
  try {
    const cfg = JSON.parse(readFileSync(path, "utf8"));
    return `config=${path}\ndbname=${cfg.dbname || "<missing>"}\nconnectionString=${cfg.connectionString ? "set" : "missing"}`;
  } catch (err) {
    return `invalid config ${path}: ${err instanceof Error ? err.message : String(err)}`;
  }
}

function run(wrapper: string, args: string[], stdin?: string, timeoutMs = 60_000, maxBytes = 200_000) {
  return new Promise<{ stdout: string; stderr: string; code: number | null }>((resolve, reject) => {
    const child = spawn(wrapper, args, {
      stdio: [stdin === undefined ? "ignore" : "pipe", "pipe", "pipe"],
      env: { ...process.env, QUEENSPARK_PSQL_TIMEOUT_SECONDS: String(Math.ceil(timeoutMs / 1000)), QUEENSPARK_PSQL_MAX_BYTES: String(maxBytes) },
    });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (c) => (stdout += c.toString("utf8")));
    child.stderr.on("data", (c) => (stderr += c.toString("utf8")));
    child.on("error", reject);
    child.on("close", (code) => resolve({ stdout, stderr, code }));
    if (stdin !== undefined) child.stdin.end(stdin);
  });
}

export default function queensparkPsql(pi: ExtensionAPI) {
  pi.registerTool({
    name: "queenspark_psql_query",
    label: "Queenspark PSQL Query",
    description: "Run read-only SQL against Queenspark prod PostgreSQL and return bounded output.",
    promptSnippet: "Run read-only SQL against Queenspark PostgreSQL.",
    parameters: QueryParams,
    async execute(_id, params) {
      assertReadOnlySql(params.sql);
      const result = await run(DEFAULT_QUERY_WRAPPER, [], params.sql, params.timeoutMs ?? 60_000, params.maxBytes ?? 200_000);
      if (result.code !== 0) throw new Error(`queenspark_psql_query failed\n\n${result.stderr || result.stdout}`);
      return { content: [{ type: "text", text: result.stdout || "(no rows)" }], details: result };
    },
  });

  pi.registerTool({
    name: "queenspark_psql_check",
    label: "Queenspark PSQL Check",
    description: "Check Queenspark PostgreSQL config and local psql availability.",
    promptSnippet: "Check Queenspark PostgreSQL connectivity and config.",
    parameters: EmptyParams,
    async execute() {
      const summary = getConfigSummary();
      const result = await run(DEFAULT_CHECK_WRAPPER, []);
      return { content: [{ type: "text", text: `${summary}\n\n${result.stdout}${result.stderr ? `\n${result.stderr}` : ""}` }], details: result };
    },
  });

  pi.registerCommand("queenspark", {
    description: "Queenspark helpers: /queenspark check, /queenspark query <SQL>, /queenspark eda <topic>",
    handler: async (args, ctx) => {
      const trimmed = args.trim();
      if (!trimmed || trimmed === "help") {
        ctx.ui.notify("Usage: /queenspark check | /queenspark query <read-only SQL> | /queenspark eda <topic>", "info");
        return;
      }
      if (trimmed === "check") {
        const result = await run(DEFAULT_CHECK_WRAPPER, []);
        ctx.ui.notify(result.stdout || result.stderr || "ok", result.code === 0 ? "info" : "error");
        return;
      }
      if (trimmed.startsWith("query ")) {
        const sql = trimmed.slice("query ".length);
        assertReadOnlySql(sql);
        const result = await run(DEFAULT_QUERY_WRAPPER, [], sql);
        ctx.ui.notify(result.stdout || result.stderr || "ok", result.code === 0 ? "info" : "error");
        return;
      }
      if (trimmed.startsWith("eda ")) {
        ctx.ui.notify("Use natural language in the chat, e.g. 'queenspark에서 orders 테이블 EDA 해줘'. The skill/prompt layer will plan queries using queenspark_psql_check/query.", "info");
        return;
      }
      ctx.ui.notify("Unknown /queenspark command. Use: /queenspark check | /queenspark query <SQL> | /queenspark eda <topic>", "error");
    },
  });
}
