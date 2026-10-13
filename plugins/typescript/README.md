# typescript

TypeScript counterpart of the `go` plugin. Idioms live in the `typescript` skill. Commands, coverage, and greenfield lint scripts live in `shared/toolchain.md`. Compiler flags for a new package live in `skills/typescript/organization.md`.

## Skills

| Skill | Role |
|---|---|
| `typescript` | Hub: types, errors, async, testing, layout, debugging |
| `typescript-code-audit` | Whole-project quality audit |
| `typescript-code-review` | First-pass PR / diff review |
| `typescript-lint-audit` | Typecheck and ESLint or Biome, with explanations |
| `typescript-standards-audit` | Docs, `tsconfig`, dependencies, layout |
| `typescript-test-coverage` | Coverage gaps and table-driven stubs |
| `new-typescript-cli` | Scaffold an ESM Commander CLI (`disable-model-invocation`) |
| `new-typescript-service` | Scaffold a `node:http` service (`disable-model-invocation`) |
| `typescript-detail-plan` | Turn a stage into `plans/stage-<N>.md`, then one Fizzy card per step |
| `typescript-implement-stage` | Orchestrate implementer → feature/code/test review until all three APPROVE, then commit, open a GitHub PR, and update Fizzy |

`/typescript-implement-stage` schema files live with the skill (`skills/typescript-implement-stage/references/`). Run state still goes in the consuming repo at `.grok/typescript-implement-stage/progress/`.

## Agents

Spawned by `/typescript-implement-stage`. Prefer the qualified types so they do not collide with the `go` plugin: `typescript:implementer`, `typescript:feature-review`, `typescript:code-review`, `typescript:test-review`.

| Agent | Role |
|---|---|
| `implementer` | Write the plan in TypeScript in an isolated worktree on `impl/<plan-stem>` |
| `feature-review` | Plan compliance only |
| `code-review` | Diff against `typescript`, `typescript-code-review`, `typescript-lint-audit` |
| `test-review` | Plan-named tests, false positives, 80% statements on touched packages |

## Hooks

`PostToolUse` on file-edit tools formats an existing `.ts`, `.tsx`, `.mts`, or `.cts` file with Biome or Prettier when that tool is already installed. Missing tools are ignored (fail-open).
