#!/bin/bash
set -euo pipefail

# Confirm every config tracked under home/ is a live symlink into this checkout,
# that it still resolves, and that the credentials next to it were left alone.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

# Optional app name, so a partly-migrated machine can verify one at a time.
only="${1:-}"
case "$only" in
    ""|claude|codex|pi) ;;
    *) echo "usage: $(basename "$0") [claude|codex|pi]" >&2; exit 2 ;;
esac

tracked="$(cd "$ROOT_DIR/home" && find . -type f | sed 's|^\./||')"
[ -n "$only" ] && tracked="$(printf '%s\n' "$tracked" | grep "^$only/" || true)"

echo "[verify-links] tracked configs resolve into $ROOT_DIR${only:+ (${only} only)}"
while read -r rel; do
    app="${rel%%/*}"
    sub="${rel#*/}"
    target="$HOME/.$app/$sub"

    if [ ! -L "$target" ]; then
        echo "  MISS  .$app/$sub is not a symlink"; fail=1; continue
    fi
    dest="$(readlink "$target")"
    case "$dest" in
        "$ROOT_DIR"/*) ;;
        *) echo "  STRAY .$app/$sub -> $dest"; fail=1; continue ;;
    esac
    [ -e "$target" ] || { echo "  BROKEN .$app/$sub -> $dest"; fail=1; }
done <<< "$tracked"

echo "[verify-links] machine-local files are untouched"
for f in "$HOME/.pi/agent/auth.json" "$HOME/.pi/agent/node_modules" \
         "$HOME/.codex/auth.json" "$HOME/.claude/history.jsonl"; do
    if [ -e "$f" ] && [ -L "$f" ]; then
        echo "  LINKED $(basename "$f") became a symlink; it must stay a real file"; fail=1
    fi
done

echo "[verify-links] no local home path from another machine leaked in"
# Mask $HOME before looking for home-shaped prefixes, for the same reason
# normalize-home-paths.sh does: otherwise a correct path sitting under a
# directory named "home" reads as a foreign one.
stale="$(perl -ne '
    BEGIN { $h = $ENV{HOME}; }
    s{\Q$h\E}{}g;
    while (/(?:\/Users\/|\/home\/)[^\/"'"'"':\s\]]+/g) { print "$&\n" }
' "$ROOT_DIR"/home/codex/config.toml "$ROOT_DIR"/home/codex/AGENTS.md 2>/dev/null | sort -u || true)"
if [ -n "$stale" ]; then
    echo "  STALE  home/codex carries a home path from another machine:"
    printf '         %s\n' $stale
    echo "         run scripts/normalize-home-paths.sh --apply"
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "[verify-links] ok"
else
    echo "[verify-links] FAILED" >&2
fi
exit "$fail"
