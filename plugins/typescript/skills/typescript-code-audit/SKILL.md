---
name: typescript-code-audit
description: >
  Audit a TypeScript project for smells, anti-patterns, and non-idiomatic
  types, errors, async, and module layout. Use when the user asks for a code
  quality audit, "how good is this code", or "audit my code" on a TypeScript
  repo. Use when they run /typescript-code-audit. Skip when they want a bug
  fixed, tests run, or lint only (typescript-lint-audit). A single PR diff
  is typescript-code-review.
license: MIT
---

# TypeScript code audit

Read the whole project against the `typescript` skill. Do not restate that skill. Route to its siblings and use each sibling's audit mode.

## Scope

Default: the package or workspace the user named, or the repo root if they did not. Do not expand into dependencies under `node_modules`.

## Procedure

1. Read `../../shared/toolchain.md`. Run typecheck and lint. Save the command and the counts. Tool output is evidence, not the whole audit.
2. Read the `typescript` skill (`../typescript/SKILL.md`) and then, in order, its `types.md`, `errors.md`, `async.md`, and `organization.md`. Run the audit section each file describes. Cap is the cap that sibling names.
3. Skim tests only for the testing-quality items in `testing.md` (assertions, mocks, sleeps). Coverage numbers belong to `typescript-test-coverage`. Do not run a coverage audit here unless the user asked for both.
4. Read the public entry (`package.json` `"exports"` or the main bin) and the modules it reaches. Findings on dead experiments outside that graph are suggestions, not critical.

Each finding needs `file:line`, the sibling rule it breaks, and the smallest change that would follow that rule.

## Severity

- **Critical** — a defect the tools or the siblings call a bug: unsound `any` at a boundary, an empty catch around I/O, a floating promise whose rejection is lost, a race on shared module state.
- **Warning** — the code works and will mislead the next edit: string-matched errors, a cycle, a cast after a missing parser, business logic in the entry file.
- **Suggestion** — local clarity. A suggestion does not lower the score by itself.

## Report

```markdown
## Code audit report

**Project:** {name}
**Date:** {date}
**Files read:** {count}
**Typecheck:** {command} — {pass or fail}
**Lint:** {command} — {pass, fail, or no linter configured}

### Summary
- Critical: {n}
- Warning: {n}
- Suggestion: {n}

### Findings

#### Critical

1. **{title}** — `{file}:{line}`
   - Rule: {sibling} — {rule}
   - Fix: {smallest change}

#### Warning

1. **{title}** — `{file}:{line}`
   - Rule: {sibling} — {rule}
   - Fix: {smallest change}

#### Suggestion

1. **{title}** — `{file}:{line}`
   - Fix: {smallest change}

### Next
1. {highest-leverage change}
```

Do not invent a numeric quality score. Do not edit source unless the user asks to fix the findings.
