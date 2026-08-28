#!/usr/bin/env bash
# Validate marketplace index, plugin manifests, SKILL.md files, agents, and hooks.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export ROOT

python3 - "$ROOT" <<'PY'
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1])
errors: list[str] = []
warnings: list[str] = []

NAME_RE = re.compile(r"^[a-z0-9](?:[a-z0-9-]{0,62}[a-z0-9])$")


def err(msg: str) -> None:
    errors.append(msg)


def warn(msg: str) -> None:
    warnings.append(msg)


def load_json(path: Path) -> object | None:
    try:
        with path.open(encoding="utf-8") as fh:
            return json.load(fh)
    except FileNotFoundError:
        err(f"missing {path.relative_to(ROOT)}")
        return None
    except json.JSONDecodeError as exc:
        err(f"invalid JSON {path.relative_to(ROOT)}: {exc}")
        return None


def parse_frontmatter(text: str) -> dict[str, str] | None:
    if not text.startswith("---"):
        return None
    parts = text.split("---", 2)
    if len(parts) < 3:
        return None
    fields: dict[str, str] = {}
    key: str | None = None
    chunks: list[str] = []
    multiline = False
    for raw_line in parts[1].splitlines():
        line = raw_line.rstrip("\n")
        if key and multiline:
            if line.strip() and not line.startswith((" ", "\t")) and ":" in line:
                fields[key] = "\n".join(chunks).strip()
                key, chunks, multiline = None, [], False
            else:
                chunks.append(line.strip())
                continue
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            continue
        name, value = line.split(":", 1)
        name = name.strip()
        value = value.strip()
        if value in ("|", ">", ">-", "|-"):
            key, chunks, multiline = name, [], True
            continue
        if (value.startswith('"') and value.endswith('"')) or (
            value.startswith("'") and value.endswith("'")
        ):
            value = value[1:-1]
        fields[name] = value
    if key:
        fields[key] = "\n".join(chunks).strip()
    return fields


def check_marketplace() -> list[str]:
    path = ROOT / ".grok-plugin" / "marketplace.json"
    data = load_json(path)
    if not isinstance(data, dict):
        return []
    if not data.get("name"):
        err("marketplace.json missing name")
    plugins = data.get("plugins")
    if not isinstance(plugins, list) or not plugins:
        err("marketplace.json has no plugins")
        return []
    names: list[str] = []
    for i, plugin in enumerate(plugins):
        if not isinstance(plugin, dict):
            err(f"marketplace.json plugins[{i}] is not an object")
            continue
        name = plugin.get("name")
        if not isinstance(name, str) or not NAME_RE.match(name):
            err(f"marketplace.json plugins[{i}] has invalid name {name!r}")
            continue
        names.append(name)
        source = plugin.get("source")
        rel = None
        if isinstance(source, str):
            rel = source
        elif isinstance(source, dict):
            rel = source.get("path")
        if not isinstance(rel, str):
            err(f"plugin {name}: missing local source.path")
            continue
        plugin_dir = (ROOT / rel).resolve()
        if not plugin_dir.is_dir():
            err(f"plugin {name}: source path does not exist: {rel}")
            continue
        if not (plugin_dir / "plugin.json").is_file():
            err(f"plugin {name}: missing plugin.json")
    dupes = {n for n in names if names.count(n) > 1}
    for name in sorted(dupes):
        err(f"marketplace.json duplicate plugin name: {name}")
    return names


def check_plugin_json(plugin_dir: Path, expected_name: str) -> None:
    data = load_json(plugin_dir / "plugin.json")
    if not isinstance(data, dict):
        return
    name = data.get("name")
    if name != expected_name:
        err(f"{plugin_dir.name}/plugin.json name {name!r} != {expected_name!r}")
    if not data.get("description"):
        err(f"{plugin_dir.name}/plugin.json missing description")


def check_skills(plugin_dir: Path) -> None:
    skills_root = plugin_dir / "skills"
    if not skills_root.is_dir():
        return
    for skill_md in sorted(skills_root.rglob("SKILL.md")):
        skill_dir = skill_md.parent
        rel = skill_md.relative_to(ROOT)
        text = skill_md.read_text(encoding="utf-8")
        fields = parse_frontmatter(text)
        if fields is None:
            err(f"{rel}: missing YAML frontmatter")
            continue
        name = fields.get("name", "").strip()
        desc = fields.get("description", "").strip()
        if not name:
            err(f"{rel}: frontmatter missing name")
        elif not NAME_RE.match(name):
            err(f"{rel}: invalid name {name!r}")
        elif name != skill_dir.name:
            err(f"{rel}: name {name!r} does not match directory {skill_dir.name!r}")
        if not desc:
            err(f"{rel}: frontmatter missing description")
        nested = [p for p in skill_dir.rglob("SKILL.md") if p != skill_md]
        for extra in nested:
            err(f"nested skill {extra.relative_to(ROOT)} inside {skill_dir.relative_to(ROOT)}")


