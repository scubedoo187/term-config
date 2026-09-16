#!/bin/bash
#
# Claude Code statusLine, mirroring the enabled modules/format from the
# user's Starship config (~/.config/starship.toml -> term-config repo),
# used as the visible prompt for the fish shell (config.fish runs
# `starship init fish`).
#
# Ported modules (in the order Starship renders them):
#   directory   -> [directory]   truncation_length=3, truncate_to_repo=true,
#                  home_symbol="~", read_only=" 󰌾"
#   git_branch  -> [git_branch]  symbol="󰊢 ", truncation_length=20
#   git_status  -> [git_status]  conflicted/staged/renamed/modified/deleted/
#                  untracked/stashed counts + ahead/behind
#   nodejs/python/rust/golang -> shown only when the matching project files
#                  are present in the current directory, same detection
#                  Starship uses
#
# Skipped on purpose (they describe interactive-shell command state that
# doesn't exist in a Claude Code turn):
#   docker_context, cmd_duration, status (exit code), character (prompt glyph)

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir')
[ -z "$cwd" ] || [ "$cwd" = "null" ] && cwd="$PWD"

RESET=$'\033[0m'
BOLD_CYAN=$'\033[1;36m'
BOLD_PURPLE=$'\033[1;35m'
BOLD_RED=$'\033[1;31m'
RED=$'\033[0;31m'
BOLD_GREEN=$'\033[1;32m'
BOLD_YELLOW=$'\033[1;33m'
BOLD_BLUE=$'\033[1;34m'
BOLD_WHITE=$'\033[1;37m'

# ---------------------------------------------------------------------------
# Session identity, placed at the very front of the line (identifies the
# session rather than measuring usage): session name, model, fast-mode.
#
#   .session_name        -> string, key omitted entirely unless the user has
#                            renamed the session via /rename. Degrades to
#                            nothing when absent (jq `// empty`).
#   .model.display_name  -> string, always present; .model.id is the raw
#                            fallback if display_name were ever missing.
#   .fast_mode            -> boolean, always present. Only the literal
#                            string "true" renders a marker; "false", "null"
#                            (missing key) and anything else render nothing.
#                            Per the false-vs-absent jq caveat, this is read
#                            directly (no `// empty`) and compared with `=`.
# ---------------------------------------------------------------------------
session_segment=""
session_name=$(printf '%s' "$input" | jq -r '.session_name // empty')
[ -n "$session_name" ] && session_segment="${BOLD_BLUE}${session_name}${RESET} "

model_segment=""
model_name=$(printf '%s' "$input" | jq -r '.model.display_name // .model.id // empty')
[ -n "$model_name" ] && model_segment="${BOLD_WHITE}${model_name}${RESET} "

fast_segment=""
fast_mode=$(printf '%s' "$input" | jq -r '.fast_mode')
[ "$fast_mode" = "true" ] && fast_segment="${BOLD_YELLOW}⚡${RESET} "

# ---------------------------------------------------------------------------
# [directory]: truncation_length = 3, truncate_to_repo = true, home_symbol="~"
# truncation_symbol = "…/", read_only = " 󰌾"
# ---------------------------------------------------------------------------
if [ "$cwd" = "$HOME" ]; then
    dir_display="~"
elif [ "${cwd#"$HOME"/}" != "$cwd" ]; then
    dir_display="~/${cwd#"$HOME"/}"
else
    dir_display="$cwd"
fi

repo_root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
repo_name=""
[ -n "$repo_root" ] && repo_name=$(basename "$repo_root")

IFS='/' read -ra raw_parts <<< "$dir_display"
dir_parts=()
for p in "${raw_parts[@]}"; do
    [ -n "$p" ] && dir_parts+=("$p")
done

