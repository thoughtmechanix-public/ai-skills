#!/usr/bin/env python3
"""PostToolUse: append a truncated JSONL record. Passive; never blocks."""
from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timezone

MAX_INPUT = 2048


def data_dir() -> str:
    path = os.environ.get("GROK_PLUGIN_DATA") or os.path.join(
        os.environ.get("TMPDIR", "/tmp"), "grok-plugin-core"
    )
    os.makedirs(path, exist_ok=True)
    return path


def truncate(value: object) -> object:
    raw = json.dumps(value, default=str)
    if len(raw) <= MAX_INPUT:
        return value
    return raw[:MAX_INPUT] + f"… [+{len(raw) - MAX_INPUT} chars]"


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    if not isinstance(payload, dict):
        sys.exit(0)

    record = {
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "session": os.environ.get("GROK_SESSION_ID"),
        "event": os.environ.get("GROK_HOOK_EVENT"),
        "tool": payload.get("toolName") or payload.get("tool_name"),
        "cwd": payload.get("cwd") or os.environ.get("GROK_WORKSPACE_ROOT"),
        "input": truncate(payload.get("toolInput") or payload.get("tool_input") or {}),
    }
    dest = os.path.join(data_dir(), "tool-use.jsonl")
    with open(dest, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(record, default=str) + "\n")
    sys.exit(0)


if __name__ == "__main__":
    main()
