# ai

Language-neutral planning and gated implementation. File-level Go and TypeScript plans stay in the `go` and `typescript` plugins.

| Skill | Role |
|---|---|
| `stage-plan` | Gaps, clarifying questions, then `plans/staged-plan.md` |
| `implement-task` | One task, in the language and approach named at kickoff, until feature-review and qa-review both APPROVE |

`/go-detail-plan` and `/typescript-detail-plan` read the stage map and plan one stage. `/go-implement-stage` and `/typescript-implement-stage` remain the language-specific loops.

## Agents

Spawned by `/implement-task`. Always use the qualified types so they do not collide with `go` or `typescript`: `ai:implementer`, `ai:feature-review`, `ai:qa-review`.

| Agent | Role |
|---|---|
| `implementer` | Implement the task in an isolated worktree on `impl/<task-stem>` |
| `feature-review` | Task compliance only |
| `qa-review` | Correctness, tests, and the language and approach from kickoff |

Schema files live with `implement-task` (`skills/implement-task/references/`). Run state goes in the consuming repo at `.grok/implement-task/progress/`.
