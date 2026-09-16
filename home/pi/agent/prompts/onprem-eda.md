---
description: Run safe read-only EDA on a configured onprem DuckDB/dlk table
argument-hint: "<table-or-topic> [focus]"
---
Use the onprem-duckdb skill and the onprem_duckdb_query tool to perform safe read-only EDA for: $ARGUMENTS

Prefer the configured local `./dlk shell --remote` + `rq(...)` path when available, start with schema/row-count/freshness/null checks, avoid large raw samples, and summarize findings with query evidence and follow-up recommendations.
