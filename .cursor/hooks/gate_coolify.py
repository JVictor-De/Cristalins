#!/usr/bin/env python3
"""beforeMCPExecution: ask before Coolify lifecycle/write tools."""

from __future__ import annotations

import json
import sys

WRITE_TOOLS = frozenset(
    {
        "deploy",
        "control",
        "cancel_deployment",
    }
)


def _read_stdin() -> str:
    return sys.stdin.buffer.read().decode("utf-8-sig", errors="replace")


def _respond(permission: str, user_message: str = "", agent_message: str = "") -> None:
    out: dict[str, str] = {"permission": permission}
    if user_message:
        out["user_message"] = user_message
    if agent_message:
        out["agent_message"] = agent_message
    sys.stdout.buffer.write((json.dumps(out, ensure_ascii=False) + "\n").encode("utf-8"))
    sys.stdout.buffer.flush()


def is_coolify_server(server_name: str) -> bool:
    return "coolify" in (server_name or "").lower()


def classify_coolify(tool_name: str, mcp_server_name: str) -> str:
    """Return permission: ask | allow."""
    name = (tool_name or "").strip()
    if is_coolify_server(mcp_server_name) and name in WRITE_TOOLS:
        return "ask"
    return "allow"


def main() -> int:
    raw = _read_stdin()
    try:
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        _respond("allow")
        return 0

    if not isinstance(data, dict):
        _respond("allow")
        return 0

    tool_name = data.get("tool_name") or ""
    if not isinstance(tool_name, str):
        tool_name = str(tool_name)
    server = data.get("mcp_server_name") or ""
    if not isinstance(server, str):
        server = str(server)

    if classify_coolify(tool_name, server) == "ask":
        tool = tool_name.strip()
        msg = (
            f"Coolify MCP `{tool}` requer aprovação no card "
            "(deploy/control/cancel). O card é a aprovação — não peça outro 'sim' no chat."
        )
        _respond("ask", msg, msg)
        return 0

    _respond("allow")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
