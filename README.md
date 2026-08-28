# personal-skills

A Grok plugin marketplace of personal skills, hooks, and scripts for AI work, Go, and git.

This repo is meant to be the source of truth for those files. Point Grok at the checkout and edit here; do not treat `~/.grok/skills/` as the canonical copy.

## Layout

```
.grok-plugin/marketplace.json   catalog Grok reads
plugins/
  core/                         session-wide hooks (no domain skills)
  ai/                           reserved for AI-generic skills (none yet)
  go/                           Go skills, go-detail-plan, go-implement-stage, review agents, gofmt-after-edit
  git/                          git skills, plus force-push guard
scripts/
  install.sh                    register this checkout with Grok
  validate.sh                   check manifests, skills, hooks, and shell layout
shell/
  zsh/ bash/ lib/ bin/          interactive shell helpers (you, not Grok)
```

Each plugin is a Grok plugin: `plugin.json`, optional `skills/<name>/SKILL.md`, optional `agents/<name>.md`, optional `hooks/hooks.json`.

**Four kinds of scripts, four places:**

| Kind | Location | Who runs it |
|---|---|---|
| Skill helper | `plugins/<domain>/skills/<name>/scripts/` | The agent, while following that skill |
| Hook handler | `plugins/<domain>/hooks/bin/` | Grok, on a lifecycle event |
| Repo tooling | `scripts/` | You or CI |
| Interactive shell | `shell/zsh/`, `shell/bash/`, `shell/bin/` | You, in zsh or bash |

Do not mix them. See [shell/README.md](shell/README.md) for functions such as `how`.

## Install

From this directory:

```bash
./scripts/install.sh
```

That makes hook handlers executable, adds this folder as a local marketplace, and installs the four plugins with trust enabled so hooks can run.

To attach the live checkout instead of an installed snapshot (better while you are still adding skills):

```bash
./scripts/install.sh --paths
```

That appends the plugin directories to `[plugins].paths` in `~/.grok/config.toml` (or `$GROK_HOME/config.toml`). Restart Grok or press `r` in the Plugins tab.

Interactive zsh/bash helpers are separate:

```bash
./shell/install.sh
```

That sources this checkout from `~/.zshrc` and/or `~/.bashrc` and puts `shell/bin` on `PATH`. Details: [shell/README.md](shell/README.md).

Enable only the domains you want:

```toml
[plugins]
enabled = ["core", "go"]
```

## Validate

```bash
./scripts/validate.sh
```

Requires `python3`. Uses `grok plugin validate` when `grok` is on `PATH`.

## Plugins

| Plugin | Status | Contents |
|---|---|---|
| `core` | ready | `SessionStart` log, destructive-command deny, tool-use log |
| `go` | ready | Hub skill plus audits, coverage, CLI/service scaffolding; `go-detail-plan`, `go-implement-stage`, and review agents; `gofmt` after `.go` edits |
| `ai` | empty | Reserved for AI-generic skills. Go planning and implementation live in `go`. |
| `git` | ready | `/git-commit`, `/git-prepare-pr`; blocks `git push --force` / `-f` to `main` or `master` |

Go skills were copied from `~/.grok/skills/` (the Gopher Guides–derived set). Some of those files still mention `.github/skills/scripts/` and a Gopher Guides API; those helpers are not in this repo.

`go-detail-plan`, `go-implement-stage`, and the four review agents live in the `go` plugin. Schema files travel with `go-implement-stage`; per-run progress still belongs in the consuming repo under `.grok/go-implement-stage/progress/`.

## Adding content

See [AGENTS.md](AGENTS.md) for the rules an agent should follow when adding a skill or hook. Short version:

1. Create `plugins/<domain>/skills/<name>/SKILL.md` with `name` matching the directory.
2. Put spawned agents in `plugins/<domain>/agents/<name>.md`.
3. Put agent-run helpers in that skill's `scripts/` directory.
4. Put lifecycle hooks in that plugin's `hooks/hooks.json` and `hooks/bin/`.
5. Run `./scripts/validate.sh`.
