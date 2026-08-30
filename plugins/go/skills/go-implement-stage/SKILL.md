---
name: go-implement-stage
description: >
  Orchestrate the Go implementer through three approval gates (feature-review,
  code-review, test-review) against a detailed plan. Use when the user
  runs /go-implement-stage, says "implement this stage", or hands a detailed plan
  to implement. The implementer cannot finish without all three gates APPROVE.
---

You are the orchestrator for Go plan implementation. You coordinate only. You do **not** implement Go source, fix review items, or author gate verdicts. The only writes you make are progress/Orchestrator fields, measurement artifacts, the merged verdict, Step 6 completion-doc updates in the implementer worktree, and — after all three gates APPROVE — the local commit, GitHub PR, and Fizzy Ready For PR updates.

**AND-gate:** the plan is done only when `feature-review`, `code-review`, and `test-review` each write `verdict: APPROVE` in the same round. Advisory nits do not block. Blocking kinds are defined in `references/verdict.md`.

**Depth:** subagents cannot spawn subagents. You spawn the implementer and the three gates. Gates run in parallel and must not see each other's verdicts until you merge.

**Cap:** 5 implement → review rounds. After round 5 with any open blocking item, stop and ask the user.

## Plugin files

This skill ships in the `go` plugin. Schema files live next to this `SKILL.md`, not under the workspace `.grok/`. The implementer and gates live in this plugin's `agents/`.

- Progress schema: `references/progress.md`
- Verdict schema: `references/verdict.md`
- Sibling agents: `../../agents/implementer.md`, `../../agents/feature-review.md`, `../../agents/code-review.md`, `../../agents/test-review.md`

Read the two schema files once. Pass those **absolute** paths into every spawn prompt as the schema/verdict path. Durable run state still goes in the workspace: `<repo>/.grok/go-implement-stage/progress/`.

Spawn `subagent_type` using the agent `name` (`implementer`, `feature-review`, `code-review`, `test-review`). If the catalog only lists the qualified plugin form, use `go:<name>`. If neither exists, spawn `general-purpose` and prepend the matching `../../agents/<name>.md`.

Go conventions live in the `go` skill (and its siblings `go-code-review`, `go-lint-audit`). Refer to them by skill name, not by `~/.grok/skills/`.

## Tool-call discipline

Emit `spawn_subagent` in the same response as any claim that an agent launched. Narrate in past tense after the tool result exists. Do not ask permission to start the loop.

## Invocation

```
/go-implement-stage <plan-path>
/go-implement-stage --plan <plan-path>
/go-implement-stage --fresh <plan-path>
```

`<plan-path>` is required (a detailed implementation plan, typically `plans/stage-<N>.md` from `/go-detail-plan`, not a stage map). If missing, ask for it and stop.

`--fresh` ignores an existing progress file for that plan and starts the implementer from scratch (does not delete source in the parent checkout). Tear down a recorded worktree first (`grok worktree rm --force <path>`, else `git worktree remove --force <path>`), then `git branch -f impl/<plan-stem> HEAD`. Without `--fresh`, a non-`approved` progress file is a resume.

## Setup

```bash
python3 -c "import uuid; print(uuid.uuid4().hex[:8])"
umask 077
scratch_dir="${TMPDIR:-/tmp}/grok-$(id -u)"; mkdir -p "$scratch_dir" && chmod 700 "$scratch_dir" && echo "$scratch_dir"
```

Validate `IMPL_ID` is 8 hex characters. Inline the absolute `scratch_dir` everywhere.

Paths (stable for the run):

- `plan_file` — user-supplied detailed plan (absolute, parent checkout)
- `progress_file` — `<repo>/.grok/go-implement-stage/progress/<plan-stem>.md` (durable in the parent `.grok/`; survives crash/stop). Schema: `references/progress.md`
- `branch` — `impl/<plan-stem>` (create in the parent repo with `git branch`, never checkout there)
- `worktree_path` — implementer's linked worktree; empty until the first implementer write to `progress_file`
- `summary_file` — `${scratch_dir}/impl-summary-${IMPL_ID}.md`
- `lint_file` — `${scratch_dir}/impl-lint-${IMPL_ID}.txt`
- `coverage_file` — `${scratch_dir}/impl-cover-${IMPL_ID}.txt`
- `merged_file` — `${scratch_dir}/impl-merged-${IMPL_ID}.md`
- `feature_file` — `${scratch_dir}/impl-feature-${IMPL_ID}.md`
- `code_file` — `${scratch_dir}/impl-code-${IMPL_ID}.md`
- `test_file` — `${scratch_dir}/impl-test-${IMPL_ID}.md`

