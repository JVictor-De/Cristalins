#!/usr/bin/env python3
"""afterFileEdit: fail-open reminder to run flutter tests when flutter_app/ changes."""

from __future__ import annotations

import json
import sys


FOLLOWUP = (
    "Arquivo Flutter alterado. Rode: cd flutter_app; "
    "flutter test test/entrada_partida_test.dart test/partidas_janela_test.dart "
    "(ou a suíte do módulo tocado)."
)

_PATH_KEYS = ("file_path", "path", "filePath", "file")


def _read_stdin() -> str:
    return sys.stdin.buffer.read().decode("utf-8-sig", errors="replace")


def _respond(payload: dict) -> None:
    sys.stdout.buffer.write(
        (json.dumps(payload, ensure_ascii=False) + "\n").encode("utf-8")
    )
    sys.stdout.buffer.flush()


def _paths_from_mapping(item: dict) -> list[str]:
    out: list[str] = []
    for key in _PATH_KEYS:
        val = item.get(key)
        if isinstance(val, str) and val.strip():
            out.append(val)
    return out


def _collect_paths(data: dict) -> list[str]:
    paths = _paths_from_mapping(data)
    for key in ("paths", "files", "edits"):
        val = data.get(key)
        if not isinstance(val, list):
            continue
        for item in val:
            if isinstance(item, str) and item.strip():
                paths.append(item)
            elif isinstance(item, dict):
                paths.extend(_paths_from_mapping(item))
    return paths


def is_flutter_app_path(file_path: str) -> bool:
    """True if a path segment is exactly ``flutter_app`` (lib/test/etc.)."""
    if not file_path or not isinstance(file_path, str):
        return False
    parts = [p for p in file_path.replace("\\", "/").split("/") if p]
    return any(p.lower() == "flutter_app" for p in parts)


def should_remind(paths: list[str]) -> bool:
    return any(is_flutter_app_path(p) for p in paths)


def main() -> int:
    raw = _read_stdin()
    try:
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        # fail-open: never block the edit
        _respond({})
        return 0

    if not isinstance(data, dict):
        _respond({})
        return 0

    paths = _collect_paths(data)
    if should_remind(paths):
        _respond({"followup_message": FOLLOWUP})
        return 0

    _respond({})
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
