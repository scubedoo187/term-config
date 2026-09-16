---
name: onprem-duckdb
description: Use for onprem DuckDB/dlk data analysis, EDA, schema inspection, data-quality checks, and read-only SQL investigation through the configured onprem_duckdb_query tool. Load when the user mentions onprem, dlk, DuckDB, EDA, data checks, warehouse/table inspection, or asks to fetch/analyze onprem data.
---

# Onprem DuckDB / dlk Workflow

This skill gives the agent the recurring context the user previously supplied manually: how to approach onprem DuckDB/dlk work, how to query safely, and how to report results.

## Available tools

Use these Pi tools when available:

- `onprem_duckdb_check`: verify config, local/remote mode, working directory, and dlk visibility.
- `onprem_duckdb_query`: execute read-only SQL against the configured onprem DuckDB/dlk environment.
- `onprem_exec`: execute a guarded read-oriented command from a specified path on the configured onprem host. Use for inspection commands, existing scripts, and `./dlk` interfaces when SQL-only access is insufficient.
- `onprem_status`: collect a fixed-schema readonly JSON status snapshot from the configured onprem host/runtime. Use for CPU load, memory, disk/storage, network, Docker/container status, service health, PostgreSQL/PgBouncer status, and Redis queue/status questions.

The preferred query path is now local `./dlk shell --remote` plus `rq(...)`, which uses onprem compute resources without requiring SSH for query execution. Legacy SSH + `./dlk shell --local` remains available as a fallback mode. Do **not** use generic `bash` with raw `sshpass` for onprem work unless explicitly debugging the integration. Prefer `onprem_duckdb_query`, `onprem_status`, or `onprem_exec` so mode handling, timeouts, command guards, and output bounds are handled consistently.

## Safety rules

1. Treat the onprem environment as sensitive.
2. Use read-only SQL only.
3. Never run destructive or mutating SQL: `INSERT`, `UPDATE`, `DELETE`, `DROP`, `CREATE`, `ALTER`, `COPY`, `EXPORT`, `ATTACH`, `INSTALL`, `LOAD`, `TRUNCATE`, `MERGE`, `VACUUM`, etc.
4. Avoid fetching large raw rows. Start with metadata and aggregates.
5. Use `LIMIT` for samples and explain why each sample is needed.
6. Minimize PII exposure. Prefer counts, distributions, hashes, or masked fields unless raw values are necessary.
7. If a requested action needs write access or a risky command, stop and ask the user for explicit confirmation and a safer alternative.
8. Report query assumptions and limitations clearly.
9. For host/runtime status questions, use `onprem_status` before composing ad-hoc `onprem_exec` commands. Default `section="all"` is lightweight; use `section="redis"` or `detail="detailed"` only when prefix/TTL/key-scan detail is needed.
10. For `onprem_exec`, prefer read-only inspection commands (`ls`, `find`, `rg`, `cat`, `head`, `tail`, `wc`, `du`, `df`, `stat`, `file`, safe `git` subcommands) or existing project scripts (`./script`, `bash ./script`, `python ./script`, `node ./script`) and `./dlk` interfaces.
11. `onprem_exec` intentionally blocks destructive or high-risk commands including `rm`, `mv`, `cp`, `chmod`, `chown`, `sudo`, process control, package managers, network transfer tools, shell chains, redirects, pipes, and command substitution.

## When starting an onprem task

If the session has not already proven the integration works, run:

1. `onprem_duckdb_check`
2. A tiny smoke query, e.g. `select 1;`, if check output is not enough.

For server health/status requests, run `onprem_status` after the check instead of a DuckDB smoke query.

If config is missing, tell the user to create `~/.pi/agent/onprem-duckdb.json` from `~/.pi/agent/onprem-duckdb.example.json` and fill `mode`, `workdir`, `dlkCommand`, and optional legacy `ssh` fallback settings.

## Onprem status workflow

For CPU/memory/storage/network/container/Redis/PostgreSQL/service health requests:

1. Use `onprem_duckdb_check` if integration has not been checked in this session.
2. Run `onprem_status` with `section="all"`, `detail="summary"` first.
3. If the user asks specifically about Redis queues, TTL, key prefixes, or backlog, run `onprem_status` with `section="redis"`. Use `detail="detailed"` only when prefix counts or TTL policy evidence is needed.
4. Summarize:
   - resource pressure: CPU load vs cores, memory availability, disk/inode pressure, network counters if relevant,
   - service health: unhealthy/exited containers and endpoint/DB/PgBouncer errors,
   - queue pressure: known prefix queue lengths, failed/processing/pending counts,
   - limitations: snapshot timing, bounded Redis scan, sections with errors.
5. Do not suggest or run remediation actions such as restart, cleanup, TTL update, or deletion unless the user explicitly asks and confirms a write/risky operation.

## EDA workflow

For a table or dataset EDA request, use this order:

1. Identify table/view name and relevant time window from the user request.
2. Inspect schema:
   - `describe <table>;` or equivalent.
   - table list/schema queries if the table name is ambiguous.
3. Count rows:
   - total row count.
   - row count by date partition/time bucket if applicable.
4. Freshness/time range:
   - min/max timestamp or date columns.
   - recent row count.
5. Null/empty checks:
   - null counts and null ratios for important columns.
6. Numeric summaries:
   - min/max/avg/stddev/percentiles when supported.
7. Categorical summaries:
   - top values and cardinality for dimensions/status columns.
8. Duplicates:
   - check obvious keys if available.
9. Anomalies:
   - sudden volume changes, impossible values, negative amounts, out-of-range dates, unexpected statuses.
10. Summarize findings with exact query evidence and recommend follow-up queries.

## Query style

- Keep queries small and composable.
- Prefer `COUNT(*)`, grouped counts, null ratios, `MIN/MAX`, top-K distributions.
- Add `LIMIT 50` or lower for samples.
- For uncertain schemas, query schema first instead of guessing.
- Use CTEs for readability.
- Do not assume DuckDB extensions are installed.

## Reporting style

Return concise but evidence-backed results:

- What was checked
- Key numbers
- Notable anomalies
- Confidence/limitations
- Suggested next checks

For EDA, structure the answer:

```text
Summary
Schema highlights
Volume/freshness
Quality checks
Anomalies / risks
Recommended follow-ups
```

## Troubleshooting

If `onprem_duckdb_query` fails:

1. Run `onprem_duckdb_check`.
2. Check whether the config exists and has the correct `mode`, `workdir`, `dlkCommand`, and `remoteQueryFunction`.
3. If TERM/tmux issues appear, the wrapper normalizes with `env -u TMUX TERM=xterm-256color`; mention this in the diagnosis.
4. For remote-rq mode, ask the user to verify locally:

```bash
cd <workdir>
./dlk shell --remote -c "FROM rq('select 1 as ok')"
```

5. For legacy SSH mode, the older `./dlk shell --local` path is still available as fallback.

Do not ask for passwords in chat. Use the configured `passwordCommand`/Keychain path only for legacy SSH fallback.
