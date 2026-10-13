---
name: stage-plan
description: >
  Turn a rough prompt into a high-level plan of ordered stages. Assess gaps,
  ask clarifying questions, then write plans/staged-plan.md in the working
  directory. Use when the user runs /stage-plan, asks to break work into
  stages, or wants a high-level plan before a language detail plan. Skip when
  they want one stage broken into files and tests (/go-detail-plan,
  /typescript-detail-plan) or want that stage implemented.
---

You write a **stage map**. You do not write file layouts, test tables, or source, and you do not run a detail-plan or implement skill.

`/go-detail-plan` and `/typescript-detail-plan` consume this file. They own *how*. This skill owns *what* and *done when*, split into stages.

## Invocation

```
/stage-plan <prompt>
/stage-plan
```

The prompt is the user's goal, notes, or a path to a doc. If they only name the skill, ask what they want to plan. The working directory is the repo they have open, unless they name another directory.

Output: `plans/staged-plan.md` in that directory. Create `plans/` if it is missing. Headings and labels come from `references/staged-plan.md`.

If `plans/staged-plan.md` already exists, show its first heading and ask: overwrite, revise that file, or write a different filename. A different filename is not the file the detail skills load by default. Say that when you ask.

## Procedure

### 1. Read

Read only enough to see what the prompt assumes:

- The prompt, plus any doc it names
- `README` or the equivalent at the working directory
- Manifests that name the stack (`go.mod`, `package.json`, `Cargo.toml`, `pyproject.toml`, and the same idea for another language)
- Existing files in `plans/`, including `plans/staged-plan.md` and `plans/stage-*.md`

Do not audit the codebase. Do not invent stages from files the prompt did not mention.

### 2. Assess gaps

In the reply, before any question, list three groups:

- **Known** — facts from the prompt or the files you read, each with its source
- **Gaps** — missing facts that would change the number, order, or boundary of a stage
- **Later** — choices that can wait for the detail plan (names, signatures, schemas)

A gap is one of these, and only when the prompt and the tree do not already answer it:

| Gap | Why it changes the map |
|---|---|
| Outcome | No way to say what "done" is for the whole effort |
| Check | No observable way to know a stage is finished |
| Boundary | In-scope work and later work are mixed |
| Order | One stage secretly depends on another |
| Stack | Which detail skill to name, when the tree does not force it |
| Conflict | The prompt disagrees with the tree or an existing plan |

Skip a row that is already answered. Do not add a gap to have something to ask.

### 3. Ask

Do not write `plans/staged-plan.md` until every gap in that list is answered.

- Closed choices: `ask_user_question`, recommended option first. When a manifest makes the stack obvious, recommend that detail skill (`/go-detail-plan` for a Go module, `/typescript-detail-plan` for a TypeScript package).
- Free text: one cluster in a normal question. Group related gaps. Do not ask one field per turn.
- Do not re-ask a fact already in **Known**.

Record answers. They become the Decisions table.

### 4. Draft the stages

Show titles, one deliver each, and the order. Ask whether to split, merge, or reorder. Edit until they accept. Then write the file.

Rules for the stages:

- Number from 0. Title each stage `## Stage <N> — <title>`.
- A stage is one increment a person can verify. It is not a function, a file, or a test case.
- Stage 0 is the smallest increment that proves the outcome.
- Use two or more stages when the outcome has more than one independently verifiable increment. Use one stage only after the user confirms the work is a single increment.
- **Depends on** names earlier stages by number. Stage 0 depends on nothing in this plan.
- **Open for the detailed plan** holds choices that do not move a stage boundary. If a choice would move a boundary, it belongs in step 3, not here.
- **Non-goals** holds what the user deferred. Later stages are not non-goals; they are later stages.
- **Detail with** is `/go-detail-plan <N>` or `/typescript-detail-plan <N>`. Use the decision from step 3. Stages may name different detail skills when the user said so.
- No file trees, signatures, or test tables. Those are the detail plan.

### 5. Write

Create `plans/` in the working directory. Fill `references/staged-plan.md` without renaming its labels. Separate stages with `---`.

Then report:

- The path
- Stage numbers and titles
- The next command, which is the Stage 0 **Detail with** line

Stop. Do not start the detail plan unless they run it.

## Rules

- One stage map per run. A revision edits `plans/staged-plan.md` (or the filename they chose). Do not write a second map beside it.
- Do not implement, and do not edit product source.
- If an answer contradicts the prompt, stop and ask which one wins. Do not silently pick.
- Vague done-when lines ("works", "good coverage", "handled properly") go back to step 3. Rewrite them as something a person can observe.