trunc_len=3
count=${#dir_parts[@]}
if [ "$count" -gt "$trunc_len" ]; then
    start=$((count - trunc_len))
    # truncate_to_repo: never truncate past the repository's top-level dir
    if [ -n "$repo_name" ]; then
        for i in "${!dir_parts[@]}"; do
            if [ "${dir_parts[$i]}" = "$repo_name" ] && [ "$i" -lt "$start" ]; then
                start=$i
            fi
        done
    fi
    kept=("${dir_parts[@]:$start}")
    dir_out="…/$(IFS=/; printf '%s' "${kept[*]}")"
else
    dir_out="$dir_display"
fi

read_only=""
[ -n "$cwd" ] && [ ! -w "$cwd" ] && read_only=" 󰌾"

directory_segment="${BOLD_CYAN}${dir_out}${RESET}"
[ -n "$read_only" ] && directory_segment="${directory_segment}${RED}${read_only}${RESET}"
directory_segment="${directory_segment} "

# ---------------------------------------------------------------------------
# [git_branch]: symbol="󰊢 ", style="bold purple", truncation_length=20
# ---------------------------------------------------------------------------
branch=""
branch_segment=""
if [ -n "$repo_root" ]; then
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ] && [ "$branch" != "HEAD" ]; then
        display_branch="$branch"
        if [ ${#display_branch} -gt 20 ]; then
            display_branch="${display_branch:0:20}…"
        fi
        remote_branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
        if [ -n "$remote_branch" ]; then
            branch_text="on 󰊢 ${display_branch}:${remote_branch} "
        else
            branch_text="on 󰊢 ${display_branch} "
        fi
        branch_segment="${BOLD_PURPLE}${branch_text}${RESET}"
    fi
fi

# ---------------------------------------------------------------------------
# [git_status]: conflicted="=", staged="+", renamed="»", modified="!",
# deleted="✘", untracked="?", stashed="$", ahead="⇡", behind="⇣"
# ---------------------------------------------------------------------------
status_segment=""
if [ -n "$branch" ]; then
    porcelain=$(git -C "$cwd" --no-optional-locks status --porcelain=v1 2>/dev/null)
    conflicted=$(printf '%s\n' "$porcelain" | grep -cE '^(UU|AA|DD|AU|UA|UD|DU)')
    staged=$(printf '%s\n' "$porcelain" | grep -cE '^[^ ?]')
    renamed=$(printf '%s\n' "$porcelain" | grep -c '^R')
    modified=$(printf '%s\n' "$porcelain" | grep -c '^.M')
    deleted=$(printf '%s\n' "$porcelain" | grep -c '^.D')
    untracked=$(printf '%s\n' "$porcelain" | grep -c '^??')
    stashed=$(git -C "$cwd" --no-optional-locks stash list 2>/dev/null | wc -l | tr -d ' ')
    ab=$(git -C "$cwd" --no-optional-locks rev-list --left-right --count 'HEAD...@{u}' 2>/dev/null)
    ahead=$(printf '%s' "$ab" | awk '{print $1+0}')
    behind=$(printf '%s' "$ab" | awk '{print $2+0}')

    all_status=""
    [ "${conflicted:-0}" -gt 0 ] && all_status="${all_status}=${conflicted}"
    [ "${staged:-0}" -gt 0 ] && all_status="${all_status}+${staged}"
    [ "${renamed:-0}" -gt 0 ] && all_status="${all_status}»${renamed}"
    [ "${modified:-0}" -gt 0 ] && all_status="${all_status}!${modified}"
    [ "${deleted:-0}" -gt 0 ] && all_status="${all_status}✘${deleted}"
    [ "${untracked:-0}" -gt 0 ] && all_status="${all_status}?${untracked}"
    [ "${stashed:-0}" -gt 0 ] && all_status="${all_status}\$${stashed}"

    ahead_behind=""
    if [ "${ahead:-0}" -gt 0 ] && [ "${behind:-0}" -gt 0 ]; then
        ahead_behind="⇕⇡${ahead}⇣${behind}"
    elif [ "${ahead:-0}" -gt 0 ]; then
        ahead_behind="⇡${ahead}"
    elif [ "${behind:-0}" -gt 0 ]; then
        ahead_behind="⇣${behind}"
    fi

    if [ -n "${all_status}${ahead_behind}" ]; then
        status_segment="${BOLD_RED}(${all_status}${ahead_behind}) ${RESET}"
    fi
fi

# ---------------------------------------------------------------------------
# Language modules: only rendered when the same marker files/extensions
# Starship checks for are present in the current directory.
# ---------------------------------------------------------------------------
has_ext() {
    local ext
    for ext in "$@"; do
        compgen -G "$cwd/*.$ext" > /dev/null 2>&1 && return 0
    done
    return 1
}

lang_segment=""

if command -v node > /dev/null 2>&1 && {
    [ -f "$cwd/package.json" ] || [ -f "$cwd/.node-version" ] || [ -f "$cwd/.nvmrc" ] ||
    [ -d "$cwd/node_modules" ] || has_ext js mjs cjs ts mts cts
}; then
    v=$(node --version 2>/dev/null | tr -d 'v')
    [ -n "$v" ] && lang_segment="${lang_segment}${BOLD_GREEN}via  v${v} ${RESET}"
fi

if command -v python3 > /dev/null 2>&1 && {
    [ -f "$cwd/.python-version" ] || [ -f "$cwd/Pipfile" ] || [ -f "$cwd/pyproject.toml" ] ||
    [ -f "$cwd/requirements.txt" ] || [ -f "$cwd/setup.py" ] || has_ext py
}; then
    v=$(python3 --version 2>/dev/null | awk '{print $2}')
    [ -n "$v" ] && lang_segment="${lang_segment}${BOLD_YELLOW}via  v${v} ${RESET}"
fi

if command -v rustc > /dev/null 2>&1 && { [ -f "$cwd/Cargo.toml" ] || has_ext rs; }; then
    v=$(rustc --version 2>/dev/null | awk '{print $2}')
    [ -n "$v" ] && lang_segment="${lang_segment}${BOLD_RED}via 🦀 v${v} ${RESET}"
fi

if command -v go > /dev/null 2>&1 && {
    [ -f "$cwd/go.mod" ] || [ -f "$cwd/go.sum" ] || has_ext go
}; then
    v=$(go version 2>/dev/null | awk '{print $3}' | tr -d 'go')
    [ -n "$v" ] && lang_segment="${lang_segment}${BOLD_CYAN}via  v${v} ${RESET}"
fi

# ---------------------------------------------------------------------------
# Helper: render a seconds count as "3d4h" / "12h30m" / "45m"
# ---------------------------------------------------------------------------
format_duration() {
    local total=$1 d h m
    d=$((total / 86400))
    h=$(((total % 86400) / 3600))
    m=$(((total % 3600) / 60))
    if [ "$d" -gt 0 ]; then
        printf '%dd%dh' "$d" "$h"
    elif [ "$h" -gt 0 ]; then
        printf '%dh%dm' "$h" "$m"
    else
        printf '%dm' "$m"
    fi
}

now=$(date +%s)

# ---------------------------------------------------------------------------
# Context window remaining: .context_window.remaining_percentage
# Green when >=50% free, yellow 20-49%, red <20%. Omitted whenever the field
# is missing/null so nothing is ever printed for "null" or a stale 0%.
# ---------------------------------------------------------------------------
context_segment=""
ctx_remaining=$(printf '%s' "$input" | jq -r '.context_window.remaining_percentage // empty')
if [ -n "$ctx_remaining" ]; then
    ctx_pct=$(awk -v v="$ctx_remaining" 'BEGIN{printf "%.0f", v}' 2>/dev/null)
    if [ -n "$ctx_pct" ]; then
        if [ "$ctx_pct" -ge 50 ]; then
            ctx_color="$BOLD_GREEN"
        elif [ "$ctx_pct" -ge 20 ]; then
            ctx_color="$BOLD_YELLOW"
        else
            ctx_color="$BOLD_RED"
        fi
        context_segment="${ctx_color}ctx:${ctx_pct}%${RESET} "
    fi
fi

# ---------------------------------------------------------------------------
# 5-hour quota left + time until reset: .rate_limits.five_hour.{used_percentage,
# resets_at}. Rendered immediately before the weekly segment since the 5-hour
# window usually binds first. Reuses the same thresholds/format_duration as
# the weekly segment; degrades silently exactly like it does.
# ---------------------------------------------------------------------------
five_hour_segment=""
five_hour_used=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$five_hour_used" ]; then
    five_hour_left=$(awk -v u="$five_hour_used" 'BEGIN{v=100-u; if (v<0) v=0; if (v>100) v=100; printf "%.0f", v}' 2>/dev/null)
    if [ -n "$five_hour_left" ]; then
        if [ "$five_hour_left" -ge 50 ]; then
            fh_color="$BOLD_GREEN"
        elif [ "$five_hour_left" -ge 20 ]; then
            fh_color="$BOLD_YELLOW"
        else
            fh_color="$BOLD_RED"
        fi
        five_hour_segment="${fh_color}5h:${five_hour_left}%${RESET}"

        five_hour_resets=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
        if [ -n "$five_hour_resets" ]; then
            fh_secs_left=$(awk -v r="$five_hour_resets" -v n="$now" 'BEGIN{printf "%.0f", r-n}' 2>/dev/null)
            if [ -n "$fh_secs_left" ] && [ "$fh_secs_left" -gt 0 ]; then
                fh_reset_str=$(format_duration "$fh_secs_left")
                [ -n "$fh_reset_str" ] && five_hour_segment="${five_hour_segment} ${fh_color}(resets ${fh_reset_str})${RESET}"
            fi
        fi
        five_hour_segment="${five_hour_segment} "
    fi
fi

# ---------------------------------------------------------------------------
# Weekly quota left + time until reset: .rate_limits.seven_day.{used_percentage,
# resets_at}. "rate_limits" only exists for claude.ai subscription sessions
# (absent on API/gateway auth), so every lookup below degrades silently to an
# empty segment when the key, or any parent key, is missing or null.
# resets_at is Unix epoch seconds.
# ---------------------------------------------------------------------------
quota_segment=""
week_used=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$week_used" ]; then
    week_left=$(awk -v u="$week_used" 'BEGIN{v=100-u; if (v<0) v=0; if (v>100) v=100; printf "%.0f", v}' 2>/dev/null)
    if [ -n "$week_left" ]; then
        if [ "$week_left" -ge 50 ]; then
            wk_color="$BOLD_GREEN"
        elif [ "$week_left" -ge 20 ]; then
            wk_color="$BOLD_YELLOW"
        else
            wk_color="$BOLD_RED"
        fi
        quota_segment="${wk_color}wk:${week_left}%${RESET}"

        week_resets=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
        if [ -n "$week_resets" ]; then
            secs_left=$(awk -v r="$week_resets" -v n="$now" 'BEGIN{printf "%.0f", r-n}' 2>/dev/null)
            if [ -n "$secs_left" ] && [ "$secs_left" -gt 0 ]; then
                reset_str=$(format_duration "$secs_left")
                [ -n "$reset_str" ] && quota_segment="${quota_segment} ${wk_color}(resets ${reset_str})${RESET}"
            fi
        fi
        quota_segment="${quota_segment} "
    fi
fi

printf '%s' "${session_segment}${model_segment}${fast_segment}${directory_segment}${branch_segment}${status_segment}${lang_segment}${context_segment}${five_hour_segment}${quota_segment}"
