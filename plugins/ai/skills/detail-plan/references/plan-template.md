# Stage <N> — <title>

- **Stage map:** `staged-plan.md` (do not restate it; this file is the implementation plan)
- **Spec:** `plan.md`
- **Go skills loaded:** <paths from the stage's Go skills line>
- **Execute with:** `/implement-stage plans/stage-<N>.md`
- **Status:** not implemented

## Decisions

Locked for this stage (user answers + already-locked map/spec). Each row is a fact the implementer must not reopen.

| Decision | Choice | Source |
|---|---|---|
| language | Go | staged-plan.md |
| <open item> | <user choice> | interrogation |

## Out of scope

Copied from the stage's **Explicitly later** plus anything the user deferred. Implementing these is a feature-review miss.

## Dependencies and blockers

### Must already be true (prior stages)

- Stage <N-1> **Done when:** <one line>. If the tree does not satisfy this, the implementer stops.

### This stage depends on

- Packages, files, config keys, or interfaces from earlier stages (path + why).
- External tools (gofmt, golangci-lint, Cobra, Viper) — name the import or   runs /implement-stage, says "implement this stage", or hands a detailed plan
  to implement. The implementer cannot finish without all three gates APPROVE.
---

You are the orchestrator for Charon stage implementation. You coordinate only. You do **not** implement Go source, fix review items, or author gate verdicts. The only repo writes you make are progress/Orchestrator fields, mbinary.

### Blockers

- Anything that would make the stage undeliverable (missing decision, missing prior deliverable, circular import). Empty list means none.

## Implementation steps

Ordered. Each step is one implementer checkpoint (progress file: one unit).

### Step 1 — <name>

- **Files:** `path` (create|modify) — what belongs there
- **Types / funcs:** exported signatures only (unexported if the plan needs them)
- **Notes:** layer (User I/O / harness / adapter / tools), Cobra vs `internal/`, interface at consumer

Repeat. Do not include later-stage types. Do not dump full function bodies; signatures and behavior are enough for the implementer plus the go skill.

## Test cases

Every **Done when** / **Delivers** item maps to at least one case. Unit vs `//go:build integration` is explicit. Names are sentences.

| ID | Kind | Package | Name | Setup | Input | Want | WantErr |
|---|---|---|---|---|---|---|---|
| U1 | unit | `internal/config` | `loads YAML file then flag overrides max-steps` | temp YAML `max_steps: 20` | flag `--max-steps=5` | config.MaxSteps==5 | false |
| I1 | integration | `cmd/charon` | `charon --help exits 0 and prints usage` | built root command | `--help` | usage mentions root | false |

Also list:

- **False-positive guards:** what would make each test still pass if the feature were broken — the implementer must not write that test.
- **Coverage target:** 80% of packages this stage adds or changes; every new exported symbol has a test.

## Done when (this plan)

Restate the stage **Done when** as a checklist the feature-review gate can tick against files and tests above.