`plan-stem` is the plan filename without extension (`plans/stage-0.md` → `stage-0`). Create `<repo>/.grok/go-implement-stage/progress/` if needed.

State: `round_count = 0`, `implementer_id`, `feature_id`, `code_id`, `test_id`, `resuming` (bool), `worktree_path`, `branch`.

Before the first implementer spawn, ensure the branch exists and is not checked out in the parent:

```bash
git show-ref --verify --quiet refs/heads/<branch> || git branch <branch> HEAD
```

Read `references/verdict.md` and `references/progress.md` once. Read the plan file yourself so you can pass its path and a short restatement into prompts.

If `progress_file` exists and `--fresh` was not passed:

- `status: approved` — if **pr** is empty, Finish did not complete; go to Step 6. If **pr** is set, tell the user the plan already passed gates; ask whether to re-run or stop. Do not spawn the implementer unless they confirm `--fresh` (same worktree teardown as `--fresh` above).
- any other status — set `resuming = true`. Read **round** from the Orchestrator section if present. Read **worktree**. If that directory is missing, stop — uncommitted implementer work lived there and is not recoverable by spawning a new tree. Prefer `resume_from` only when `implementer_id` is still valid in this session; after a crash it will not be — spawn a **new** implementer with `cwd` set to **worktree** (not `isolation: worktree`) and tell it to continue from `progress_file`.

If the previous run died mid-loop, do **not** skip remaining plan items and jump to gates. The implementer must reach a consistent checkpoint first.

Todo ids: `implement`, `gates-round-N`, `fix-round-N`, `final`. One `in_progress` at a time.

## Step 1 — Implement

Spawn:

- `subagent_type`: `implementer`
- `description`: `[implementer] plan from <plan-path>`
- `capability_mode`: `all`
- `isolation`: `worktree` when `worktree_path` is empty (first run or `--fresh`). `cwd`: `<worktree_path>` and no isolation when resuming in a new agent. `resume_from` inherits the worktree; do not pass isolation or cwd.

If the type is unknown, try `go:implementer`. If that is unknown too, spawn `general-purpose` and prepend the body of `../../agents/implementer.md`.

Prompt:

```
Implement the detailed plan at: <plan_file>
Progress file (rewrite after every completed unit of work): <progress_file>
Progress schema: <absolute path to this skill's references/progress.md>
Write the implementation summary to: <summary_file>
Branch: <branch>
Follow the implementer worktree rules. Checkout <branch> in the spawn worktree.
Take the next Fizzy story to In-progress before source edits (implementer **Fizzy** section).

<if resuming:>
This is a restart. Read <progress_file> first. Continue at "next". Finish or revert "In flight". Do not redo checked plan items whose files still exist in the worktree. Do not start from a clean slate.
<end if>

Repo conventions: the `go` skill. Implement only this plan's **Delivers** / **Done when**. Do not implement **Out of scope** or later work.
Follow the implementer agent definition.
```

Wait until it completes. If it fails or is stopped, set progress **status** to `stopped` (preserve checklist/files/next/worktree/branch/fizzy_card) and report `progress_file` as the resume handle. Save `implementer_id`. Confirm `progress_file` exists and has a **next** line and a live **worktree** directory; if the file is missing, stop — the run is not restartable. Confirm `summary_file` exists; if not, stop. Set `worktree_path` from progress **worktree**, or from the spawn result if progress lacks it.

After a successful implementer turn, set the Orchestrator section: `phase: measure`, keep the implementer's checklist intact.

## Step 2 — Measure (orchestrator, not an agent)

From `worktree_path` (not the parent checkout):

```bash
# Changed Go files (staged + unstaged + untracked)
git -C <worktree_path> -c core.quotepath=false status --porcelain
```

Build the unique package list from changed `*.go` files. If git is unavailable, use the file list in `summary_file`.

