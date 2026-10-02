#!/bin/bash
set -euo pipefail

# One-shot setup for the shared Headroom stack (macOS). Safe to re-run.
#
#   ./scripts/headroom/setup.sh              install / repair
#   ./scripts/headroom/setup.sh --uninstall  remove agents and the Claude MCP entry
#
# What it sets up:
#   1. mitmproxy (uv tool), whose CA lands in ~/.headroom/mitm on first start
#   2. LaunchAgents com.headroom.{proxy,mcp,mitm}, each running serve.sh
#   3. Claude Code's user-scope `headroom` MCP -> http://127.0.0.1:8788/mcp
#      (~/.claude.json is not tracked; Codex's entry lives in home/codex)
#
# The fish `claude` wrapper (.config/fish/conf.d/headroom.fish) picks the stack
# up automatically once :8789 is listening.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
agents="$HOME/Library/LaunchAgents"
logs="$HOME/.headroom/logs"
ca="$HOME/.headroom/mitm/mitmproxy-ca-cert.pem"
mcp_url="http://127.0.0.1:8788/mcp"
domain="gui/$(id -u)"
services=(proxy mcp mitm)

label() { echo "com.headroom.$1"; }
log()   { echo "==> $*"; }
warn()  { echo "warning: $*" >&2; }

plist_for() {
    local svc="$1"
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$(label "$svc")</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$here/serve.sh</string>
        <string>$svc</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>10</integer>
    <key>StandardOutPath</key>
    <string>$logs/launchd-$svc.log</string>
    <key>StandardErrorPath</key>
    <string>$logs/launchd-$svc.log</string>
</dict>
</plist>
EOF
}

wait_for() {
    local what="$1" check="$2" i
    for i in $(seq 1 60); do
        eval "$check" && return 0
        sleep 1
    done
    warn "$what did not come up within 60s (see $logs/launchd-*.log)"
    return 1
}

uninstall() {
    for svc in "${services[@]}"; do
        launchctl bootout "$domain/$(label "$svc")" 2>/dev/null || true
        rm -f "$agents/$(label "$svc").plist"
    done
    log "removed LaunchAgents"
    if command -v claude >/dev/null && claude mcp get headroom >/dev/null 2>&1; then
        claude mcp remove headroom -s user >/dev/null
        log "removed Claude MCP entry 'headroom'"
    fi
    log "left in place: mitmproxy (uv tool), ~/.headroom/mitm CA, Codex config"
}

if [[ "$(uname -s)" != Darwin ]]; then
    echo "setup.sh: macOS only (uses launchd)" >&2
    exit 1
fi

if [[ "${1:-}" == "--uninstall" ]]; then
    uninstall
    exit 0
fi

# --- 1. binaries ---------------------------------------------------------
for cmd in headroom uv claude nc; do
    command -v "$cmd" >/dev/null || { echo "setup.sh: '$cmd' not found on PATH" >&2; exit 1; }
done

if ! command -v mitmdump >/dev/null; then
    log "installing mitmproxy"
    uv tool install mitmproxy
fi

# --- 2. LaunchAgents -----------------------------------------------------
# Only reload an agent whose plist actually changed: bootout kills the running
# service, and live Claude sessions depend on the mitm.
mkdir -p "$agents" "$logs"
for svc in "${services[@]}"; do
    plist="$agents/$(label "$svc").plist"
    desired="$(plist_for "$svc")"
    if [[ -f "$plist" && "$(cat "$plist")" == "$desired" ]] \
        && launchctl print "$domain/$(label "$svc")" >/dev/null 2>&1; then
        log "$(label "$svc") up to date"
        continue
    fi
    printf '%s\n' "$desired" > "$plist"
    launchctl bootout "$domain/$(label "$svc")" 2>/dev/null || true
    launchctl bootstrap "$domain" "$plist"
    log "loaded $(label "$svc")"
done

wait_for "mitm (:8789)"      "nc -z 127.0.0.1 8789 2>/dev/null" || true
wait_for "mitmproxy CA"      "test -f '$ca'" || true
wait_for "Headroom MCP (:8788)" "nc -z 127.0.0.1 8788 2>/dev/null" || true

# --- 3. Claude MCP entry -------------------------------------------------
if claude mcp get headroom 2>/dev/null | grep -q "URL: $mcp_url"; then
    log "Claude MCP 'headroom' up to date"
else
    claude mcp remove headroom -s user >/dev/null 2>&1 || true
    claude mcp add --transport http -s user headroom "$mcp_url" >/dev/null
    log "registered Claude MCP 'headroom' -> $mcp_url"
fi

# --- status --------------------------------------------------------------
echo
for port in 8787 8788 8789; do
    if nc -z 127.0.0.1 "$port" 2>/dev/null; then state=listening; else state=down; fi
    printf '  :%s  %s\n' "$port" "$state"
done
if pgrep -f "serve.sh proxy" >/dev/null && ! pgrep -f "headroom.*proxy --host 127.0.0.1 --port 8787" >/dev/null; then
    echo "  (com.headroom.proxy is waiting for a hand-started proxy on :8787 to exit)"
fi
echo
log "done. Open a new fish shell (or 'exec fish'); plain 'claude' now goes through Headroom."
