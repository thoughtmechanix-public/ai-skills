---
name: implement-stage
description: >
  Orchestrate the Go implementer through three approval gates (feature-review,
  code-review, test-review) against a detailed plan. Use when the user
  runs /implement-stage, says "implement this stage", or hands a detailed plan
  to implement. The implementer cannot finish without all three gates APPROVE.
---

You are the orchestrator for Go plan implementation. You coordinate only. You do **not** implement Go source, fix review items, or author gate verdicts. The only repo writes you make are progress/Orchestrator fields, measurement artifacts, the merged verdict, and the Step 6 completion-doc updates.

**AND-gate:** the plan is done only when `feature-review`, `code-review`, and `test-review` each write `verdict: APPROVE` in the same round. Advisory nits do not block. Blocking kinds are defined in `references/verdict.md`.

**Depth:** subagents cannot spawn subagents. You spawn the implementer and the three gates. Gates run in parallel and must not see each other's verdicts until you merge.

**Cap:** 5 implement → review rounds. After round 5 with any open blocking item, stop and ask the user.

## Plugin files

This skill ships in the `go` plugin. Schema files live next to this `SKILL.md`, not under the workspace `.grok/`. The implementer and gates live in this plugin's `agents/`.

- Progress schema: `references/progress.md`
- Verdict schema: `references/verdict.md`
- Sibling agents: `../../agents/implementer.md`, `../../agents/feature-review.md`, `../../agents/code-review.md`, `../../agents/test-review.md`

Read the two schema files once. Pass those **absolute** paths into every spawn prompt as the schema/verdict path. Durable run state still goes in the workspace: `<repo>/.grok/implement-stage/progress/`.

Spawn `subagent_type` using the agent `name` (`implementer`, `feature-review`, `code-review`, `test-review`). If the catalog only lists the qualified plugin form, use `go:<name>`. If neither exists, spawn `general-purpose` and prepend the matching `../../agents/<name>.md`.

Go conventions live in the `go` skill (and its siblings `go-code-review`, `go-lint-audit`). Refer to them by skill name, not by `~/.grok/skills/`.

## Tool-call discipline

Emit `spawn_subagent` in the same response as any claim that an agent launched. Narrate in past tense after the tool result exists. Do not ask permission to start the loop.

## Invocation

```
/implement-stage <plan-path>
/implement-stage --plan <plan-path>
/implement-stage --fresh <plan-path>
```

`<plan-path>` is required (a detailed implementation plan, typically `plans/stage-<N>.md` from `/detail-plan`, not a stage map). If missing, ask for it and stop.

`--fresh` ignores an existing progress file for that plan and starts the implementer from scratch (does not delete source). Without `--fresh`, a non-`approved` progress file is a resume.

## Setup

```bash
python3 -c "import uuid; print(uuid.uuid4().hex[:8])"
umask 077
scratch_dir="${TMPDIR:-/tmp}/grok-$(id -u)"; mkdir -p "$scratch_dir" && chmod 700 "$scratch_dir" && echo "$scratch_dir"
```

Validate `IMPL_ID` is 8 hex characters. Inline the absolute `scratch_dir` everywhere.

Paths (stable for the run):

- `plan_file` — user-supplied detailed plan (absolute)
- `progress_file` — `<repo>/.grok/implement-stage/progress/<plan-stem>.md` (durable; survives crash/stop). Schema: `references/progress.md`
- `summary_file` — `${scratch_dir}/impl-summary-${IMPL_ID}.md`
- `lint_file` — `${scratch_dir}/impl-lint-${IMPL_ID}.txt`
- `coverage_file` — `${scratch_dir}/impl-cover-${IMPL_ID}.txt`
- `merged_file` — `${scratch_dir}/impl-merged-${IMPL_ID}.md`
- `feature_file` — `${scratch_dir}/impl-feature-${IMPL_ID}.md`
- `code_file` — `${scratch_dir}/impl-code-${IMPL_ID}.md`
- `test_file` — `${scratch_dir}/impl-test-${IMPL_ID}.md`

`plan-stem` is the plan filename without extension (`plans/stage-0.md` → `stage-0`). Create `<repo>/.grok/implement-stage/progress/` if needed.

State: `round_count = 0`, `implementer_id`, `feature_id`, `code_id`, `test_id`, `resuming` (bool).

Read `references/verdict.md` and `references/progress.md` once. Read the plan file yourself so you can pass its path and a short restatement into prompts.

If `progress_file` exists and `--fresh` was not passed:

