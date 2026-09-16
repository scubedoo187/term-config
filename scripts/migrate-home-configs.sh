#!/bin/bash
set -euo pipefail

# Move ~/.claude, ~/.codex and ~/.pi configs onto this checkout without losing
# the settings that are live right now.
#
# home.nix links these as out-of-store symlinks, which home-manager refuses to
# create over an existing regular file. This script clears the way, but treats
# the LIVE file as authoritative: if it has drifted from the repo copy, the
# live version is pulled into the repo first, so switching can only ever
# preserve the working configuration, never overwrite it with a stale one.
#
# Only files that already exist under home/ in this checkout are touched.
# Everything else in those directories -- auth.json, node_modules, sessions,
# the populated *-psql.json -- is left exactly where it is.
#
# Links are created the same way the rest of this repo already does it: a
# plain symlink from $HOME into the working copy, matching ~/.config/fish and
# friends. home-manager has never been run on this machine, and home.nix
# describes the same end state for anyone who wants to adopt it later.
#
# An app name limits the run to one of claude/codex/pi, so the riskiest one
# (whichever has live sessions) can go last.
#
#   migrate-home-configs.sh                 # dry run (default)
#   migrate-home-configs.sh --apply         # everything
#   migrate-home-configs.sh --apply pi      # just ~/.pi
#   migrate-home-configs.sh --rollback STAMP

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_ROOT="$HOME/.term-config-backups"

mode="dry-run"
stamp=""
only=""
case "${1:-}" in
    ""|--dry-run) mode="dry-run"; only="${2:-}" ;;
    --apply)      mode="apply";   only="${2:-}" ;;
    --rollback)   mode="rollback"; stamp="${2:-}" ;;
    *) echo "usage: $(basename "$0") [--apply|--dry-run] [claude|codex|pi]" >&2
       echo "       $(basename "$0") --rollback STAMP" >&2; exit 2 ;;
esac

case "$only" in
    ""|claude|codex|pi) ;;
    *) echo "[migrate] unknown app '$only'; expected claude, codex or pi" >&2; exit 2 ;;
esac

# ---------------------------------------------------------------------------
# Rollback: put every backed-up file back where it came from.
# ---------------------------------------------------------------------------
if [ "$mode" = "rollback" ]; then
    [ -n "$stamp" ] || { echo "[migrate] --rollback needs a stamp; see $BACKUP_ROOT" >&2; exit 2; }
    src="$BACKUP_ROOT/$stamp"
    [ -d "$src" ] || { echo "[migrate] no backup at $src" >&2; exit 1; }

    find "$src" -type f | while read -r file; do
        rel="${file#"$src"/}"
        target="$HOME/$rel"
        mkdir -p "$(dirname "$target")"
        # The symlink home-manager created has to go before the file returns.
        [ -L "$target" ] && rm "$target"
        cp "$file" "$target"
        echo "[migrate] restored $rel"
    done
    echo "[migrate] rolled back to $stamp"
    echo "[migrate] run 'home-manager switch' only after reverting home.nix,"
    echo "[migrate] otherwise the next activation re-links these files."
    exit 0
fi

# ---------------------------------------------------------------------------
# The managed set: every file tracked under home/, mapped to its $HOME target.
#   home/claude/settings.json -> ~/.claude/settings.json
# ---------------------------------------------------------------------------
managed="$(cd "$ROOT_DIR/home" && find . -type f | sed 's|^\./||')"
if [ -n "$only" ]; then
    managed="$(printf '%s\n' "$managed" | grep "^$only/" || true)"
    [ -n "$managed" ] || { echo "[migrate] nothing tracked under home/$only" >&2; exit 1; }
fi

n_linked=0 n_same=0 n_drift=0 n_absent=0 n_clobber=0
stamp_new="$(date +%Y%m%d-%H%M%S)"
backup="$BACKUP_ROOT/$stamp_new"

echo "[migrate] checkout: $ROOT_DIR"
echo "[migrate] mode:     $mode"
[ "$mode" = "apply" ] && echo "[migrate] backup:   $backup"
echo

while read -r rel; do
    app="${rel%%/*}"                      # claude | codex | pi
    sub="${rel#*/}"                       # path below that
    target="$HOME/.$app/$sub"
    repo="$ROOT_DIR/home/$rel"

    if [ -L "$target" ]; then
        dest="$(readlink "$target")"
        case "$dest" in
            "$ROOT_DIR"/*) echo "  ok      .$app/$sub (already linked)"; n_linked=$((n_linked+1)); continue ;;
            *)             echo "  FOREIGN .$app/$sub -> $dest"; n_clobber=$((n_clobber+1)); continue ;;
        esac
    fi

    if [ ! -e "$target" ]; then
        # Fresh checkout on a new machine: nothing to preserve or back up,
        # just put the link there. The parent may not exist yet either.
        echo "  absent  .$app/$sub (new link)"
        n_absent=$((n_absent+1))
        if [ "$mode" = "apply" ]; then
            mkdir -p "$(dirname "$target")"
            ln -s "$repo" "$target"
        fi
        continue
    fi

    if cmp -s "$target" "$repo"; then
        echo "  same    .$app/$sub"
        n_same=$((n_same+1))
    else
        echo "  DRIFT   .$app/$sub (live differs; live wins)"
        n_drift=$((n_drift+1))
    fi

    if [ "$mode" = "apply" ]; then
        mkdir -p "$(dirname "$backup/.$app/$sub")"
        cp "$target" "$backup/.$app/$sub"
        # Live is authoritative: adopt it before the file is replaced.
        cmp -s "$target" "$repo" || cp "$target" "$repo"
        rm "$target"
        ln -s "$repo" "$target"
    fi
done <<< "$managed"

echo
echo "[migrate] $n_same same, $n_drift drifted, $n_absent absent, $n_linked already linked, $n_clobber foreign"
if [ "$n_clobber" -gt 0 ]; then
    echo "[migrate] FOREIGN entries point outside this checkout; resolve them by hand" >&2
    echo "[migrate] before switching, or home-manager will refuse to activate." >&2
fi
if [ "$mode" = "apply" ]; then
    echo "[migrate] originals backed up under $backup"
    echo "[migrate] linked into $ROOT_DIR/home"
    echo "[migrate] verify: scripts/verify-home-links.sh"
    echo "[migrate] undo:   scripts/migrate-home-configs.sh --rollback $stamp_new"
else
    echo "[migrate] dry run; nothing was moved. Re-run with --apply."
fi
