---
description: Run safe read-only EDA on DataHub PostgreSQL (uju-prod)
argument-hint: "<table-or-topic> [focus]"
---

Use the datahub-psql skill and the datahub_psql_check / datahub_psql_query tools to perform safe read-only EDA for: $ARGUMENTS

Workflow:
1. Clarify exact table/view or domain.
2. If ambiguous, discover candidate tables first.
3. Inspect schema (information_schema / pg_catalog equivalents).
4. Count rows and check freshness.
5. Run null/quality checks.
6. Summarize with evidence and next steps.

If the user asks for query results, plan the SQL first, then execute with read-only queries only.
