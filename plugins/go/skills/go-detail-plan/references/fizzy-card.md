# S<stage>.<k> — <step name>

**Stage:** <N or slug> — <title>
**Plan:** `<plans/stage-N.md>`
**Story:** <k> of <total> (strict order)
**Execute:** only when every **Depends on** card is In-progress, Ready For PR, or closed — not Maybe or Not Now. If a dependency is still unblocked-but-not-started, stop. Do not implement this card. Do not ask the user to waive the dependency.

**Start:** take this card — self-assign if not already assigned (`self-assign` toggles), then `fizzy card column <number> --column <In-progress id>`. Implement only after it is In-progress.

## Depends on

| Card | Why |
|---|---|
| #<number> `S<stage>.<k> — <title>` | what that story must have left in the tree before this one starts |

None if this is the first story. List every earlier story in this stage, not only the previous one.

## Blocks

- #<number> `S<stage>.<k+1> — <title>` — when this step is done, `fizzy card column <number> --column maybe`

None if this is the last story.

## Decisions (locked)

Do not reopen. Do not ask the user. Implement these:

| Decision | Choice |
|---|---|
| <name> | <locked value this step needs> |

## Implement

- **Files:** `path` (create|modify) — what belongs there
- **Types / funcs:** exported signatures only (unexported if this story needs them)
- **Behavior:** what those symbols do, including errors
- **Notes:** `cmd/` vs `internal/`, interface at consumer

## Tests this story owns

| ID | Kind | Package | Name | Setup | Input | Want | WantErr |
|---|---|---|---|---|---|---|---|
| U1 | unit | `internal/pkg` | `sentence name` | … | … | … | false |

- **False-positive guards:** what would make each test still pass if this story's behavior were missing.

## Done when

- [ ] files and signatures above exist
- [ ] tests above exist and pass (`//go:build integration` where Kind is integration)
- [ ] no Out of scope item was implemented

## Out of scope

Later-stage work and user deferrals. Do not implement.

## When this step is done

For each **Blocks** card: `fizzy card column <number> --column maybe`. Leave this card In-progress.
