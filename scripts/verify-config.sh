#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[verify] refresh shell cache"
"$ROOT_DIR/scripts/refresh-shell-cache.sh"

echo "[verify] fish config syntax"
fish -n "$ROOT_DIR/.config/fish/config.fish"
for file in "$ROOT_DIR"/.config/fish/conf.d/*.fish; do
    fish -n "$file"
done

echo "[verify] tmux config syntax"
tmux -L term-config-verify kill-server 2>/dev/null || true
tmux -L term-config-verify -f "$ROOT_DIR/.config/tmux/tmux.conf" new-session -d -s verify
tmux -L term-config-verify show-options -g extended-keys | grep -q '^extended-keys on$'
tmux -L term-config-verify kill-server 2>/dev/null || true

echo "[verify] wezterm config loads"
wezterm --config-file "$ROOT_DIR/.config/wezterm/wezterm.lua" show-keys >/dev/null

echo "[verify] ok"
