---
name: typescript-test-coverage
description: >
  Find untested TypeScript behavior, measure coverage, and draft table-driven
  tests. Use when the user asks what tests are missing, how to improve
  coverage, or for test stubs. Use when they run /typescript-test-coverage.
  Skip when they only want existing tests run or a failure debugged
  (typescript debugging topic).
license: MIT
---

# TypeScript test coverage

Measure, then name the missing behavior. Commands, file names, and the 80% statement bar are in `../../shared/toolchain.md`. Test shape is in `../typescript/testing.md`. Do not add a test framework the package does not already use.

## Procedure

1. Run the coverage command from `toolchain.md`. If the tool cannot print a per-package number, say so and list gaps from source instead of inventing a percentage.
2. List exported functions and methods in changed or named packages whose lines are at 0%, and branches the report marks partial.
3. For each gap, name the cases: the success path, each thrown `code` or result error, and the boundary inputs (`""`, missing key, aborted signal) the function's types allow.
4. Map each case to a unit or integration file using the names in `toolchain.md`. Integration is for the public entry (CLI, HTTP, package export used as a process). Everything else is a unit test.
5. Draft stubs only when the user asks for stubs or for the tests to be written. Use the table shape in `testing.md` and the runner this package already has. A stub must contain a real assertion. Do not leave `assert.ok(true)`.

## Report

```markdown
## Test coverage report

**Project:** {name}
**Command:** {coverage command}
**Bar:** 80% statements on each touched package

### By package

| Package | Statements | Status |
|---|---|---|
| {name} | {n}% | {meets bar or short} |

### Untested behavior

| Symbol | File | Missing case |
|---|---|---|
| `loadConfig` | `src/load-config.ts` | missing file → `ConfigError` code `config` |

### Cases to add

#### `loadConfig`
1. Unit — valid file and flag — returns the flag value
2. Unit — missing path — `ConfigError` with code `config`
3. Integration — CLI `--help` — exit 0

### Stubs
{paths written, or "none — ask to write them"}
```

Do not lower the bar because the package is old. You may limit the report to the packages the user named. Say which packages you measured.
