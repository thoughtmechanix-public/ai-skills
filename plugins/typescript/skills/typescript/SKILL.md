---
name: typescript
description: >
  Idiomatic TypeScript: types, errors, async, testing, module layout, and
  debugging. Use when the user writes, reviews, or debugs TypeScript or TSX,
  asks if code is idiomatic, or asks an open TypeScript question that does
  not fit a more specific skill. Use when they run /typescript. Skip for a
  full audit (typescript-code-audit), lint-only (typescript-lint-audit),
  coverage (typescript-test-coverage), or scaffolding
  (/new-typescript-cli, /new-typescript-service).
---

**Modes:**

- **Coding mode** — writing TypeScript. Apply the sibling for that topic. Match the repo's existing compiler flags, linter, and test runner (`../../shared/toolchain.md`).
- **Review mode** — reviewing a diff. Check the categories below that the diff touches.
- **Audit mode** — the sibling's audit section. Dispatch the parallel sub-agents that sibling names.

> Clear is better than clever. Prefer a type a new teammate can read over one that encodes the same fact three ways.

# TypeScript

## Topic routing

Read the sibling. Do not answer a deep topic from this file alone.

| Topic | Trigger phrases | Sibling |
|---|---|---|
| Types | "should this be a type", unions, generics, `any`, `unknown`, narrowing, public API shape | `types.md` |
| Errors | throw vs result, `unknown` in catch, error `cause`, HTTP error mapping | `errors.md` |
| Async | promises, `async`/`await`, `AbortSignal`, floating promises, concurrency | `async.md` |
| Testing | "how do I test this", `*.test.ts`, tables, fakes, integration tests | `testing.md` |
| Layout | "where should this file go", `exports`, `tsconfig`, cycles, barrels | `organization.md` |
| Debugging | "why is this broken", failing tests, stack traces, type errors that hide a bug | `debugging.md` |

Framework code (React, Next, Angular, and others) still follows these rules for types, errors, and async. Do not invent a framework style guide in this skill.

## Cross-cutting smells

Name the smell and follow the sibling. The sibling owns the rule.

- `any`, a cast that skips a check, or `!` to silence the checker → `types.md`
- Empty `catch`, thrown non-Errors, matching on `error.message` → `errors.md`
- A promise with no `await`, `.catch`, or explicit handoff → `async.md`
- An assertion on a mock call or a private field → `testing.md`
- A cycle through `index.ts`, or business logic in the process entry → `organization.md`

## When the right design is unclear

Use this only when all of the following hold:

- The user is designing something new: a public type, a module boundary, an error policy, or a multi-step refactor.
- They asked for alternatives, or the choice is a durable public contract and more than one shape is honest.
- A single answer would be enough if the constraints were already clear.

Do not use it for reviews, "is this idiomatic", or a small refactor with an obvious shape.

When the gate is met, spawn 3 or more sub-agents in one message. Give each a different constraint, for example: smallest public surface, easiest call site, closest match to the repo's existing types. Each returns signatures, one call-site example, and what it hides. Compare in prose, then pick or combine.

This is for competing designs, not for searching the repo. It applies most often to `types.md` and `organization.md`.

## Debugging rule

No fix before a root-cause investigation. Do not guess. If three fix attempts fail, stop and report what you know. The procedure is `debugging.md`.

## Further reading

- `types.md` — unions, boundaries, generics, public signatures
- `errors.md` — catch, cause, codes, boundaries
- `async.md` — promises, cancellation, fan-out
- `testing.md` — tables, fakes, integration files
- `organization.md` — layout, `tsconfig`, `exports`
- `debugging.md` — reproduce, then fix
- `../../shared/toolchain.md` — which binary to run in this repo
