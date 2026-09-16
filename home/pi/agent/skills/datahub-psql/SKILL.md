---
name: datahub-psql
description: Use for DataHub (uju-prod) read-only PostgreSQL exploration, schema inspection, EDA, and query planning through the configured datahub_psql_check and datahub_psql_query tools. Load when the user mentions datahub, uju-prod, PostgreSQL, tables, schema, EDA, data checks, or asks to query DataHub data.
---

# DataHub PostgreSQL (uju-prod) Workflow

Use this skill for safe read-only exploration of the DataHub PostgreSQL database.

## Available tools

- `datahub_psql_check`: verify config and local psql availability.
- `datahub_psql_query`: run read-only SQL against DataHub PostgreSQL and return bounded output.

## Safety rules

1. Treat DataHub as sensitive.
2. Use read-only SQL only.
3. Never run mutating SQL: `INSERT`, `UPDATE`, `DELETE`, `DROP`, `CREATE`, `ALTER`, `COPY`, `EXPORT`, `ATTACH`, `INSTALL`, `LOAD`, `TRUNCATE`, `MERGE`, `VACUUM`, `GRANT`, `REVOKE`, etc.
4. Prefer metadata and aggregates over raw rows.
5. Use `LIMIT` for samples.
6. If a request needs write access or risky commands, stop and ask for confirmation.

## When starting

If the integration has not yet been verified in this session:

1. Run `datahub_psql_check`
2. Run a tiny smoke query like `select 1;`

If config is missing, create `~/.pi/agent/datahub-psql.json` from `~/.pi/agent/datahub-psql.example.json`.

## EDA workflow

For a table or topic request, use this order:

1. Identify the exact table/view, schema, or domain from the user request.
2. Discover relevant tables if the name is ambiguous:
   - `select table_schema, table_name from information_schema.tables ...`
3. Inspect schema:
   - `select ... from information_schema.columns ...`
   - use `
`-style psql meta commands only as a mental model; execute SQL equivalents.
4. Count rows.
5. Freshness/time range checks.
6. Null/empty checks.
7. Numeric summaries.
8. Categorical summaries.
9. Duplicates and anomaly checks.
10. Summarize with evidence and follow-up queries.

## Query style

- Keep queries small and composable.
- Prefer `COUNT(*)`, grouped counts, `MIN/MAX`, `AVG`, `stddev`, percentile queries, and `LIMIT` samples.
- Use CTEs for readability.
- Do not assume extensions are installed.

## Reporting style

Return concise, evidence-backed results:

- What was checked
- Key numbers
- Notable anomalies
- Limitations
- Suggested next checks

For EDA, structure like:

```text
Summary
Schema highlights
Volume/freshness
Quality checks
Anomalies / risks
Recommended follow-ups
```
