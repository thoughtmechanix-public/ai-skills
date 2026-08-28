# go

Idiomatic Go skills, copied from `~/.grok/skills/`. Several files still mention Gopher Guides API helpers (`.github/skills/scripts/`, `../references/api-usage.md`); those paths are not in this plugin.

## Skills

| Skill | Role |
|---|---|
| `go` | Hub: interfaces, errors, concurrency, testing, organization, debugging |
| `go-code-audit` | Whole-project quality audit |
| `go-code-review` | First-pass PR / diff review |
| `go-lint-audit` | golangci-lint with explanations |
| `go-standards-audit` | Docs, concurrency, deps, layout |
| `go-test-coverage` | Coverage gaps and table-driven stubs |
| `new-go-cli` | Scaffold a Cobra/Viper CLI (`disable-model-invocation`) |
| `new-go-service` | Scaffold a stdlib HTTP service (`disable-model-invocation`) |
| `detail-plan` | Turn a stage of work into `plans/stage-<N>.md` |
| `implement-stage` | Orchestrate implementer → feature/code/test review until all three APPROVE |

`/implement-stage` schema files live with the skill (`skills/implement-stage/references/`), not in the consuming repo. Run state still goes in the workspace at `.grok/implement-stage/progress/`.

## Agents

Spawned by `/implement-stage`. Types: `implementer`, `feature-review`, `code-review`, `test-review` (qualified `go:<name>` if the catalog requires it).

| Agent | Role |
|---|---|
| `implementer` | Write the plan in Go using the `go` skill; keep the progress file current |
| `feature-review` | Plan compliance only |
| `code-review` | Diff against `go`, `go-code-review`, `go-lint-audit` |
| `test-review` | Plan-named tests, false positives, 80% coverage on touched packages |

## Hooks

`PostToolUse` on file-edit tools runs `gofmt -w` for existing `*.go` files. Missing `gofmt` is ignored (fail-open).
