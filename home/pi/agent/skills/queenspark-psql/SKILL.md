---
name: queenspark-psql
description: Use for Queenspark (queenspark-prod) read-only PostgreSQL exploration, schema inspection, EDA, and query planning through the configured queenspark_psql_check and queenspark_psql_query tools. Load when the user mentions queenspark, queenspark-prod, PostgreSQL, tables, schema, EDA, data checks, or asks to query Queenspark data.
---

# Queenspark PostgreSQL (queenspark-prod) Workflow

Use this skill for safe read-only exploration of the Queenspark PostgreSQL database.

## Available tools

- `queenspark_psql_check`: verify config and local psql availability.
- `queenspark_psql_query`: run read-only SQL against Queenspark PostgreSQL and return bounded output.

## Safety rules

1. Treat Queenspark as sensitive.
2. Use read-only SQL only.
3. Never run mutating SQL.
4. Prefer metadata and aggregates over raw rows.
5. Use `LIMIT` for samples.
6. If a request needs write access, stop and ask.

## When starting

1. Run `queenspark_psql_check`
2. Run `select 1;` if needed

## EDA workflow

1. Clarify exact table/view or domain.
2. If ambiguous, discover candidate tables first from `information_schema.tables`.
3. Inspect schema from `information_schema.columns`.
4. Count rows and check freshness.
5. Run null/quality checks.
6. Summarize with evidence and next steps.
