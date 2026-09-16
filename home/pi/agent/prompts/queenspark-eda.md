---
description: Run safe read-only EDA on Queenspark PostgreSQL (queenspark-prod)
argument-hint: "<table-or-topic> [focus]"
---

Use the queenspark-psql skill and the queenspark_psql_check / queenspark_psql_query tools to perform safe read-only EDA for: $ARGUMENTS

Workflow:
1. Clarify exact table/view or domain.
2. If ambiguous, discover candidate tables first.
3. Inspect schema (information_schema / pg_catalog equivalents).
4. Count rows and check freshness.
5. Run null/quality checks.
6. Summarize with evidence and next steps.
