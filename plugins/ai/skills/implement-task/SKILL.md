---
name: implement-task
description: >
  Orchestrate a language-agnostic implementer through feature-review and
  qa-review until both APPROVE. Use when the user runs /implement-task, says
  "implement this task", or hands over a task and names the language and the
  approach. The implementer cannot finish without both gates APPROVE. Skip
  when the user wants the Go loop (/go-implement-stage) or the TypeScript
  loop (/typescript-implement-stage).
---

You are the orchestrator. You coordinate only. You do not implement source, fix review items, or author gate verdicts. The only writes you make are the inline task file, progress and Orchestrator fields, the merged verdict, and — after both gates APPROVE — checking **Done when** boxes on the task file.

**AND-gate:** the task is done only when `feature-review` and `qa-review` each write `verdict: APPROVE` in the same round. Advisory items do not block. Kinds are defined in `references/verdict.md`.

**Depth:** subagents cannot spawn subagents. You spawn the implementer and the two gates. Gates run in parallel and must not see each other's verdicts until you merge.

**Cap:** 5 implement → review rounds. After round 5 with any open blocking item, stop and ask the user.

The user names the language and the approach at kickoff. Do not infer them from the repo. Do not run language-specific lint or coverage yourself. QA runs the checks.

## Plugin files

This skill ships in the `ai` plugin. Schema files live next to this `SKILL.md`. Agents live in this plugin's `agents/`.

- Progress schema: `references/progress.md`
- Verdict schema: `references/verdict.md`
- Agents: `../../agents/implementer.md`, `../../agents/feature-review.md`, `../../agents/qa-review.md`

Read both schema files once. Pass those absolute paths into every spawn prompt. Durable run state goes in the workspace: `<repo>/.grok/implement-task/progress/`.

Spawn `subagent_type` as `ai:implementer`, `ai:feature-review`, and `ai:qa-review`. Unqualified `implementer` and `feature-review` belong to other plugins. If a qualified type is unknown, spawn `general-purpose` and prepend the matching `../../agents/<name>.md`. Do not pass `capability_mode`. It is not a spawn argument.

## Tool-call discipline

Emit `spawn_subagent` in the same response as any claim that an agent launched. Narrate in past tense after the tool result exists. Do not ask permission to start the loop once language and approach are known.

## Invocation

```
/implement-task <task>
/implement-task --task <path> --language <language> --approach <approach>
/implement-task --fresh <task>
```

`<task>` is a file path or the rest of the message. A directory is not a task.

**Language** and **approach** are required. They count as given when the kickoff message names them, including by pointing at a file. If either is missing, ask once for both and stop. Do not read a manifest to fill them in.

Examples of a complete kickoff:

```
/implement-task plans/stage-0.md --language Go --approach "Follow the go skill. 80% coverage on touched packages."
/implement-task Add a health endpoint. Language: Python. Approach: pytest and ruff. Match the existing package layout.
```

`--fresh` ignores an existing progress file for that task and starts the implementer from scratch. It does not delete source in the parent checkout. Tear down a recorded worktree first (`grok worktree rm --force <path>`, else `git worktree remove --force <path>`), then `git branch -f impl/<task-stem> HEAD`. Without `--fresh`, a non-`approved` progress file is a resume.

## Setup

```bash
python3 -c "import uuid; print(uuid.uuid4().hex[:8])"
umask 077
scratch_dir="${TMPDIR:-/tmp}/grok-$(id -u)"; mkdir -p "$scratch_dir" && chmod 700 "$scratch_dir" && echo "$scratch_dir"
```

Validate `IMPL_ID` is 8 hex characters. Inline the absolute `scratch_dir` everywhere.

`task-stem` is the task filename without an extension when the task is a file. When the task is inline text, slug the first line to kebab-case, at most 48 characters. `task_file` is `<repo>/.grok/implement-task/tasks/<task-stem>.md`. Write the inline text there when the file is missing. If the file exists and its contents differ, stop and ask for a stem unless `--fresh` was passed. With `--fresh`, overwrite it. If the contents match, keep the file.

Paths:

- `task_file` — absolute task path
- `progress_file` — `<repo>/.grok/implement-task/progress/<task-stem>.md`
- `branch` — `impl/<task-stem>`
- `worktree_path` — empty until the first implementer write to `progress_file`
- `summary_file` — `${scratch_dir}/task-summary-${IMPL_ID}.md`
- `merged_file` — `${scratch_dir}/task-merged-${IMPL_ID}.md`
- `feature_file` — `${scratch_dir}/task-feature-${IMPL_ID}.md`
- `qa_file` — `${scratch_dir}/task-qa-${IMPL_ID}.md`

