# Claude Code goes through Headroom by default, via HTTPS_PROXY rather than
# ANTHROPIC_BASE_URL: Remote Control refuses to start unless the base URL is
# api.anthropic.com, but it does not care about a proxy. The shared mitm on
# :8789 (term-config/scripts/headroom, run by launchd) hands /v1/messages to the
# Headroom proxy on :8787 and passes everything else -- OAuth, the Remote
# Control bridge -- straight through. One set of services serves every session.
#
# Falls back to plain `claude` when the mitm is not up, when ANTHROPIC_BASE_URL
# is already set, or when HEADROOM_OFF is set (`HEADROOM_OFF=1 claude …`).
#
# Deliberately not `headroom wrap`: wrap persists ANTHROPIC_BASE_URL into the
# project's .claude/settings.local.json, which is what broke Remote Control.
function claude --wraps claude --description "Claude Code, routed through the shared Headroom proxy"
    if set -q HEADROOM_OFF; or set -q ANTHROPIC_BASE_URL; or not nc -z 127.0.0.1 8789 2>/dev/null
        command claude $argv
        return
    end

    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    test -n "$root"; or set root $PWD

    # The proxy env is inherited by every Bash tool call too; keep loopback
    # traffic (dev servers, the Headroom MCP on :8788) off it.
    env HTTPS_PROXY=http://127.0.0.1:8789 \
        NO_PROXY=localhost,127.0.0.1,::1 \
        NODE_EXTRA_CA_CERTS=$HOME/.headroom/mitm/mitmproxy-ca-cert.pem \
        ANTHROPIC_CUSTOM_HEADERS="X-Headroom-Project: "(basename $root) \
        command claude $argv
end

function hr --description "Run a provider CLI through the local Headroom proxy"
    if test (count $argv) -eq 0
        echo "usage: hr <claude|codex> [args…]" >&2
        return 2
    end

    switch $argv[1]
        case claude
            # Already routed by default; kept so `hr claude` muscle memory works.
            claude $argv[2..]
        case '*'
            # codex and friends route through their own config files, not env
            # (that is what `headroom init codex` installs), so let wrap own them.
            headroom wrap $argv
    end
end
