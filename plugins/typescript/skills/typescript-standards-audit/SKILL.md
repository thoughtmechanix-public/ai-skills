---
name: typescript-standards-audit
description: >
  Check a TypeScript project against this plugin's standards: public docs,
  compiler strictness, dependency hygiene, layout, errors, and async.
  Use when the user asks for a standards check, documentation completeness,
  project structure, or dependency health. Use when they run
  /typescript-standards-audit. Skip for a one-off idiom question
  (typescript) or a lint-only pass (typescript-lint-audit).
license: MIT
---

# TypeScript standards audit

The rules live in the `typescript` skill and in `../../shared/toolchain.md`. This skill is the checklist and the report. Do not copy those files into the report; cite the sibling and the path.

## Procedure

### 1. Documentation

On the public entry (`package.json` `"exports"`, or the published types):

- Each exported function and type has a TSDoc summary that says what it does for the caller.
- Comments that only repeat the parameter name are not summaries.
- A package with no external callers still documents the bin's flags in the README when a CLI or service exists.

```bash
# Exported declarations. Confirm a /** */ block immediately above each one you will cite.
rg -n "^export (async )?(function|class|const|type|interface|enum) " --glob '!*.test.ts' --glob '!*.test.tsx'
```

### 2. Compiler

Read the `tsconfig` that builds the package. Compare it to the greenfield options in `../typescript/organization.md`.

- For a package this plugin scaffolded, every greenfield flag that is off is a finding.
- For any other package, a finding is `strict` off, or a flag the repo's own docs require that is missing. Do not file a finding for every greenfield flag an older repo never adopted.

Run typecheck via `toolchain.md`.

### 3. Dependencies

```bash
# Manager from toolchain.md. Examples:
npm ls --depth=0
npm outdated || true
```

Use the repo's package manager. Findings:

- No lockfile
- A direct dependency the source does not import (check before reporting; config plugins and CLIs are used)
- A dependency marked abandoned or with a known critical advisory the package manager prints

Do not install `depcheck` or `knip` for the audit. If they are already scripts, run them.

### 4. Layout, errors, async

Walk `organization.md`, `errors.md`, and `async.md` in review mode over the public modules. Report mismatches as findings with `file:line`.

### 5. Tests exist

Confirm the package has a test script from `toolchain.md` and at least one unit test file. Depth and coverage belong to `typescript-test-coverage`.

## Report

```markdown
## Standards report

**Project:** {name}

### Documentation
- Public exports with a TSDoc summary: {n}/{total}
- Missing: {file:symbol list}

### Compiler
- tsconfig: {path}
- strict: {on or off}
- Drift from the standard that applies to this package: {list or none}
- Typecheck: {pass or fail}

### Dependencies
- Lockfile: {present or missing}
- Direct dependencies unused: {list or none}
- Advisories the package manager printed: {list or none}

### Layout and runtime rules
- {finding — sibling — file:line}

### Tests
- Script: {name or missing}
- Unit files: {count}

### Next
1. {first change}
```

Do not score the repo with a single number. Do not edit source unless the user asks.
