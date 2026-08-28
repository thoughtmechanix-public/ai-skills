# Stage <N> — <title>

- **Stage map:** <path, or none>
- **Spec:** <path, or none>
- **Go skills loaded:** <skill names>
- **Execute with:** `/implement-stage plans/stage-<N>.md`
- **Status:** not implemented

## Decisions

Locked for this stage (user answers + already-locked map/spec). Each row is a fact the implementer must not reopen.

| Decision | Choice | Source |
|---|---|---|
| language | Go | stage map or interrogation |
| <open item> | <user choice> | interrogation |

## Out of scope

Later work from the stage map plus anything the user deferred. Implementing these is a feature-review miss.

## Dependencies and blockers

### Must already be true (prior stages)

- Previous stage **Done when:** <one line>. If the tree does not satisfy this, the implementer stops. Omit this subsection for the first stage.

### This stage depends on

- Packages, files, config keys, or interfaces from earlier work (path + why).
- External tools (gofmt, golangci-lint, and any libraries the repo already uses) — name the import or binary.

### Blockers

- Anything that would make the stage undeliverable (missing decision, missing prior deliverable, circular import). Empty list means none.

## Implementation steps

Ordered. Each step is one implementer checkpoint (progress file: one unit).

### Step 1 — <name>

- **Files:** `path` (create|modify) — what belongs there
- **Types / funcs:** exported signatures only (unexported if the plan needs them)
- **Notes:** `cmd/` vs `internal/`, interface at consumer

Repeat. Do not include later-stage types. Do not dump full function bodies; signatures and behavior are enough for the implementer plus the go skill.

## Test cases

Every **Done when** / **Delivers** item maps to at least one case. Unit vs `//go:build integration` is explicit. Names are sentences.

| ID | Kind | Package | Name | Setup | Input | Want | WantErr |
|---|---|---|---|---|---|---|---|
| U1 | unit | `internal/config` | `loads YAML file then flag overrides timeout` | temp YAML `timeout: 20s` | flag `--timeout=5s` | config.Timeout==5s | false |
| I1 | integration | `cmd/app` | `root --help exits 0 and prints usage` | built root command | `--help` | usage mentions root | false |

Also list:

- **False-positive guards:** what would make each test still pass if the feature were broken — the implementer must not write that test.
- **Coverage target:** 80% of packages this stage adds or changes; every new exported symbol has a test.

## Done when (this plan)

Restate the stage **Done when** as a checklist the feature-review gate can tick against files and tests above.
