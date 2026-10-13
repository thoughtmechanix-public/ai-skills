---
name: new-typescript-cli
description: >
  Scaffold a new TypeScript CLI: ESM, strict tsc, Commander, cosmiconfig
  (JSON, YAML, TOML) under flags and env, JSON logs, unit and integration
  tests, --ai-help JSON on every command, and the greenfield lint setup.
  Use when the user wants a new TypeScript CLI or runs /new-typescript-cli.
disable-model-invocation: true
---

Scaffold a new TypeScript CLI. Ask for the package name and the commands it should expose if they were not given. Finish each step before the next. Do not proceed while the current step is red.

Compiler flags: the greenfield `tsconfig` in `../typescript/organization.md`. Lint, Prettier, and scripts: the greenfield section of `../../shared/toolchain.md`. Test style: `../typescript/testing.md`. Errors and logs: `../typescript/errors.md`.

## Layout

1. `mkdir -p <name> && cd <name>`. Every later command runs there.
2. Create:
   - `src/cli.ts` — build the Commander program, parse `process.argv`, exit. No business rules.
   - `src/commands/<command>.ts` — one module per command. Each exports a function that receives the program and registers its command.
   - `src/config.ts` — load and validate config.
   - `src/logging.ts` — JSON log lines on stderr.
   - `src/ai-help.ts` — build the `--ai-help` payloads.
   - `src/<domain>.ts` — pure behavior commands call. No Commander types in this file.
3. `package.json`: `"type": "module"`, `"engines": { "node": ">=22" }`, `"bin"` pointing at `dist/cli.js`. Dependencies: `commander`, `cosmiconfig`, `js-yaml`, `smol-toml`. Dev dependencies and scripts from `toolchain.md`, plus `@types/js-yaml`.

## Stack

4. Commander for every command. Register each `src/commands/*` module from `src/cli.ts`. Do not put two unrelated commands in one file.
5. Config precedence is **flags > environment > config file > defaults**. Environment prefix: the package name in uppercase with non-alphanumerics turned into `_` (document the map). Search, in order: `./.<name>.yaml`, `./.<name>.yml`, `./.<name>.toml`, `./.<name>.json`, `$XDG_CONFIG_HOME/<name>/config.yaml`, and the home-directory equivalent. Load YAML with `js-yaml` and TOML with `smol-toml` through cosmiconfig. After load, parse into a typed object (a guard or parser in `src/config.ts`). Fail with a `ConfigError` (`errors.md`) when a required value is still missing.
6. Logs are one JSON object per line on **stderr** (`level`, `time`, `msg`). No `console.log` for operational messages. Stdout is for command results only. Log level comes from config / `--log-level`.
7. Command modules stay thin: bind flags, load config, call `src/<domain>.ts`, write stdout, set the exit code.

## --ai-help

8. Every command, including the root, has `--ai-help` (boolean, default false).
9. When it is set, do no other work. Write one JSON document to stdout and exit 0. No log lines on stdout.
10. Root JSON includes `name`, `description`, `version`, `commands` (name, brief, usage, `examples`, `flags`), and `config` (env, YAML, TOML, JSON, flags, with examples).
11. Subcommand JSON includes purpose, flags, config keys, side effects, exit codes, and `examples`. Build both in `src/ai-help.ts` so the shape stays one type.

## Tests

12. Unit tests in `src/*.test.ts` for config precedence, the domain function's success and failure, and the ai-help object. Table shape from `testing.md`.
13. `src/cli.integration.test.ts` runs the program in-process (Commander `parseAsync` with `exitOverride`, or `node --experimental-strip-types src/cli.ts` via `node:child_process`). Cover `--help`, each command's success and failure, env and flag precedence, and `--ai-help` (parse the JSON and assert the required fields).

## Gates

14. `pnpm install` or the manager from `toolchain.md` (npm when the directory has no lockfile yet).
15. Run `typecheck`, `lint`, `test`, `test:integration`, and `build`. Fix and re-run until all pass.
16. Run the built `dist/cli.js` with `--help` and `--ai-help`. Confirm the JSON parses. Run one real subcommand.

## Defaults

- If no commands were named, add `version` (print the version) so config, logging, and `--ai-help` have a real command.
- Binary name equals the package name.