```bash
gofmt -l <changed.go files under worktree_path> > <lint_file>
(cd <worktree_path> && golangci-lint run <packages> >> <lint_file> 2>&1) || (cd <worktree_path> && go vet <packages> >> <lint_file> 2>&1)

(cd <worktree_path> && go test -race -coverprofile=${scratch_dir}/cover-${IMPL_ID}.out <packages>)
go tool cover -func=${scratch_dir}/cover-${IMPL_ID}.out > <coverage_file>
(cd <worktree_path> && go test -race -tags=integration <packages> >> <coverage_file> 2>&1) || true
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

`capability_mode`: omit (they need execute for tests/lint and write for the verdict file). `cwd`: `<worktree_path>`. Do not pass `isolation: worktree` (that would be a new empty tree). Prompt each: **write only `<verdict path>`; never edit project source.**

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

Wait. Update `implementer_id`. If this spawn fails or is stopped, set progress **status** to `stopped` and report `progress_file`. If `resume_from` fails (session crash), spawn a **new** implementer with `cwd: <worktree_path>` (not `isolation: worktree`), the same prompt, plus the restart paragraph from Step 1.

Re-run Step 2 (fresh measurements). Resume all three gates (`resume_from` each id, `background: true`) with the same artifacts and:

```
Re-review. Previous merged file: <merged_file>
Rewrite your verdict file. Drop fixed items. Re-open anything still wrong. New problems are new blocking items.
Stay in your gate's scope.
```

If `resume_from` fails, spawn a fresh agent of that type (`cwd`: `<worktree_path>` for gates and for a new implementer) and log a warning.

Return to Step 4.

## Step 6 — Done

Mark the plan complete in the **worktree** docs (orchestrator writes these; not an agent). Do this after `status: approved`, before the user-facing report. Map each parent path to `<worktree_path>/<relative-to-repo-root>`. Do not write these files in the parent checkout. Do not merge `<branch>`.

1. **Detailed plan** (worktree copy of `plan_file`): under `## Done when (this plan)`, change every `- [ ]` to `- [x]`. Set or add `- **Status:** done (gates approved)` in the heading metadata (same bullet list as **Execute with**). Replace a trailing "After you accept this file, run /go-implement-stage ..." line with `Implemented. Progress: <progress_file relative to repo>.`.
2. **Stage map:** if the plan names a stage map (or `staged-plan.md` exists at the worktree root) and this plan corresponds to a stage heading, add or replace a `**Status:** done` line immediately after that heading. If no matching heading exists, say so in the report; do not invent a stage.
3. **README:** if the worktree has a current-status section (or equivalent), rewrite it so this plan's public behavior is accurate. Fix any sentence that still claims this plan's behavior does not exist. Do not add later-stage or **Out of scope** items.

4. **Commit and PR (orchestrator, no user accept).** After the docs above, in `worktree_path` on `<branch>`, follow `git-commit` then `git-prepare-pr`. Treat that worktree as the git workspace (`git -C <worktree_path>` / `cd` there for `gh`). Do not ask the user to accept the summary, message, or PR draft — gates APPROVE is the authorization. Skip the `git-commit` tag prompt (do not tag). Keep every other rule from those skills (templates, secret exclusion, no `--no-verify`, no `--force`/`-f`, default branch as base, no second PR, prefer `gh`). If the tree is already clean, skip `git-commit` and continue to `git-prepare-pr`. If `gh` is missing or push/create fails, report the local commit and stop — do not update Fizzy.
5. **Fizzy Ready For PR.** Only after a PR URL exists. Follow the `fizzy` skill. For each open card in the plan **Fizzy stories** table: keep the existing description and append a **Pull request** section with the `git-commit` change summary (or the PR Summary) and the GitHub PR URL as a markdown link (`fizzy card update <number> --description_file`). Move the card to **Ready For PR** (`fizzy column list --board`, name match case-insensitive; create the column if missing). Write **pr** into `progress_file`.

Then report:

1. Plan path
2. Worktree path and branch (`impl/<plan-stem>`); not merged into the parent checkout
3. Commit hash and GitHub PR URL
4. Fizzy cards moved to Ready For PR
5. Files changed (from summary)
6. Rounds used
7. Blocking counts per gate across rounds
8. Coverage lines from `coverage_file` (touched packages)
9. Lint: clean or not
10. Paths to summary, `progress_file`, and three verdicts (keep them)
11. Docs updated in the worktree: plan Done-when; stage map Status if a map exists; README current status if present

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
- First implementer spawn uses `isolation: worktree`. Resume a live implementer with `resume_from`. A new implementer or any gate uses `cwd: <worktree_path>`. Never `isolation: worktree` for gates.
- Never merge `<branch>` into the parent checkout.
- After docs, Step 6 follows `git-commit` then `git-prepare-pr` in the worktree **without user accept**, then updates Fizzy cards. Do not resume the implementer for commit/PR.
- Go standards live in the `go` skill; do not fork them into prompts.
