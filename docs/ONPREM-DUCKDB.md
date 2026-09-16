# Onprem DuckDB / dlk Pi Integration

This setup lets Pi perform read-only onprem DuckDB/dlk investigation without re-explaining connection context every session.

## Components

- `~/.local/bin/onprem-duckdb-query` — wrapper that reads SQL from stdin and executes it remotely through SSH/sshpass.
- `~/.local/bin/onprem-exec` — wrapper for guarded read-oriented onprem shell commands.
- `~/.pi/agent/extensions/onprem-duckdb.ts` — Pi tools:
  - `onprem_duckdb_check`
  - `onprem_duckdb_query`
  - `onprem_exec`
- `~/.pi/agent/skills/onprem-duckdb/SKILL.md` — default workflow/safety context for onprem EDA.
- `~/.pi/agent/prompts/onprem-eda.md` — prompt template for `/onprem-eda <table-or-topic>`.

## Private config

Create:

```bash
cp ~/.pi/agent/onprem-duckdb.example.json ~/.pi/agent/onprem-duckdb.json
```

Fill:

```json
{
  "host": "ONPREM_HOST_OR_IP",
  "user": "yg.jung",
  "workdir": "/path/to/dlk/project",
  "passwordCommand": "security find-generic-password -s tridge-onprem -a yg.jung -w",
  "dlkCommand": "./dlk shell --local",
  "sshTty": false,
  "sshOptions": [
    "-o", "PreferredAuthentications=password",
    "-o", "PubkeyAuthentication=no"
  ]
}
```

Do not store the password in this file. Store it in macOS Keychain:

```bash
security add-generic-password -s tridge-onprem -a yg.jung -w 'PASSWORD'
```

## Tests

```bash
~/.local/bin/onprem-duckdb-query --check
echo 'select 1;' | ~/.local/bin/onprem-duckdb-query
```

Inside Pi, run `/reload`, then:

```text
/onprem check
/onprem query select 1;
/onprem exec /tmp -- ls -la
```

Then use natural language:

```text
onprem duckdb에서 orders 테이블 EDA 해줘
```

## Safety

The DuckDB wrapper and extension only allow read-oriented SQL starts such as `SELECT`, `WITH`, `SHOW`, `DESCRIBE`, `EXPLAIN`, limited `PRAGMA`, and `SUMMARIZE`. Mutating/destructive statements are blocked.

The general `onprem_exec` path allows read-oriented inspection commands, safe `git` subcommands, existing relative scripts such as `./script`, `bash ./script`, `python ./script`, `node ./script`, and `./dlk ...`. It blocks shell chains, redirection, pipes, command substitution, destructive commands, privilege/process-control commands, package managers, and network transfer commands.
