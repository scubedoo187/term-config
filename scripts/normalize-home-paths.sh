#!/bin/bash
set -euo pipefail

# Rewrite absolute home-directory paths in tracked configs to the current $HOME,
# so a checkout works under a different username.
#
# Deliberately scoped to a fixed file list rather than scanning home/: some
# tracked configs carry paths that are NOT local. home/pi/agent/onprem-duckdb
# .example.json points at a remote host's /home/..., and rewriting that would
# break the connection instead of fixing it.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGETS="
home/codex/config.toml
home/codex/AGENTS.md
"

apply=0
case "${1:-}" in
    --apply) apply=1 ;;
    ""|--dry-run) apply=0 ;;
    *) echo "usage: $(basename "$0") [--apply|--dry-run]" >&2; exit 2 ;;
esac

changed=0
for rel in $TARGETS; do
    file="$ROOT_DIR/$rel"
    [ -f "$file" ] || continue

    # Any /Users/<name> or /home/<name> prefix that is not ours becomes $HOME.
    #
    # Occurrences of $HOME are masked out first. Without that, a substituted
    # path gets re-matched on the next pass whenever $HOME itself ends in a
    # home-shaped segment (/home/<user> on Linux, or any checkout under a
    # directory literally named "home"), and the path loses a segment every
    # run. Masking makes this idempotent for any value of $HOME.
    rewritten="$(perl -pe '
        BEGIN { $h = $ENV{HOME}; }
        s{\Q$h\E}{\x00}g;
        s{(?:/Users/|/home/)[^/"'"'"':\s\]]+}{\x00}g;
        s{\x00}{$h}g;
    ' "$file")"

    if [ "$rewritten" = "$(cat "$file")" ]; then
        echo "[normalize] $rel: already matches \$HOME"
        continue
    fi

    hits="$(printf '%s\n' "$rewritten" | diff - "$file" | grep -c '^>' || true)"
    changed=$((changed + 1))
    if [ "$apply" -eq 1 ]; then
        printf '%s\n' "$rewritten" > "$file"
        echo "[normalize] $rel: rewrote $hits line(s) to \$HOME"
    else
        echo "[normalize] $rel: would rewrite $hits line(s) to \$HOME"
    fi
done

if [ "$changed" -eq 0 ]; then
    echo "[normalize] nothing to do"
elif [ "$apply" -eq 0 ]; then
    echo "[normalize] dry run; re-run with --apply to write"
fi
