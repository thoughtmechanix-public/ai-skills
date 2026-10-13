---
name: typescript-detail-plan
description: >
  Turn a TypeScript project's stage of work into a detailed implementation
  plan: interrogate the user for open decisions, then write step-by-step
  module layout, dependencies and blockers, and specific unit and integration
  test cases, then create one Fizzy card per implementation step on the Grok
  Developer board. Use when the user runs /typescript-detail-plan, says
  "detail stage N" for a TypeScript repo, "detailed plan for stage 0", or
  asks to flesh out a stage before /typescript-implement-stage.
---

You write a **detailed implementation plan** for one unit of TypeScript work. You do not implement source and you do not run `/typescript-implement-stage`.

The stage map is the source of *what* and *done when*. This skill produces *how*: files, signatures, order, blockers, and named tests. After the user accepts the plan, you open that *how* as Fizzy stories. The implementer (`/typescript-implement-stage`) is the only consumer that writes code.

## Invocation

```
/typescript-detail-plan <stage>
/typescript-detail-plan 0
/typescript-detail-plan foundation
/typescript-detail-plan --stage 3
```

`<stage>` is a number or a unique title substring from the stage map. If missing, list the stage titles from the map and ask which one.

Default stage map: `plans/staged-plan.md` (written by `/stage-plan`). If that file is missing, use `staged-plan.md` at the repo root. If both are missing, ask for the map path (or confirm a one-off slice of work with no map). Do not assume a fixed number of stages or a fixed set of titles.

Output path: `plans/stage-<N>.md` when the stage is numbered; otherwise `plans/<slug>.md`. Example: Stage 0 → `plans/stage-0.md`.

If that file already exists, show its first heading and ask overwrite / cancel. Do not overwrite without confirmation.

## Procedure

### 1. Load context

Read, in order:

1. The stage map — extract the matching stage section through the next stage heading or horizontal rule.
2. Any spec or design doc the stage (or user) names — only the facts that stage's **Delivers** depend on. Do not paste the whole spec into the plan. If none is named, skip.
3. TypeScript skills the stage names, or else the `typescript` skill plus the siblings the work implies (`new-typescript-cli` for a new CLI, `new-typescript-service` for a new HTTP service, and topic files such as `organization.md` / `testing.md` for the rest). Tool commands and the coverage bar: `../../shared/toolchain.md`.
4. The current tree (`package.json`, `tsconfig`, `src/`, existing tests) enough to see whether prior stages' **Done when** already hold.

Do not copy skill prose into the plan. Cite the skill name.

### 2. Interrogate

You may not write the plan until open decisions are answered. Ask **before** drafting.

Always ask (skip a bullet only if the stage section already locked it):

- Every item the stage lists as open for the detailed plan
- Underspecified names: package name, module paths, config keys, command names, route paths
- Anything in **Delivers** that cannot be implemented without a choice

Also resolve:

- **Prior-stage blocker:** if this is not the first stage and the tree does not satisfy the previous stage's **Done when**, tell the user and ask: stop, or plan anyway with the missing work listed as a blocker.
- **Scope creep:** if they ask to pull a later stage's deliverable in, refuse and keep it on **Out of scope**.

How to ask:

- Closed choices: `ask_user_question` (recommended option first).
- Free text (package name, routes): ordinary questions, one cluster per turn (related names together).
- Do not re-ask facts already locked in the stage map or a named spec.

Record answers. They become the Decisions table.

### 3. Write the plan

Create `plans/` if needed. Write the output file using the headings in `references/plan-template.md` (same heading names, filled in). Set **Stage map** to the path you loaded. Leave **Fizzy stories** as an empty table. Step 5 fills it.

Requirements for the body:

- **Implementation steps** are strictly ordered. Each step is a single checkpoint (one file or a tight group). Name modules and exported signatures. No full function bodies unless a type is otherwise ambiguous.
- **Layout:** follow `typescript` / `organization.md`. Match the repo. In a package this plan creates, use the greenfield layout in `organization.md`. Do not invent a second config system, test runner, or package manager if the repo already has one. Commands and test file names come from `../../shared/toolchain.md`.
- **Dependencies and blockers** are concrete paths or prior **Done when** lines.
- **Test cases** are specific (name, file, setup, input, want, wantErr). Cover the happy path, the error and edge cases the stage's Done when implies, and at least one `*.integration.test.ts` for the plan's public behavior. Unit tests are table-driven names, not "add tests."
- **Out of scope** is later work the stage map names plus user deferrals.

### 4. Confirm

Show the path and a short outline (step titles + test count). Ask whether to adjust. Edit the same file until they accept. Then go to step 5. Do not start implementation unless they explicitly run `/typescript-implement-stage` or ask to implement.

### 5. Open Fizzy stories

Create one Fizzy card per **Implementation step** on the **Grok Developer** board. Follow the `fizzy` skill for CLI usage (card NUMBER, `--jq`, `--description_file`, auth).

A card that still needs a user choice is not ready: return to step 2, then edit the plan. Do not write TBD, TODO, or "ask the user" into a card.

1. **Board.** `fizzy board list --jq '[.data[] | {id, name}]'`. Use the board whose name is `Grok Developer` or `Grok Developer Board` (exact, case-insensitive). Pass that id as `--board` on every card command. If auth fails or the name is missing or ambiguous: `fizzy doctor`, report, stop (the plan file stays).
2. **Dedupe.** List open, Not Now, and closed cards on that board. If any title starts with `S<stage>.` (`S0.` / `Sfoundation.`), show them and ask: update in place, skip Fizzy, or create additional. Do not silently duplicate.
3. **Bodies.** For each step, write a description file from `references/fizzy-card.md` (same heading names, filled in). The card is the unit of work: copy the files, signatures, behavior, the Decisions rows that step needs, the test rows it owns, Done when, and Out of scope. Linking the plan path is extra, not a substitute. The agent executing the card must not need to ask the user anything interrogation already answered.
4. **Create in order.** Title: `S<stage>.<k> — <step name>` (k is 1-based). `fizzy card create --board <id> --title "..." --description_file <path> --jq '.data | {number, url, title}'`. Record each number. Then rewrite every description so **Depends on** / **Blocks** use those `#<number>` values (Fizzy has no native blocker field) and `fizzy card update <number> --description_file <path>`.
5. **Depends on / Blocks.** Linear with the plan. Story k depends on every earlier story in this stage (those must be In-progress, Ready For PR, or closed — not Maybe or Not Now). Story k blocks story k+1. First checklist step: deps are not Maybe or Not Now. Last checklist step: move each Blocks card onto Maybe (`fizzy card column <n> --column maybe`). Other steps: the implement and test checklist for that story. Do not close the card when the step is done.
6. **Lanes.** Cards with an empty Depends on stay in Maybe (create default). Cards with dependencies: `fizzy card postpone <number>` so they are not on the open list. Tag `stage-<N>` or `stage-<slug>` (`fizzy card tag` toggles — skip if the tag is already on the card).
7. **Plan.** Fill **Fizzy stories** in the plan file. Report titles, numbers, URLs, and which card is unblocked.

If Fizzy fails after some creates, report what exists. Do not delete cards unless the user asks.

## Rules

- One stage per run. Never detailed-plan the next stage in the same file.
- Never implement or edit TypeScript source as part of this skill.
- If a choice would violate the stage map or a named spec, say so and keep the map/spec.
- If a choice would violate a TypeScript skill, the TypeScript skill wins. Do not write a competing convention into the plan.
- Feature-review will grade `/typescript-implement-stage` against this file. Vague tests ("good coverage") are a failed plan — rewrite them before finishing.
- Fizzy cards are part of this skill. If Fizzy is unavailable, say so and leave the plan in place.
