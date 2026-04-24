#!/bin/bash
set -euo pipefail

WEZTERM_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/wezterm"

if pgrep -f "wezterm-mux-server" >/dev/null 2>&1; then
    echo "wezterm-mux-server is still running; stop it before cleaning state." >&2
    exit 1
fi

if [ ! -d "$WEZTERM_DATA_DIR" ]; then
    echo "No wezterm data directory found at $WEZTERM_DATA_DIR"
    exit 0
fi

find "$WEZTERM_DATA_DIR" -maxdepth 1 -type l \( -name 'agent.*' -o -name 'gui-sock-*' \) -print -delete
find "$WEZTERM_DATA_DIR" -maxdepth 1 -type f \( -name 'mux-server*.log' -o -name 'wezterm-*-log-*.txt' \) -size +1M -print -delete

echo "Cleaned stale wezterm state under $WEZTERM_DATA_DIR"
