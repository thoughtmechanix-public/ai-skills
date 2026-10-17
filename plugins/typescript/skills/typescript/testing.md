# TypeScript — Testing

Loaded by `SKILL.md` when the user is writing or reviewing tests.

A test names a behavior. It fails when that behavior breaks and passes when the behavior holds, including after an internal refactor.

File names, runners, and the coverage bar are in `../../shared/toolchain.md`.

## Modes

**Coding.** Use the runner the package already has. For a new package created by `new-typescript-cli` or `new-typescript-service`, use `node:test` and `node:assert/strict`.

**Review.** Missing cases named by the change, assertions on mocks, sleeps, and tests that import private helpers only to read hidden state.

**Audit.** Up to four sub-agents: exported functions with no test; tests with no assertion; shared mutable state across tests; integration behavior covered only by a unit test that mocks the boundary.

## Rules

1. One behavior per test name. The name is a sentence: `returns config error when the file is missing`.
2. Prefer a table when the cases share a setup and differ by input and expectation.
3. Assert on the return value, the thrown `code` / class, or the observable side effect (HTTP status and body, rows written, text sent to stdout).
4. Do not assert that a mock was called as the only proof the feature works.
5. Do not mock a module you do not own. Wrap that dependency in a small function this package owns, and fake the wrapper.
6. Build collaborators this package owns for real when they are pure or in-memory. Fake only the edge (clock, network, filesystem, process).
7. Do not sleep. Use fake timers (`node:test` mock timers, or the runner's equivalent) or wait on an event with a deadline.
8. Integration tests use the `*.integration.test.ts` name from `toolchain.md` and exercise the public entry (CLI argv, HTTP server, exported function) without replacing the module under test.
9. Each case that `toolchain.md` calls a unit test stays a unit test. Do not put network or process setup in a unit file.
10. Restore env and working directory in a `finally` or the runner's equivalent (`t.after`). Do not leak `process.env` into the next test.
11. A test written after a fix must fail if the fix is reverted. If it passes with the bug still present, it is not a regression test.

## Table shape (`node:test`)

```ts
import assert from "node:assert/strict";
import { test } from "node:test";
import { loadConfig } from "./load-config.ts";

const cases = [
  {
    name: "uses the flag when the file also sets a timeout",
    file: "timeout: 20\n",
    flag: "5",
    want: 5,
  },
];

for (const item of cases) {
  test(item.name, async () => {
    const got = await loadConfig({ fileText: item.file, flag: item.flag });
    assert.equal(got.timeoutSeconds, item.want);
  });
}
```

Vitest: `it.each` with the same columns (name, setup, input, want). Do not introduce a second style in a package that already has one.

## Anti-patterns

| Smell | What to do |
|---|---|
| Snapshot of an entire object when one field is the behavior | Assert that field |
| `as unknown as PrivateType` to read a field | Assert through the public API |
| Mock of `fs` / `fetch` / the database driver | Wrap the edge and fake the wrapper, or use an integration test |
| `setTimeout` to wait for a write | An event, a fake timer, or a poll with a deadline |
| Test name `works` or `test 1` | Name the behavior |

## See also

- `types.md` — public types under test
- `errors.md` — how to assert failures
- `async.md` — timers and abort in tests
- `debugging.md` — a failing test is evidence, not a prompt to edit the assertion
