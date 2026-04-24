#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/term-config/fish"

mkdir -p "$CACHE_DIR"

if command -v fzf >/dev/null 2>&1; then
  fzf --fish > "$CACHE_DIR/fzf-init.fish"
fi

if command -v direnv >/dev/null 2>&1; then
  direnv hook fish > "$CACHE_DIR/direnv-init.fish"
fi

if command -v starship >/dev/null 2>&1; then
  starship init fish --print-full-init > "$CACHE_DIR/starship-init.fish"
fi

echo "Refreshed fish init cache in $CACHE_DIR"
