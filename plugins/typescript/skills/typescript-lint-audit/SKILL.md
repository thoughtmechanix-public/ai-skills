---
name: typescript-lint-audit
description: >
  Run the repo's TypeScript linter and typecheck, explain the findings, and
  recommend config changes. Use when the user wants a lint pass, asks what
  is wrong from a lint perspective, or wants ESLint, Biome, or tsc config
  improved. Use when they run /typescript-lint-audit. Skip for a design
  audit (typescript-code-audit) and for applying fixes unless they ask.
license: MIT
---

# TypeScript lint audit

Explain lint and typecheck output. The commands live in `../../shared/toolchain.md`. The coding rules live in the `typescript` skill. This skill adds grouping, plain-language explanations, and config advice.

## Procedure

1. Find the linter and `tsconfig` using `toolchain.md`. Record what you found, including "no linter configured."
2. Run typecheck and lint with the repo's existing config. Do not pass a one-off rule set that hides results.
3. Group findings with the table below. A `tsc` error is a bug when it indicates a real type hole, and a type-error otherwise.
4. For each distinct rule (not each duplicate past the first three), write: what it means, why it matters here, a fix in the repo's style, and when a local suppression is honest.
5. Recommend config changes only for a real gap (no linter, `strict` off, type-aware lint rules missing while `typescript-eslint` is already a dependency). Point scaffolded packages at the greenfield setup in `toolchain.md`. Do not paste a second config into a repo that already has one; say what to add.

Do not run a formatter write. Do not `--fix` unless the user asks.

## Categories

| Category | Typical rules | Severity |
|---|---|---|
| Bugs | `no-floating-promises`, `no-misused-promises`, `require-atomic-updates`, unsafe assignment that hides `undefined` | Critical |
| Types | `no-explicit-any`, `no-unsafe-*`, `ban-ts-comment`, `tsc` errors | Critical when the value crosses a boundary; otherwise warning |
| Errors and control flow | `no-empty`, useless catches the linter flags | Critical |
| Complexity | cognitive complexity, max-lines, nested callbacks | Warning |
| Style | Prettier or Biome format diffs, import order | Suggestion |

## One finding

```markdown
#### {rule}: {short title}

**Where:** `file.ts:{line}`

**What:** {plain language}

**Why:** {what breaks or rots}

**Fix:**
​```ts
{replacement}
​```

**Suppress:** {the local comment, and the only situation where it is honest; or "do not suppress"}
```

## Report

```markdown
## Lint audit report

**Project:** {name}
**Typecheck:** {command} — {n} errors
**Lint:** {command} — {n} findings, or "no linter configured"

### Summary

| Category | Count | Severity |
|---|---|---|
| Bugs | {n} | Critical |
| Types | {n} | |
| Errors and control flow | {n} | |
| Complexity | {n} | |
| Style | {n} | |

### Findings
{grouped, using the finding shape above}

### Config
{gaps, or "config matches the repo's stated rules"}
```

If there is no linter, say so at the top and still report typecheck. Suggest the greenfield ESLint setup from `toolchain.md` only when the package has no lint config at all.
