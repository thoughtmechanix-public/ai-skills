#!/usr/bin/env python3
"""PreToolUse (Bash): deny git push --force / -f to main or master.

--force-with-lease is allowed. Fail-open on parse errors.
"""
from __future__ import annotations

import json
import re
import sys

ALLOW = {"decision": "allow"}


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


def is_forced_push(cmd: str) -> bool:
    if not re.search(r"\bgit\s+push\b", cmd):
        return False
    # Allow lease; block bare --force and the -f short flag on push.
    if re.search(r"--force-with-lease\b", cmd):
        return False
    return bool(re.search(r"(^|\s)(--force|-f)(\s|$)", cmd))


def targets_protected_branch(cmd: str) -> bool:
    return bool(re.search(r"(^|[\s/:])(main|master)(\s|$)", cmd))


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        allow()
    cmd = command_from(payload)
    if not cmd:
        allow()
    if is_forced_push(cmd) and targets_protected_branch(cmd):
        deny("Blocked git push --force/-f to main or master")
    allow()


if __name__ == "__main__":
    main()
