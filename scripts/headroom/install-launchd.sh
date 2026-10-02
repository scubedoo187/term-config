#!/bin/bash
set -euo pipefail

# Install (or with --uninstall, remove) the shared Headroom services as
# per-user LaunchAgents. See serve.sh for what each one does.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
agents="$HOME/Library/LaunchAgents"
logs="$HOME/.headroom/logs"
domain="gui/$(id -u)"
services=(proxy mcp mitm)

label() { echo "com.headroom.$1"; }

if [[ "${1:-}" == "--uninstall" ]]; then
    for svc in "${services[@]}"; do
        launchctl bootout "$domain/$(label "$svc")" 2>/dev/null || true
        rm -f "$agents/$(label "$svc").plist"
    done
    exit 0
fi

mkdir -p "$agents" "$logs"

for svc in "${services[@]}"; do
    plist="$agents/$(label "$svc").plist"
    cat > "$plist" <<EOF
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
    launchctl bootout "$domain/$(label "$svc")" 2>/dev/null || true
    launchctl bootstrap "$domain" "$plist"
done