def check_agents(plugin_dir: Path) -> None:
    agents_root = plugin_dir / "agents"
    if not agents_root.is_dir():
        return
    for agent_md in sorted(agents_root.glob("*.md")):
        rel = agent_md.relative_to(ROOT)
        text = agent_md.read_text(encoding="utf-8")
        fields = parse_frontmatter(text)
        if fields is None:
            err(f"{rel}: missing YAML frontmatter")
            continue
        name = fields.get("name", "").strip()
        desc = fields.get("description", "").strip()
        if not name:
            err(f"{rel}: frontmatter missing name")
        elif not NAME_RE.match(name):
            err(f"{rel}: invalid name {name!r}")
        elif name != agent_md.stem:
            err(f"{rel}: name {name!r} does not match filename stem {agent_md.stem!r}")
        if not desc:
            err(f"{rel}: frontmatter missing description")


def check_shell() -> None:
    shell = ROOT / "shell"
    if not shell.is_dir():
        err("missing shell/")
        return
    for rel in (
        "install.sh",
        "lib/clipboard.sh",
        "lib/how-query.sh",
        "zsh/init.zsh",
        "bash/init.bash",
    ):
        path = shell / rel
        if not path.is_file():
            err(f"missing {path.relative_to(ROOT)}")
    install = shell / "install.sh"
    if install.is_file() and not os.access(install, os.X_OK):
        warn("shell/install.sh is not executable")
    zsh_fns = shell / "zsh" / "functions"
    bash_fns = shell / "bash" / "functions"
    if zsh_fns.is_dir() and not any(zsh_fns.glob("*.zsh")):
        warn("shell/zsh/functions/ has no *.zsh files")
    if bash_fns.is_dir() and not any(bash_fns.glob("*.bash")):
        warn("shell/bash/functions/ has no *.bash files")


def check_hooks(plugin_dir: Path) -> None:
    hooks_json = plugin_dir / "hooks" / "hooks.json"
    if not hooks_json.is_file():
        return
    data = load_json(hooks_json)
    if not isinstance(data, dict):
        return
    groups = data.get("hooks")
    if not isinstance(groups, dict):
        err(f"{hooks_json.relative_to(ROOT)}: missing top-level hooks object")
        return
    for event, matchers in groups.items():
        if not isinstance(matchers, list):
            err(f"{hooks_json.relative_to(ROOT)}: {event} is not an array")
            continue
        for matcher in matchers:
            if not isinstance(matcher, dict):
                continue
            handlers = matcher.get("hooks")
            if not isinstance(handlers, list):
                err(f"{hooks_json.relative_to(ROOT)}: {event} entry missing hooks array")
                continue
            for handler in handlers:
                if not isinstance(handler, dict):
                    continue
                if handler.get("type") != "command":
                    continue
                command = handler.get("command")
                if not isinstance(command, str) or not command:
                    err(f"{hooks_json.relative_to(ROOT)}: {event} command missing")
                    continue
                if " " in command:
                    continue
                script = (hooks_json.parent / command).resolve()
                if not script.is_file():
                    err(f"{hooks_json.relative_to(ROOT)}: {event} script not found: {command}")
                    continue
                if not os.access(script, os.X_OK):
                    warn(f"{script.relative_to(ROOT)} is not executable")


def main() -> int:
    catalog_names = check_marketplace()
    plugin_root = ROOT / "plugins"
    if not plugin_root.is_dir():
        err("missing plugins/")
    else:
        on_disk = sorted(p.name for p in plugin_root.iterdir() if p.is_dir())
        for name in on_disk:
            if catalog_names and name not in catalog_names:
                err(f"plugins/{name} is not listed in marketplace.json")
            check_plugin_json(plugin_root / name, name)
            check_skills(plugin_root / name)
            check_agents(plugin_root / name)
            check_hooks(plugin_root / name)
        for name in catalog_names:
            if name not in on_disk:
                err(f"marketplace lists {name} but plugins/{name} is missing")

    check_shell()

    for msg in warnings:
        print(f"warning: {msg}")
    for msg in errors:
        print(f"error: {msg}")
    if errors:
        print(f"{len(errors)} error(s), {len(warnings)} warning(s)")
        return 1
    print(f"ok ({len(warnings)} warning(s))")
    return 0


sys.exit(main())
PY

status=$?

if command -v grok >/dev/null 2>&1; then
  for plugin in "$ROOT"/plugins/*; do
    [ -d "$plugin" ] || continue
    echo "grok plugin validate ${plugin##*/}"
    if ! grok plugin validate "$plugin"; then
      echo "error: grok plugin validate failed for ${plugin##*/}" >&2
      status=1
    fi
  done
else
  echo "warning: grok not on PATH; skipped grok plugin validate"
fi

exit "$status"