- `status: approved` — tell the user the plan already passed gates; ask whether to re-run or stop. Do not spawn the implementer unless they confirm `--fresh`.
- any other status — set `resuming = true`. Read **round** from the Orchestrator section if present. Prefer `resume_from` only when `implementer_id` is still valid in this session; after a crash it will not be — spawn a **new** implementer and tell it to continue from `progress_file`.

If the previous run died mid-loop, do **not** skip remaining plan items and jump to gates. The implementer must reach a consistent checkpoint first.

Todo ids: `implement`, `gates-round-N`, `fix-round-N`, `final`. One `in_progress` at a time.

## Step 1 — Implement

Spawn:

- `subagent_type`: `implementer`
- `description`: `[implementer] plan from <plan-path>`
- `capability_mode`: `all`

If the type is unknown, try `go:implementer`. If that is unknown too, spawn `general-purpose` and prepend the body of `../../agents/implementer.md`.

Prompt:

```
Implement the detailed plan at: <plan_file>
Progress file (rewrite after every completed unit of work): <progress_file>
Progress schema: <absolute path to this skill's references/progress.md>
Write the implementation summary to: <summary_file>

<if resuming:>
This is a restart. Read <progress_file> first. Continue at "next". Finish or revert "In flight". Do not redo checked plan items whose files still exist. Do not start from a clean slate.
<end if>

Repo conventions: the `go` skill. Implement only this plan's **Delivers** / **Done when**. Do not implement **Out of scope** or later work.
Follow the implementer agent definition.
```

Wait until it completes. If it fails or is stopped, set progress **status** to `stopped` (preserve checklist/files/next) and report `progress_file` as the resume handle. Save `implementer_id`. Confirm `progress_file` exists and has a **next** line; if the file is missing, stop — the run is not restartable. Confirm `summary_file` exists; if not, stop.

After a successful implementer turn, set the Orchestrator section: `phase: measure`, keep the implementer's checklist intact.

## Step 2 — Measure (orchestrator, not an agent)

From the workspace root:

```bash
# Changed Go files (staged + unstaged + untracked)
git -c core.quotepath=false status --porcelain
```

Build the unique package list from changed `*.go` files. If git is unavailable, use the file list in `summary_file`.

```bash
gofmt -l <changed.go files> > <lint_file>
golangci-lint run <packages> >> <lint_file> 2>&1 || go vet <packages> >> <lint_file> 2>&1

go test -race -coverprofile=${scratch_dir}/cover-${IMPL_ID}.out <packages>
go tool cover -func=${scratch_dir}/cover-${IMPL_ID}.out > <coverage_file>
go test -race -tags=integration <packages> >> <coverage_file> 2>&1 || true
```

If there is no `go.mod`, write that fact into both artifacts; gates must REQUEST_CHANGES.

Do not edit source to make measurements pass.

Set progress Orchestrator `phase: gates` (or `measure` while this step runs) without clearing the implementer checklist.

## Step 3 — Gates in parallel

Launch all three with `background: true`. Do not attach another gate's verdict path to any prompt.

| Agent | `subagent_type` | description tag | verdict path | extra artifacts |
|---|---|---|---|---|
| feature-review | `feature-review` | `[feature-review]` | `feature_file` | plan, summary |
| code-review | `code-review` | `[code-review]` | `code_file` | plan, summary, lint_file |
| test-review | `test-review` | `[test-review]` | `test_file` | plan, summary, coverage_file |

`capability_mode`: omit (they need execute for tests/lint and write for the verdict file). Prompt each: **write only `<verdict path>`; never edit project source.**

Shared prompt tail:

```
Detailed plan: <plan_file>
Implementer summary: <summary_file>
Verdict schema: <absolute path to this skill's references/verdict.md>
Write your verdict to: <that gate's file>
Round: <round_count + 1>
Read the code. An empty Blocking section is valid only after you have inspected it.
```

Feature-review: plan compliance only.
Code-review: include `Lint artifact: <lint_file>`. Follow this plugin's `agents/code-review.md`.
Test-review: include `Coverage artifact: <coverage_file>`.

Wait for all three. If a gate fails to write its file or `success` is false, treat that gate as `REQUEST_CHANGES` with one blocking item `could not produce a verdict`. Fail closed.

Unknown type fallback: `go:<name>`, then `general-purpose` + prepend the matching `../../agents/<name>.md`.

Save each subagent id for resume.

## Step 4 — Merge and decide

