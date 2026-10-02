#!/bin/bash
set -euo pipefail

# launchd entry point for the shared Headroom services. One instance of each
# serves every Claude Code / Codex session on the machine:
#
#   proxy  127.0.0.1:8787  headroom proxy (compression)
#   mcp    127.0.0.1:8788  headroom MCP over Streamable HTTP (headroom_retrieve …)
#   mitm   127.0.0.1:8789  HTTPS_PROXY for Claude; hands /v1/messages to :8787
#
# If something else already holds the port (e.g. a hand-started proxy that
# live sessions still depend on), wait for it to go away instead of crashing
# and letting launchd respawn us every ten seconds.

service="${1:?usage: serve.sh <proxy|mcp|mitm>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin="$HOME/.local/bin"

case "$service" in
    proxy) port=8787 ;;
    mcp)   port=8788 ;;
    mitm)  port=8789 ;;
    *) echo "serve.sh: unknown service: $service" >&2; exit 2 ;;
esac

# Never inherit a proxy: the upstream legs must go straight to the provider.
unset HTTPS_PROXY HTTP_PROXY https_proxy http_proxy ALL_PROXY all_proxy

while nc -z 127.0.0.1 "$port" 2>/dev/null; do
    sleep 30
done

case "$service" in
    proxy)
        exec "$bin/headroom" proxy --host 127.0.0.1 --port "$port"
        ;;
    mcp)
        exec "$bin/headroom" mcp serve --transport http \
            --host 127.0.0.1 --port "$port" --path /mcp \
            --proxy-url http://127.0.0.1:8787
        ;;
    mitm)
        # Only api.anthropic.com is decrypted; every other host is tunnelled
        # through as opaque TLS.
        exec "$bin/mitmdump" --quiet \
            --listen-host 127.0.0.1 --listen-port "$port" \
            --set confdir="$HOME/.headroom/mitm" \
            --allow-hosts '^api\.anthropic\.com(:443)?$' \
            -s "$here/route_messages.py"
        ;;
esac
