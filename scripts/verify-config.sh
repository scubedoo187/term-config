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

# The Ghostty CLI lives inside the .app bundle on macOS and is not on PATH by
# default, so fall back to the bundled binary before skipping the check.
ghostty_bin="$(command -v ghostty || true)"
if [ -z "$ghostty_bin" ] && [ -x "/Applications/Ghostty.app/Contents/MacOS/ghostty" ]; then
    ghostty_bin="/Applications/Ghostty.app/Contents/MacOS/ghostty"
fi

if [ -n "$ghostty_bin" ]; then
    echo "[verify] ghostty config syntax"
    # Ghostty forks export GHOSTTY_RESOURCES_DIR into every shell they spawn.
    # Inheriting it points theme lookup at the fork's bundle instead of the
    # binary's own, which fails on any theme the fork does not ship.
    env -u GHOSTTY_RESOURCES_DIR "$ghostty_bin" \
        +validate-config --config-file="$ROOT_DIR/.config/ghostty/config"
else
    echo "[verify] ghostty not installed; skipping config check"
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