Create the progress directory if needed.

State: `round_count = 0`, `implementer_id`, `feature_id`, `qa_id`, `resuming`, `worktree_path`, `branch`, `language`, `approach`.

If the approach is a file, keep its absolute path and a one-line restatement. Agents read the file. Do not rewrite it.

Before the first implementer spawn, create the branch in the parent without checking it out:

```bash
git branch --show-current
git show-ref --verify --quiet refs/heads/<branch> || git branch <branch> HEAD
```

If the parent is already on `<branch>`, stop. Do not switch the parent's branch.

Read the task yourself so you can pass its path and a short restatement.

If `progress_file` exists and `--fresh` was not passed:

- `status: approved` — tell the user the task already passed both gates. Ask whether to re-run with `--fresh` or stop.
- any other status — set `resuming = true`. Read **round**, **language**, and **approach**. If the kickoff names a different language or approach, stop and ask which wins. Read **worktree**. If that directory is missing, stop. Uncommitted work lived there. Prefer `resume_from` only when `implementer_id` is still valid in this session. After a crash, spawn a new implementer with `cwd` set to **worktree** and tell it to continue from `progress_file`.

If the previous run died mid-loop, do not skip remaining task items and jump to gates. The implementer must reach a consistent checkpoint first.

Todo ids: `implement`, `gates-round-N`, `fix-round-N`, `final`. One `in_progress` at a time.

## Step 1 — Implement

Spawn:

- `subagent_type`: `ai:implementer`
- `description`: `[implementer] <task-stem>`
- `isolation`: `worktree` when `worktree_path` is empty. When resuming in a new agent, `cwd` is `<worktree_path>` and isolation is omitted. `resume_from` inherits the worktree. Do not pass isolation or cwd with it.

If the type is unknown, spawn `general-purpose` and prepend `../../agents/implementer.md`.

Prompt:

```
Task: <task_file>
Language: <language>
Approach: <approach>
Progress file (rewrite after every completed unit of work): <progress_file>
Progress schema: <absolute path to references/progress.md>
Write the implementation summary to: <summary_file>
Branch: <branch>
Follow the implementer agent definition. Checkout <branch> in the spawn worktree.

<if resuming:>
This is a restart. Read <progress_file> first. Continue at "next". Finish or revert "In flight". Do not redo checked items whose files still exist in the worktree.
<end if>

Implement only this task. Follow the language and the approach above. Do not implement **Out of scope**, **Non-goals**, or later work.
```

Wait until it completes. Save `implementer_id`. If it fails or is stopped, and `progress_file` exists, set **status** to `stopped` without clearing the checklist, files, next, worktree, branch, language, or approach, and report that path as the resume handle. If `progress_file` is missing, stop. The run is not restartable. On success, confirm the file has a **next** line and a live **worktree** directory, and confirm `summary_file` exists. If the summary is missing, stop. Set `worktree_path` from progress **worktree**, or from the spawn result if progress lacks it.

After a successful implementer turn, set Orchestrator `phase: gates`. Keep the implementer's checklist intact.

## Step 2 — Gates in parallel

Launch both with `background: true`. Do not attach the other gate's verdict path.

| Agent | `subagent_type` | description | verdict path |
|---|---|---|---|
| feature-review | `ai:feature-review` | `[feature-review] round N` | `feature_file` |
| qa-review | `ai:qa-review` | `[qa-review] round N` | `qa_file` |

`cwd`: `<worktree_path>`. Do not pass `isolation: worktree`. Prompt each: write only its verdict path, and do not edit project source.

Shared prompt:

```
Task: <task_file>
Language: <language>
Approach: <approach>
Implementer summary: <summary_file>
Verdict schema: <absolute path to references/verdict.md>
Write your verdict to: <that gate's file>
Round: <round_count + 1>
Read the code. An empty Blocking section is valid only after you have inspected it.
```

Feature-review: task compliance only.
QA-review: re-run the checks. Stay in the qa-review scope.

Wait for both. If a gate fails to write its file or does not succeed, treat that gate as `REQUEST_CHANGES` with one blocking item `could not produce a verdict`. Fail closed.