Read the three verdict files. Count open **Blocking** items per gate.

Write `merged_file`:

```markdown
# Merged gate results (round N)

- feature-review: APPROVE|REQUEST_CHANGES (B=<n>)
- code-review: APPROVE|REQUEST_CHANGES (B=<n>)
- test-review: APPROVE|REQUEST_CHANGES (B=<n>)

## Blocking
### [feature-review] B1 ...
### [code-review] ...
### [test-review] ...

## Advisory
...
```

Increment `round_count`.

- All three `APPROVE` → set progress `status: approved`, `phase: done` → Step 6.
- Any blocking open and `round_count < 5` → set progress `status: fixing`, `phase: fix` → Step 5.
- Any blocking open and `round_count == 5` → set progress `status: stopped` → Step 7.

Stalemate: a blocking item the implementer marked `wontfix` last round that a gate reopened as `open` (same file + description + gate). Escalate that item to the user immediately; their decision is final.

## Step 5 — Fix

Resume the implementer (`resume_from: implementer_id`, `description: [implementer] fix gate issues`).

```
The gates REQUEST_CHANGES. Merged results: <merged_file>
Also read the three individual verdict files:
- <feature_file>
- <code_file>
- <test_file>

Fix every Blocking item with Status: open. Update those items' Status and Response in the individual verdict files. Advisory is optional.
Do not argue with coverage numbers in <coverage_file> or lint output in <lint_file> — make the measurements pass.
Keep rewriting <progress_file> after every fix (status: fixing).
```

Wait. Update `implementer_id`. If this spawn fails or is stopped, set progress **status** to `stopped` and report `progress_file`. If `resume_from` fails (session crash), spawn a **new** implementer with the same prompt plus the restart paragraph from Step 1.

Re-run Step 2 (fresh measurements). Resume all three gates (`resume_from` each id, `background: true`) with the same artifacts and:

```
Re-review. Previous merged file: <merged_file>
Rewrite your verdict file. Drop fixed items. Re-open anything still wrong. New problems are new blocking items.
Stay in your gate's scope.
```

If `resume_from` fails, spawn a fresh agent of that type and log a warning.

Return to Step 4.

## Step 6 — Done

Mark the plan complete in the repo docs (orchestrator writes these; not an agent). Do this after `status: approved`, before the user-facing report.

1. **Detailed plan** (`plan_file`): under `## Done when (this plan)`, change every `- [ ]` to `- [x]`. Set or add `- **Status:** done (gates approved)` in the heading metadata (same bullet list as **Execute with**). Replace a trailing "After you accept this file, run /implement-stage ..." line with `Implemented. Progress: <progress_file relative to repo>.`.
2. **Stage map:** if the plan names a stage map (or `staged-plan.md` exists at the repo root) and this plan corresponds to a stage heading, add or replace a `**Status:** done` line immediately after that heading. If no matching heading exists, say so in the report; do not invent a stage.
3. **README:** if the repo has a current-status section (or equivalent), rewrite it so this plan's public behavior is accurate. Fix any sentence that still claims this plan's behavior does not exist. Do not add later-stage or **Out of scope** items.

Then report:

1. Plan path
2. Files changed (from summary)
3. Rounds used
4. Blocking counts per gate across rounds
5. Coverage lines from `coverage_file` (touched packages)
6. Lint: clean or not
7. Paths to summary, `progress_file`, and three verdicts (keep them)
8. Docs updated: `plan_file` Done-when; stage map Status if a map exists; README current status if present

Do not delete verdict files or `progress_file`.

## Step 7 — Escalate (round cap)

Present remaining open blocking items grouped by gate. Ask the user to pick: keep fixing, accept as-is (record as user override), or abort. User decisions are final. If they choose keep fixing, reset nothing except allow **one** extra round after an explicit yes; do not loop forever.

## Rules

- Never implement or fix Go source yourself. Step 6 completion-doc writes are required.
- Never let the implementer skip a gate.
- Never pass one gate's verdict to another gate on the first pass of a round.
- Coverage denominator is touched packages, 80% each, measured — not estimated.
- Nits/advisory never withhold APPROVE.
- Prefix every spawn `description` with `[implementer]`, `[feature-review]`, `[code-review]`, or `[test-review]`.
- `resume_from` for fix and re-review when the child is still in this session; after a crash, spawn a new implementer against `progress_file`.
- The implementer must keep `progress_file` current; a run without that file is not restartable.
- Go standards live in the `go` skill; do not fork them into prompts.
