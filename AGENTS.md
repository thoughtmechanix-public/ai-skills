# Agent notes

This repository is a Grok plugin marketplace. Skills, hooks, and scripts live here so they can be versioned and loaded by Grok.

## Where new files go

| You are adding | Put it here |
|---|---|
| A skill | `plugins/<domain>/skills/<name>/SKILL.md` |
| Extra context for one skill | same directory (`references/`, sibling `.md`) |
| A helper the agent should run | `plugins/<domain>/skills/<name>/scripts/` |
| A subagent definition | `plugins/<domain>/agents/<name>.md` (frontmatter `name` matches the filename stem) |
| A Grok lifecycle hook | `plugins/<domain>/hooks/hooks.json` + `plugins/<domain>/hooks/bin/` |
| Shared notes for several skills in one plugin | `plugins/<domain>/shared/` (never under `skills/`) |
| Install/validate tooling | `scripts/` |
| A zsh/bash function for you to run | `shell/zsh/functions/<name>.zsh` or `shell/bash/functions/<name>.bash` |
| Shared logic for those functions | `shell/lib/` |
| A user-facing executable on PATH | `shell/bin/` |

Domains: `core` (hooks that apply to every session), `ai`, `go`, `git`.

## Skill rules

- One skill per directory. The directory name is the skill name (kebab-case, 2–64 characters, start and end with a letter or digit).
- `SKILL.md` frontmatter must include `name` (identical to the directory) and `description` (what it does and when to invoke it).
- Do not nest a `SKILL.md` inside another skill. Go skills are siblings under `plugins/go/skills/`, even when one is a hub skill with topic files.
- Keep `SKILL.md` as the procedure. Put deep reference material in `references/` and point at it.
- Prefer existing CLIs over new helper scripts. If a script is required, keep it inside that skill.

## Agent rules

- One agent per `plugins/<domain>/agents/<name>.md`. Frontmatter `name` must match the filename stem.
- Keep an agent with the skill that spawns it. `/go-implement-stage` and its four gates (`implementer`, `feature-review`, `code-review`, `test-review`) live together in `go`.
- Refer to other skills by **name** (`go`, `go-code-review`), not `~/.grok/skills/` or a consuming repo's `.grok/`.
- Schema files the agent must follow live in the skill's `references/`. The orchestrator passes those absolute paths in the spawn prompt. Do not assume they exist under the workspace `.grok/`.
- Plugin spawn type is the agent name; if the catalog only lists a qualified form, use `<plugin>:<name>`.

## Hook rules

- `hooks/hooks.json` is the only hook manifest Grok loads from a plugin.
- `command` paths are relative to that JSON file. Use `bin/<handler>`.
- Put a hook in `core` when it should run in every session. Put it on `ai`, `go`, or `git` only when it is meaningless outside that domain.
- Blocking `PreToolUse` handlers must emit `{"decision":"deny","reason":"..."}` and exit 2. Any crash or malformed output fails open.
- Keep handlers fast. Default timeout is 5 seconds (600s for `Stop` / `SubagentStop`).

## Do not

- Put hook binaries in `skills/*/scripts/` or skill helpers in `hooks/bin/`.
- Put interactive zsh/bash helpers under `plugins/`, or Grok plugin helpers under `shell/`.
- Add empty `commands/`, `.mcp.json`, or `docs/` directories. Add `agents/` only when you have a `.md` definition.
- Duplicate a fact across skills. Point at the file that owns it.
- Copy third-party skills (`hey`, `omarchy`, bundled Grok skills) into this repo.

## After editing

Run `./scripts/validate.sh` from the repo root. If hook or skill scripts were added, `chmod +x` them (or re-run `./scripts/install.sh`). If a shell function or `shell/bin` executable was added, `chmod +x` it and run `./shell/install.sh` only when the checkout moved or an rc file needs the managed block.
