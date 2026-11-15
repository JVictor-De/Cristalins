#!/usr/bin/env python3
"""beforeReadFile / beforeTabFileRead: block secret files from reaching the model."""

from __future__ import annotations

import json
import re
import sys
from pathlib import PurePosixPath, PureWindowsPath

ALLOW_BASENAMES = {
    ".env.example",
    ".env.sample",
    ".env.template",
    ".env.dist",
}

SENSITIVE_BASENAME = re.compile(
    r"^(?:"
    r"\.env(?:\..+)?|"
    r".+\.pem|"
    r".+\.key|"
    r"id_rsa(?:\.pub)?|"
    r"id_ed25519(?:\.pub)?|"
    r"credentials\.json|"
    r"service-account.*\.json|"
    r".*secrets?\.json|"
    r".*token.*\.(?:json|txt|env|yml|yaml)|"
    r".*secret.*\.(?:json|txt|env|yml|yaml|pem|key)"
    r")$",
    re.I,
)

SENSITIVE_SEGMENTS = {".ssh", "credentials", "secrets"}


def _read_stdin() -> str:
    return sys.stdin.buffer.read().decode("utf-8-sig", errors="replace")


def _normalize_parts(file_path: str) -> list[str]:
    raw = file_path.replace("\\", "/")
    if len(raw) >= 2 and raw[1] == ":":
        raw = raw[2:]
    path = PurePosixPath(raw)
    return [p for p in path.parts if p not in ("/", "")]


def _basename(file_path: str) -> str:
    normalized = file_path.replace("\\", "/")
    return PurePosixPath(normalized).name


def is_secret_path(file_path: str) -> bool:
    """True when the path should not be sent to the model."""
    if not file_path:
        return False

    base = _basename(file_path)
    if base.lower() in {b.lower() for b in ALLOW_BASENAMES}:
        return False

    if SENSITIVE_BASENAME.match(base):
        return True

    parts_lower = {p.lower() for p in _normalize_parts(file_path)}
    if parts_lower & SENSITIVE_SEGMENTS:
        return True

    try:
        win_name = PureWindowsPath(file_path).name
        if win_name != base and SENSITIVE_BASENAME.match(win_name):
            return True
    except Exception:
        pass

    return False


def _respond(permission: str, user_message: str = "") -> None:
    out: dict[str, str] = {"permission": permission}
    if user_message:
        out["user_message"] = user_message
    sys.stdout.buffer.write((json.dumps(out, ensure_ascii=False) + "\n").encode("utf-8"))
    sys.stdout.buffer.flush()


def main() -> int:
    raw = _read_stdin()
    try:
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        # Malformed hook payload must not lock the agent (fail open).
        _respond("allow")
        return 0

    if not isinstance(data, dict):
        _respond("allow")
        return 0

    file_path = data.get("file_path") or ""
    if not isinstance(file_path, str):
        file_path = str(file_path)

    if is_secret_path(file_path):
        _respond(
            "deny",
            f"Leitura bloqueada (secret/credencial): {file_path}",
        )
        return 0

    _respond("allow")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
