#!/usr/bin/env python3
"""PreToolUse (Bash): deny a small set of destructive shell patterns.

Fail-open on parse errors. Only an explicit deny blocks the tool.
"""
from __future__ import annotations

import json
import re
import sys

ALLOW = {"decision": "allow"}

# Conservative: block filesystem destruction at the root, disk formatters,
# raw writes to block devices, and the classic fork bomb. Do not block
# `rm -rf` of a project subdirectory.
PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (
        re.compile(r"\brm\s+-[a-zA-Z-]*r[a-zA-Z-]*f[a-zA-Z-]*\s+/(\s|$|\*)"),
        "Blocked recursive delete of /",
    ),
    (
        re.compile(r"\brm\s+-[a-zA-Z-]*f[a-zA-Z-]*r[a-zA-Z-]*\s+/(\s|$|\*)"),
        "Blocked recursive delete of /",
    ),
    (re.compile(r"--no-preserve-root"), "Blocked rm --no-preserve-root"),
    (re.compile(r"\bmkfs(?:\.\w+)?\b"), "Blocked mkfs"),
    (re.compile(r"\bdd\b.*\bof=/dev/"), "Blocked dd write to a block device"),
    (re.compile(r":\(\)\s*\{\s*:\s*\|\s*:\s*&\s*;\s*\}\s*;"), "Blocked fork bomb"),
    (re.compile(r"\bwipefs\b"), "Blocked wipefs"),
]


def allow() -> None:
    json.dump(ALLOW, sys.stdout)
    sys.exit(0)


def deny(reason: str) -> None:
    json.dump({"decision": "deny", "reason": reason}, sys.stdout)
    sys.stderr.write(reason + "\n")
    sys.exit(2)


def command_from(payload: object) -> str:
    if not isinstance(payload, dict):
        return ""
    tool_input = payload.get("toolInput") or payload.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        return ""
    cmd = tool_input.get("command") or ""
    return cmd if isinstance(cmd, str) else ""


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        allow()
    cmd = command_from(payload)
    if not cmd:
        allow()
    for pattern, reason in PATTERNS:
        if pattern.search(cmd):
            deny(reason)
    allow()


if __name__ == "__main__":
    main()
