---
name: typescript-code-review
description: >
  First-pass review of a TypeScript PR, diff, or working tree. Use when the
  user asks to review a PR, review their changes, or says "what do you think
  of this code" about a diff. Use when they run /typescript-code-review.
  Skip for a whole-repo audit (typescript-code-audit) or lint-only
  (typescript-lint-audit).
license: MIT
---

# TypeScript code review

Review the diff. Apply the `typescript` skill's review mode for each sibling the diff touches (`types.md`, `errors.md`, `async.md`, `testing.md`, `organization.md`). Do not invent a second style guide.

## Procedure

### 1. Get the diff

Prefer the range the user named. Otherwise:

```bash
gh pr diff {number}
git diff
git diff --cached
git diff main...HEAD
```

### 2. Tools on the changed files

Follow `../../shared/toolchain.md` for typecheck and lint, limited to the touched packages. Run the package tests for those packages when they are fast enough to finish in this review. Record commands and results.

### 3. Read the diff

For each changed `.ts` / `.tsx` file, use the sibling review sections:

- **Types** — new `any`, casts, `!`, unparsed boundary input
- **Errors** — empty catch, thrown non-Errors, message matching, public stacks
- **Async** — floating promises, missing `AbortSignal` on new I/O, unbounded `Promise.all`
- **Tests** — behavior asserted, or only a mock call
- **Layout** — new cycles, logic in the entry, a second config path

### 4. Exported shape

On a package that already has callers, flag a breaking change when the diff:

- Removes or renames an export from `package.json` `"exports"` or from the package entry
- Narrows an accepted type, or widens a required input
- Removes a field a caller could have read, or changes a discriminant

Adding an optional field or a new export is not a break. Say "none" when the package is an application with no import API.

```bash
git diff main...HEAD -- '*.ts' '*.tsx' | grep -E '^-export '
```

That command is a hint. Read the surrounding lines before calling something a break.

## Report

```markdown
## Code review summary

**PR:** #{number} — {title}
**Files changed:** {count}

### Must fix ({n})
1. **`file.ts:{line}`** — {issue}
   {one suggested replacement}

### Should fix ({n})
1. **`file.ts:{line}`** — {issue}

### Nit ({n})
1. **`file.ts:{line}`** — {issue}

### Breaking changes
{list, or "None"}

### Tests
- {what the diff added, and what behavior is still untested}

### Tools
- Typecheck: {result}
- Lint: {result}
- Tests: {result or "not run"}

### Recommendation
**{APPROVE | REQUEST_CHANGES | COMMENT}**
{one paragraph}
```

`REQUEST_CHANGES` is for must-fix items. Nits do not block. `COMMENT` is for a review that could not run typecheck or could not see the tests and is not ready to approve.
