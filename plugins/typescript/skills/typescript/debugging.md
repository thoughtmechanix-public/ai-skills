# TypeScript — Systematic debugging

Loaded by `SKILL.md` when the user is investigating a bug, a failing test, a type error that appeared without an intentional type change, or a hung process.

No fix before a root cause. Do not change a line to see if the error moves.

## Modes

**Coding.** Follow the four phases below.

**Review.** A bug-fix diff needs a test that failed before the fix, or a written reproduction command in the summary. A fix that only changes an assertion is a failed investigation.

**Audit.** Up to three sub-agents: empty catches (`errors.md`); floating promises (`async.md`); `as` casts on values that cross a process boundary (`types.md`).

## Phase 1 — Reproduce

1. Read the full error, stack, and the command that produced it.
2. Reproduce with one command. A unit test is the usual form. Run it once and keep the output.
3. Check recent changes: `git log --oneline -20` and `git blame` on the throwing line.
4. Trace backward from the throw or the bad value. At each call, record what was passed.
5. Typecheck (`../../shared/toolchain.md`) before concluding the bug is at runtime. A red `tsc` can be the whole defect.

Do not edit production code in this phase. A log line at a boundary is allowed when you cannot see the value any other way. Remove it before the fix is done, or replace it with a test.

Stop here until you can state the steps and you have a failing command.

## Phase 2 — Compare

Find a similar path in the repo that works. List every difference, not only the obvious one. Note what the broken path assumes about input, order, or config.

## Phase 3 — One hypothesis

Write one sentence: "This fails because X passes Y to Z, and Z requires W."

Change one thing that tests that sentence. If the result refutes it, return to phase 1 with the new fact.

After three failed fixes, stop. Report what you know, what you tried, and whether the design is wrong. Ask before a fourth attempt.

## Phase 4 — Fix

1. Confirm the phase 1 test still fails.
2. Change the cause, not the symptom. Do not widen a type to `any` or add `!` to make the error disappear.
3. Re-run that test, then the package tests and typecheck from `toolchain.md`.
4. Keep the regression test.

## Hung processes and flakes

- A promise nobody awaits looks like a hang only after the process should have exited. Start with phase 1 and the floating-promise rules in `async.md`.
- Do not add `setTimeout` to a test to make it pass. `testing.md` owns how to wait.
- An error that happens only under `Promise.all` is still a single-cause bug. Reproduce with the smallest number of concurrent calls that fail.

## See also

- `errors.md`, `async.md`, `types.md`, `testing.md`
- `../../shared/toolchain.md` — typecheck and test commands for this repo
