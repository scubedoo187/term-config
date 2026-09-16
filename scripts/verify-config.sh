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

if command -v ghostty >/dev/null 2>&1; then
    echo "[verify] ghostty config syntax"
    ghostty +validate-config --config-file="$ROOT_DIR/.config/ghostty/config"
fi

# The filter commands live in local git config, which a clone does not carry,
# so a fresh checkout has to register them before Codex's machine-local
# [projects.*] blocks can leak into a commit.
echo "[verify] git filters"
if [ "$(git -C "$ROOT_DIR" config --get filter.codex-config.clean || true)" = "" ]; then
    echo "         filter.codex-config is not registered in this checkout"
    echo "         run scripts/setup-git-filters.sh"
    exit 1
fi

# Only meaningful once the home/ configs have been migrated onto this
# checkout; before that there is nothing to check.
if [ -L "$HOME/.claude/settings.json" ]; then
    echo "[verify] home config links"
    "$ROOT_DIR/scripts/verify-home-links.sh"
else
    echo "[verify] home config links not migrated yet; skipping"
    echo "         (scripts/migrate-home-configs.sh --apply)"
fi

echo "[verify] ok"