Unknown type: `general-purpose` plus the matching agent file. Do not fall through to an unqualified name.

Save each subagent id.

## Step 3 — Merge and decide

Read both verdict files. Count open **Blocking** items per gate.

Write `merged_file`:

```markdown
# Merged gate results (round N)

- feature-review: APPROVE|REQUEST_CHANGES (B=<n>)
- qa-review: APPROVE|REQUEST_CHANGES (B=<n>)

## Blocking
### [feature-review] B1 ...
### [qa-review] ...

## Advisory
...
```

Increment `round_count`.

- Both `APPROVE` → Step 5.
- Any blocking item open and `round_count < 5` → set progress `status: fixing`, `phase: fix` → Step 4.
- Any blocking item open and `round_count == 5` → set progress `status: stopped` → Step 6.

Stalemate: a blocking item the implementer marked `wontfix` last round that the same gate reopened as `open` (same file, description, and gate). Escalate that item now. The user's decision is final.

## Step 4 — Fix

Resume the implementer (`resume_from: implementer_id`, `description: [implementer] fix round N`).

```
The gates REQUEST_CHANGES. Merged results: <merged_file>
Also read both verdict files:
- <feature_file>
- <qa_file>

Fix every Blocking item with Status: open. Update Status and Response on those items. Advisory is optional.
Language: <language>
Approach: <approach>
Do not argue with a check the approach named. Make it pass.
Keep rewriting <progress_file> after every fix (status: fixing).
```

Wait. Update `implementer_id`. If this spawn fails or is stopped, set progress **status** to `stopped` and report `progress_file`, then stop. If `resume_from` fails, spawn a new `ai:implementer` with `cwd: <worktree_path>`, the same prompt, plus the restart paragraph from Step 1.

Resume both gates (`resume_from` each id, `background: true`) with the same artifacts and:

```
Re-review. Previous merged file: <merged_file>
Rewrite your verdict file. Drop fixed items. Re-open anything still wrong. New problems are new blocking items.
Stay in your gate's scope.
Language: <language>
Approach: <approach>
```

If `resume_from` fails, spawn a fresh agent of that type with `cwd: <worktree_path>` and log a warning.

Return to Step 3. Both gates re-review every round, including a gate that APPROVE'd last round. Agreement is on the current tree.

## Step 5 — Done

Both gates APPROVE. Do this in order:

1. Set progress `status: approved` and `phase: done`. Write **round**, **summary_file**, and **merged_file**.
2. If the task file has a `## Done when` section, check every `- [ ]` in that section. Edit the worktree copy when the file is inside the worktree. Otherwise edit `task_file`. Do not mark any other section. Do not edit a stage map.

Then report:

1. Task path, language, and approach
2. Worktree path and branch (`impl/<task-stem>`), unmerged
3. Rounds used
4. Blocking counts per gate across rounds
5. Check commands and results from the qa-review summary
6. Paths to the summary, `progress_file`, and both verdicts

Stop. Commit, pull request, and Fizzy updates are not part of this skill. The user decides the next step.

Do not delete verdict files or `progress_file`.

## Step 6 — Escalate

Present the open blocking items grouped by gate. Ask the user to keep fixing, accept as-is, or abort. Their decision is final. Keep fixing allows one extra round after an explicit yes. Do not loop on your own.

If they accept as-is, record the override in `progress_file` (**status** `approved`, and a line under Orchestrator naming the waived items) and report the Step 5 list. Do not check **Done when** boxes.

## Rules

- Never implement or fix source yourself. Checking **Done when** boxes is the only task-file edit you make.
- Never let the implementer skip a gate.
- Never pass one gate's verdict to the other on the first pass of a round.
- Nits and advisory items never withhold APPROVE.
- Prefix every spawn description with `[implementer]`, `[feature-review]`, or `[qa-review]`.
- Use `resume_from` for fix and re-review while the child is still in this session. After a crash, spawn a new implementer against `progress_file`.
- The implementer must keep `progress_file` current. A run without that file is not restartable.
- The first implementer spawn uses `isolation: worktree`. Resume a live implementer with `resume_from`. A new implementer or any gate uses `cwd: <worktree_path>`. Never `isolation: worktree` for a gate.
- Never merge `<branch>` into the parent checkout.
- Do not commit, open a pull request, or update Fizzy.
- Do not bake in a language, a coverage number, or a linter. The kickoff's language and approach are the standard. If the approach names a skill, the agents read that skill.
