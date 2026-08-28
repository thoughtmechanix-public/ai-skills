---
name: new-go-cli
description: >
  Scaffold a new Go CLI using Cobra + Viper with cmd/internal layout,
  multi-source config (env, YAML/TOML, flags), slog logging, unit and
  integration tests, --ai-help JSON docs on every command, and a Makefile
  for tools/build/test/install. Use when the user wants a new Go CLI,
  cobra/viper scaffolding, or runs /new-go-cli. Prefer explicit
  invocation; use only when clearly asked to scaffold a CLI.
disable-model-invocation: true
allowed-tools: Bash(go *) Bash(mkdir *) Bash(curl *)
---

Scaffold a new Go CLI. Ask for the CLI name (binary/module name) and the
initial commands it should expose if they were not given, then follow these
steps in order. Do not proceed to the next step until the current step is
complete.

## Layout

1. Create the project root and work inside it for every later step:
   `mkdir -p <name> && cd <name>`. Every command below runs from there.
2. Create this structure (adapt command names to what the user requested):
   - `cmd/<name>/main.go` — entrypoint only (wires root Cobra command and exits).
   - `cmd/<command>/` — **one package per CLI command** (or subcommand group).
     Each command package owns its `cobra.Command`, flags, and RunE.
   - `internal/config/` — Viper setup, config structs, load helpers.
   - `internal/logging/` — slog setup (JSON handler, level from config).
   - `internal/<domain>/` — pure business/support logic used by commands
     (no Cobra types here when practical).
   - `internal/aihelp/` — shared helpers that emit structured `--ai-help` JSON.
3. Initialize the module with `go mod init <name>` (or a full module path if
   the user gave one). Run `go get` for Cobra and Viper, then `go mod tidy`.

## Stack and idioms

4. **Cobra for all commands.** Root command in `cmd/<name>/` (or
   `cmd/root/` if clearer); every user-facing command lives under `cmd/`
   as its own package and is registered onto the root. Do not put multiple
   unrelated commands in a single file.
5. **Viper for configuration.** Support all of:
   - Flags (Cobra flags bound into Viper)
   - Environment variables (use a consistent prefix derived from `<name>`,
     e.g. `TODOCLI_`; document the mapping)
   - Config files: **YAML and TOML** (search well-known paths such as
     `./.<name>.yaml`, `./.<name>.toml`, `$XDG_CONFIG_HOME/<name>/config.yaml`,
     and the home-config equivalents)
   Precedence must be: **flags > environment > config file > defaults**.
   Fail fast with a clear error when a required value is missing after load.
6. **Logging with `log/slog`.** Default to JSON on stdout/stderr as
   appropriate. No `fmt.Println` for operational output and no `log.Fatal`
   outside `main`. Wire log level from config/flags (e.g. `--log-level`).
7. Keep support logic in `internal/`. Commands in `cmd/` should be thin:
   parse/bind flags, load config, call `internal/` packages, format output.
8. Prefer structured errors; exit non-zero on failure from `main` after
   logging or printing a concise user-facing error.

## --ai-help (required on every command)

9. Every Cobra command (root and all subcommands) must define a persistent
   or local `--ai-help` boolean flag (default false).
10. When `--ai-help` is set, the command must **not** run its normal work.
    It must print **only valid JSON** to stdout and exit 0.
11. **Root command `--ai-help` JSON** must describe the whole CLI, including
    at least:
    - `name`, `description`, `version` (if available)
    - `commands`: array of every subcommand with `name`, `brief`, `usage`,
      `examples` (string array of realistic invocations), and `flags`
      (name, type/default, description)
    - `config`: how to configure via env, YAML, TOML, and flags, with
      examples
12. **Subcommand `--ai-help` JSON** must describe that command in depth:
    purpose, flags, config keys it reads, side effects, exit codes, and
    `examples`. Reuse `internal/aihelp` for encoding so the shape stays
    consistent.
13. Always set output suitable for machines: JSON only, no log lines mixed
    into stdout when `--ai-help` is active (send logs to stderr if needed).

## Tests

14. Write **unit tests** for `internal/` packages (table-driven, subtests with
    descriptive names). Cover success and failure paths, including config
    loading and ai-help payload builders.
15. Write **integration tests** for the CLI:
    - Build or invoke the root command via Cobra (`Execute` / `SetArgs`)
      without requiring a full binary install when possible.
    - Cover: help, each command happy path, error path, config from flags
      and env (and file when practical), and `--ai-help` JSON validity
      (unmarshal and assert required fields).
16. Prefer `testing` + stdlib; add `github.com/stretchr/testify` only if it
    clearly improves assertions.

## Makefile (required targets)

17. Add a `Makefile` with at least:
    - `tools` — install/ensure developer tools (e.g. `golangci-lint`, any
      generators used). Idempotent where possible.
    - `build` — build the binary (e.g. into `bin/<name>`).
    - `test` — `go test ./...` with race detector when appropriate
      (`go test -race ./...`).
    - `vet` — `go vet ./...`.
    - `lint` — run linters (depends on `tools` if needed).
    - `install` — install the binary to `GOBIN`/`GOPATH/bin` or a
      documented prefix.
    - `all` or default goal that runs tools (if needed), vet, test, build.
18. Document targets briefly at the top of the Makefile.

## Gates

19. Run `make tools` (if tools are required for lint), then `make vet`,
    `make test`, and `make build`. If any fail, fix and re-run until clean.
20. Smoke-check: run the built binary with `--help` and with `--ai-help`,
    confirm JSON from `--ai-help` parses, then exercise at least one real
    subcommand.

## Defaults when the user is vague

- If no commands are specified, scaffold root + one example command
  (e.g. `version` or `hello`) that demonstrates config, slog, and
  `--ai-help`.
- Binary name defaults to the module/base name.
- Config env prefix: uppercase binary name with non-alnum → `_`.
