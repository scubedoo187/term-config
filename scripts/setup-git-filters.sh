#!/bin/bash
set -euo pipefail

# Register this checkout's git filters.
#
# .gitattributes names the filters, but the commands themselves live in local
# git config and are NOT carried by a clone, so every new checkout has to run
# this once. Without it git stores home/codex/config.toml verbatim, including
# the machine-local [projects.*] trust blocks.
#
# scripts/verify-config.sh checks that this has been run.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

git config filter.codex-config.clean  "scripts/git-filter-codex-config.sh"
git config filter.codex-config.smudge "cat"

echo "[git-filters] filter.codex-config registered"

# Restage anything already tracked so the filter applies to it from now on.
git add --renormalize home/codex/config.toml 2>/dev/null || true

echo "[git-filters] ok"
