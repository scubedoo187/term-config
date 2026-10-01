# Headroom is opt-in: `hr <tool> …` routes a single invocation through the
# local proxy. Plain `claude` stays native, which is what /remote-control needs
# (Remote Control refuses to start unless ANTHROPIC_BASE_URL is api.anthropic.com).
#
# Deliberately not a wrapper around `headroom wrap`: wrap persists
# ANTHROPIC_BASE_URL into the project's .claude/settings.local.json, and Claude
# Code applies that `env` block to *every* session started there — which is how
# the proxy became global in the first place.
function hr --description "Run a provider CLI through the local Headroom proxy"
    if test (count $argv) -eq 0
        echo "usage: hr <claude|codex> [args…]" >&2
        return 2
    end

    if type -q nc; and not nc -z 127.0.0.1 8787 2>/dev/null
        echo "hr: nothing is listening on 127.0.0.1:8787 — run `headroom proxy` first" >&2
        return 1
    end

    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    test -n "$root"; or set root $PWD

    switch $argv[1]
        case claude
            env ANTHROPIC_BASE_URL=http://127.0.0.1:8787 \
                ANTHROPIC_CUSTOM_HEADERS="X-Headroom-Project: "(basename $root) \
                claude $argv[2..]
        case '*'
            # codex and friends route through their own config files, not env
            # (that is what `headroom init codex` installs), so let wrap own them.
            headroom wrap $argv
    end
end
