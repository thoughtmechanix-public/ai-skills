# shell

Interactive zsh/bash functions and PATH helpers. These are for you, not for Grok agents. Do not put them under `plugins/` or `scripts/`.

## Layout

```
shell/
  install.sh              source inits from ~/.zshrc and ~/.bashrc
  lib/                    shared helpers sourced by both shells
  zsh/init.zsh            loads lib + zsh/functions/*.zsh
  zsh/functions/          one file per zsh function
  bash/init.bash          loads lib + bash/functions/*.bash
  bash/functions/         one file per bash function
  bin/                    executables; install.sh prepends this to PATH
```

| You are adding | Put it here |
|---|---|
| A zsh function | `zsh/functions/<name>.zsh` |
| A bash function | `bash/functions/<name>.bash` |
| Logic both shells share | `lib/<name>.sh` |
| An executable on PATH | `bin/<name>` (then `chmod +x`) |

Zsh init files are sourced automatically once they match `zsh/functions/*.zsh`. Same for bash and `*.bash`. Re-run `./shell/install.sh` only if you moved the checkout or want a different rc file.

## Install

From the repo root:

```bash
./shell/install.sh
```

That appends a managed block (idempotent) to `~/.zshrc` and/or `~/.bashrc` for every shell on `PATH`. Options:

```bash
./shell/install.sh --zsh
./shell/install.sh --bash
./shell/install.sh --uninstall
```

The block sources this checkout. If you move the repo, run install again.

## Commands

| Command | Shells | What it does |
|---|---|---|
| `how <request>` | zsh, bash | Ask grok for a single shell command, copy it, and (zsh) drop it on the command line |

Clipboard: `wl-copy` (Wayland), then `xclip` / `xsel` (X11), then `pbcopy` (macOS). If none are present, the command is still printed.

Zsh uses `noglob` and bash uses `set -f` on the alias, so `how find *.go files` is safe in both.

Requires `grok` on `PATH`.
