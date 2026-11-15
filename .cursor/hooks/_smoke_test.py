#!/usr/bin/env python3
"""Smoke runner — prefer `pytest tests/test_cursor_hooks.py -q`."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    return subprocess.call(
        [sys.executable, "-m", "pytest", "tests/test_cursor_hooks.py", "-q"],
        cwd=str(ROOT),
    )


if __name__ == "__main__":
    raise SystemExit(main())
