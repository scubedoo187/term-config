"""mitmproxy addon: send Claude Code's Messages API calls through Headroom.

Claude Code refuses /remote-control whenever ANTHROPIC_BASE_URL points
anywhere but api.anthropic.com, but it does honour HTTPS_PROXY. So instead of
rewriting the base URL, Claude talks to api.anthropic.com as usual through this
proxy, and only /v1/messages* is handed to the local Headroom proxy. Everything
else on that host -- OAuth, the Remote Control bridge, telemetry -- goes
upstream untouched.

If Headroom is down, requests fail open to api.anthropic.com rather than
breaking every session.
"""

import os
import socket
import time

from mitmproxy import http

UPSTREAM_HOST = "api.anthropic.com"
ROUTED_PREFIXES = ("/v1/messages",)
HEADROOM = ("127.0.0.1", int(os.environ.get("HEADROOM_PORT", "8787")))
PROBE_TTL = 5.0

_probe = {"at": float("-inf"), "up": False}


def _headroom_up() -> bool:
    now = time.monotonic()
    if now - _probe["at"] >= PROBE_TTL:
        try:
            socket.create_connection(HEADROOM, timeout=0.2).close()
            _probe["up"] = True
        except OSError:
            _probe["up"] = False
        _probe["at"] = now
    return _probe["up"]


def request(flow: http.HTTPFlow) -> None:
    req = flow.request
    if req.pretty_host != UPSTREAM_HOST or not req.path.startswith(ROUTED_PREFIXES):
        return
    if not _headroom_up():
        return
    req.scheme = "http"
    req.host, req.port = HEADROOM
    req.host_header = UPSTREAM_HOST


def responseheaders(flow: http.HTTPFlow) -> None:
    # Messages responses are SSE; buffering them would stall every token.
    flow.response.stream = True
