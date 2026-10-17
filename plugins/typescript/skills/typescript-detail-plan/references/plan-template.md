# Stage <N> — <title>

- **Stage map:** <path, or none>
- **Spec:** <path, or none>
- **TypeScript skills loaded:** <skill names>
- **Execute with:** `/typescript-implement-stage plans/stage-<N>.md`
- **Status:** not implemented

## Decisions

Locked for this stage (user answers + already-locked map/spec). Each row is a fact the implementer must not reopen.

| Decision | Choice | Source |
|---|---|---|
| language | TypeScript | stage map or interrogation |
| <open item> | <user choice> | interrogation |

## Out of scope

Later work from the stage map plus anything the user deferred. Implementing these is a feature-review miss.

## Dependencies and blockers

### Must already be true (prior stages)

- Previous stage **Done when:** <one line>. If the tree does not satisfy this, the implementer stops. Omit this subsection for the first stage.

### This stage depends on

- Modules, files, config keys, or exported types from earlier work (path + why).
- Tools this repo already runs. Name the package manager, `tsc` invocation, linter, and test command the planner resolved. Do not tell the implementer to pick a new runner.

### Blockers

- Anything that would make the stage undeliverable (missing decision, missing prior deliverable, an import cycle). Empty list means none.

## Implementation steps

Ordered. Each step is one implementer checkpoint (progress file: one unit).

### Step 1 — <name>

- **Files:** `path` (create|modify) — what belongs there
- **Exports:** signatures only
- **Notes:** entry file stays wiring; domain module owns the behavior; public types follow `typescript` / `types.md`

Repeat. Do not include later-stage types. Do not dump full function bodies. Signatures and behavior are enough for the implementer plus the `typescript` skill.

## Test cases

Every **Done when** / **Delivers** item maps to at least one case. Unit vs integration is explicit (`*.test.ts` vs `*.integration.test.ts`). Names are sentences.

| ID | Kind | File | Name | Setup | Input | Want | WantErr |
|---|---|---|---|---|---|---|---|
| U1 | unit | `src/config.test.ts` | `uses the flag when the file also sets a timeout` | temp file `timeout: 20` | flag `5` | `timeoutSeconds === 5` | false |
| I1 | integration | `src/cli.integration.test.ts` | `root --help exits 0 and prints usage` | built entry | `--help` | usage mentions the root command | false |

Also list:

- **False-positive guards:** what would make each test still pass if the feature were broken. The implementer must not write that test.
- **Coverage target:** 80% statements on each package this stage adds or changes. Do not average packages together. Every new export has a test.

## Done when (this plan)

Restate the stage **Done when** as a checklist the feature-review gate can tick against the files and tests above.

## Fizzy stories

Board: Grok Developer. One card per implementation step. Each card's **Depends on** / **Blocks** is the order.

| Step | Card | Title | Depends on | Lane |
|---|---|---|---|---|

After you accept this file, run `/typescript-implement-stage plans/stage-<N>.md`.
