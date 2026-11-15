#!/usr/bin/env python3
"""beforeShellExecution: deny force/destructive git; ask for push."""

from __future__ import annotations

import json
import re
import sys

PROTECTED_DIRS = (
    "node_modules",
    ".venv",
    "uploads",
    "training_data",
)

# git / git.exe with optional -C <path> and short/long flags before the subcommand.
_GIT = (
    r"\bgit(?:\.exe)?(?:\s+(?:-C\s+[^\s]+|-[a-zA-Z0-9][^\s]*|--[^\s=]+(?:=[^\s]+)?))*\s+"
)

# Force push: --force / --force-with-lease / -f / -uf / +refspec
_FORCE_PUSH = (
    r"(?:"
    r"--force(?:-with-lease)?(?:\s|=|$)|"
    r"(?<!\S)-[a-zA-Z]*f[a-zA-Z]*(?=\s|$)|"
    r"\s\+[^\s]+"
    r")"
)

DENY_GIT = [
    (
        re.compile(_GIT + r"push\b[^\n]*" + _FORCE_PUSH, re.I),
        "git push --force (ou +refspec) bloqueado.",
    ),
    (
        re.compile(_GIT + r"reset\b[^\n]*--hard\b", re.I),
        "git reset --hard bloqueado.",
    ),
    (
        re.compile(_GIT + r"clean\b[^\n]*-[^\s]*f", re.I),
        "git clean -f bloqueado.",
    ),
    (
        re.compile(_GIT + r"config\b", re.I),
        "git config bloqueado.",
    ),
]

ASK_GIT_PUSH = (
    re.compile(_GIT + r"push\b", re.I),
    "git push requer aprovação (card). Use só se o usuário pediu push/PR.",
)

_DIR_ALT = "|".join(re.escape(d) for d in PROTECTED_DIRS)
# Avoid \\b before dotted names like .venv (\\b does not fire before '.').
_DIR = rf"(?<![\w])(?:{_DIR_ALT})(?![\w])"
_DELETE_VERB = (
    r"(?:rm\s+-[^\s]*r|rimraf|Remove-Item\b[^\n]*-Recurse|"
    r"rd\s+/s|rmdir\s+/s|del\s+/s)"
)

DENY_DELETE = [
    re.compile(_DELETE_VERB + rf"[^\n]*{_DIR}", re.I),
    re.compile(_DIR + r"[^\n]*" + _DELETE_VERB, re.I),
]


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


def classify_command(command: str) -> tuple[str, str, str]:
    """Return (permission, user_message, agent_message)."""
    for pattern, reason in DENY_GIT:
        if pattern.search(command):
            return (
                "deny",
                reason,
                f"Hook gate_shell bloqueou o comando: {reason}",
            )

    for pattern in DENY_DELETE:
        if pattern.search(command):
            reason = (
                "Apagar pastas protegidas (node_modules/.venv/uploads/training_data) "
                "está bloqueado."
            )
            return ("deny", reason, f"Hook gate_shell bloqueou: {reason}")

    push_pat, push_reason = ASK_GIT_PUSH
    if push_pat.search(command):
        return (
            "ask",
            push_reason,
            f"Hook gate_shell pede aprovação: {push_reason}",
        )

    return ("allow", "", "")


def main() -> int:
    raw = _read_stdin()
    try:
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        # Cursor on Windows may send BOM; utf-8-sig usually fixes it.
        # If still unreadable, fail open so the agent is not locked out.
        _respond("allow")
        return 0

    if not isinstance(data, dict):
        _respond("allow")
        return 0

    command = data.get("command") or ""
    if not isinstance(command, str):
        command = str(command)
    permission, user_msg, agent_msg = classify_command(command)
    _respond(permission, user_msg, agent_msg)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
