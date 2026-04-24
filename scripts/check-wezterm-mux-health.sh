#!/bin/bash
set -euo pipefail

WEZTERM_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/wezterm"
AGENT_WARN_THRESHOLD="${AGENT_WARN_THRESHOLD:-150}"
GUI_SOCK_WARN_THRESHOLD="${GUI_SOCK_WARN_THRESHOLD:-10}"
MUX_ERR_LOG_WARN_MB="${MUX_ERR_LOG_WARN_MB:-20}"
MUX_RSS_WARN_KB="${MUX_RSS_WARN_KB:-262144}"

verdict="healthy"
reasons=()

agent_count=$(find "$WEZTERM_DATA_DIR" -maxdepth 1 -name 'agent.*' | wc -l | tr -d ' ')
gui_sock_count=$(find "$WEZTERM_DATA_DIR" -maxdepth 1 -name 'gui-sock-*' | wc -l | tr -d ' ')

rss_kb=0
if pgrep -f wezterm-mux-server >/dev/null 2>&1; then
  rss_kb=$(ps -o rss= -p "$(pgrep -f wezterm-mux-server | head -n 1)" | tr -d ' ')
fi

err_log_bytes=0
if [ -f "$WEZTERM_DATA_DIR/mux-server-error.log" ]; then
  err_log_bytes=$(stat -f%z "$WEZTERM_DATA_DIR/mux-server-error.log" 2>/dev/null || echo 0)
fi
err_log_mb=$((err_log_bytes / 1024 / 1024))

if [ "$agent_count" -gt "$AGENT_WARN_THRESHOLD" ]; then
  verdict="warning"
  reasons+=("agent symlinks high: $agent_count > $AGENT_WARN_THRESHOLD")
fi

if [ "$gui_sock_count" -gt "$GUI_SOCK_WARN_THRESHOLD" ]; then
  verdict="warning"
  reasons+=("gui sock count high: $gui_sock_count > $GUI_SOCK_WARN_THRESHOLD")
fi

if [ "$err_log_mb" -gt "$MUX_ERR_LOG_WARN_MB" ]; then
  verdict="warning"
  reasons+=("mux-server-error.log large: ${err_log_mb}MB > ${MUX_ERR_LOG_WARN_MB}MB")
fi

if [ "$rss_kb" -gt "$MUX_RSS_WARN_KB" ]; then
  verdict="warning"
  reasons+=("mux RSS high: ${rss_kb}KB > ${MUX_RSS_WARN_KB}KB")
fi

escape_error_count=$(python3 - <<'PY'
from pathlib import Path
p = Path.home()/'.local/share/wezterm/mux-server-error.log'
if not p.exists():
    print(0)
    raise SystemExit
count = 0
for line in p.read_text(errors='ignore').splitlines():
    if 'wezterm_escape_parser::parser' in line:
        count += 1
print(count)
PY
)

sixel_error_count=$(python3 - <<'PY'
from pathlib import Path
p = Path.home()/'.local/share/wezterm/mux-server-error.log'
if not p.exists():
    print(0)
    raise SystemExit
count = 0
for line in p.read_text(errors='ignore').splitlines():
    if 'terminalstate::sixel' in line:
        count += 1
print(count)
PY
)

if [ "$escape_error_count" -gt 0 ] || [ "$sixel_error_count" -gt 0 ]; then
  verdict="warning"
  reasons+=("parser warnings present: escape=${escape_error_count}, sixel=${sixel_error_count}")
fi

echo "[mux] verdict"
echo "$verdict"
if [ "${#reasons[@]}" -gt 0 ]; then
  printf '%s\n' "${reasons[@]}"
fi

echo "[mux] process"
if pgrep -f wezterm-mux-server >/dev/null 2>&1; then
  ps -o pid=,ppid=,rss=,vsz=,%cpu=,etime=,command= -p "$(pgrep -f wezterm-mux-server | head -n 1)"
else
  echo "not running"
fi

echo
echo "[mux] socket"
ls -l "$WEZTERM_DATA_DIR/sock" 2>/dev/null || echo "missing"

echo
echo "[mux] file counts"
printf "agents: "
echo "$agent_count"
printf "gui-socks: "
echo "$gui_sock_count"

echo
echo "[mux] log sizes"
du -sh "$WEZTERM_DATA_DIR"/mux-server*.log "$WEZTERM_DATA_DIR"/wezterm-*-log-*.txt 2>/dev/null || true

echo
echo "[mux] error counters"
echo "escape_parser: $escape_error_count"
echo "sixel: $sixel_error_count"

echo
echo "[mux] recent errors"
tail -n 40 "$WEZTERM_DATA_DIR/mux-server-error.log" 2>/dev/null || echo "no mux-server-error.log"
