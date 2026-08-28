#!/usr/bin/env python3
"""PostToolUse: run gofmt -w on an edited .go file. Fail-open."""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys


def path_from(payload: object) -> str:
    if not isinstance(payload, dict):
        return ""
    tool_input = payload.get("toolInput") or payload.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        return ""
    for key in ("file_path", "path", "target_file"):
        value = tool_input.get(key)
        if isinstance(value, str) and value:
            return value
    return ""


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    path = path_from(payload)
    if not path.endswith(".go") or not os.path.isfile(path):
        sys.exit(0)

    gofmt = shutil.which("gofmt")
    if not gofmt:
        sys.exit(0)

    subprocess.run([gofmt, "-w", path], check=False)
    sys.exit(0)


if __name__ == "__main__":
    main()
