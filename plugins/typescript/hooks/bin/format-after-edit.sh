#!/usr/bin/env python3
"""PostToolUse: format an edited TypeScript file. Fail-open.

Detection matches plugins/typescript/shared/toolchain.md (Formatter).
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys

EXTENSIONS = {".ts", ".tsx", ".mts", ".cts"}
BIOME_CONFIGS = {"biome.json", "biome.jsonc"}
PRETTIER_CONFIGS = {
    ".prettierrc",
    ".prettierrc.json",
    ".prettierrc.yml",
    ".prettierrc.yaml",
    ".prettierrc.json5",
    ".prettierrc.js",
    ".prettierrc.cjs",
    ".prettierrc.mjs",
    ".prettierrc.toml",
    "prettier.config.js",
    "prettier.config.cjs",
    "prettier.config.mjs",
    "prettier.config.ts",
}


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


def parents(start: str):
    directory = os.path.abspath(start)
    while True:
        yield directory
        parent = os.path.dirname(directory)
        if parent == directory:
            break
        directory = parent


def has_named(directory: str, names: set[str]) -> bool:
    try:
        present = set(os.listdir(directory))
    except OSError:
        return False
    return bool(present & names)


def package_has_prettier(directory: str) -> bool:
    path = os.path.join(directory, "package.json")
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, json.JSONDecodeError):
        return False
    return isinstance(data, dict) and "prettier" in data


def find_bin(start: str, name: str) -> str:
    for directory in parents(start):
        candidate = os.path.join(directory, "node_modules", ".bin", name)
        if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate
    return shutil.which(name) or ""


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    path = path_from(payload)
    if os.path.splitext(path)[1] not in EXTENSIONS or not os.path.isfile(path):
        sys.exit(0)

    directory = os.path.dirname(os.path.abspath(path))
    biome_config = False
    prettier_config = False
    for parent in parents(directory):
        if not biome_config and has_named(parent, BIOME_CONFIGS):
            biome_config = True
        if not prettier_config and (
            has_named(parent, PRETTIER_CONFIGS) or package_has_prettier(parent)
        ):
            prettier_config = True
        if os.path.isfile(os.path.join(parent, "package.json")):
            break

    biome = find_bin(directory, "biome")
    prettier = find_bin(directory, "prettier")

    command: list[str] = []
    if biome_config and biome:
        command = [biome, "format", "--write", path]
    elif prettier_config and prettier:
        command = [prettier, "--write", path]
    elif biome and not prettier:
        command = [biome, "format", "--write", path]
    elif prettier and not biome:
        command = [prettier, "--write", path]

    if command:
        try:
            subprocess.run(command, check=False, timeout=8)
        except (OSError, subprocess.TimeoutExpired):
            sys.exit(0)
    sys.exit(0)


if __name__ == "__main__":
    main()
