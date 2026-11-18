# Implementer progress file

Durable working state for `/implement-task`. Lives in the parent workspace `.grok/` so a killed session can continue.

Path: `<repo>/.grok/implement-task/progress/<task-stem>.md`

The implementer rewrites this file after every completed unit of work. The orchestrator updates **status** and the **Orchestrator** section only. **Files** and checklist evidence refer to the worktree.

```markdown
# implement-task progress

- **task**: <absolute task path>
- **language**: <as the user named it>
- **approach**: <as the user named it, or the absolute path of the approach file>
- **worktree**: <absolute implementer worktree path>
- **branch**: impl/<task-stem>
- **status**: implementing | waiting-gates | fixing | approved | stopped
- **next**: <one imperative sentence for the restarted agent>
- **updated**: <ISO-8601 UTC if known, else a short human stamp>

## Task items

Checklist copied from the task. Use **Done when** / **Delivers** when those headings exist. Otherwise use the observable outcomes in the task. Mark as you finish, not as you start.

- [x] <item> — <evidence, usually a path>
- [ ] <item>

## Files

- `path` — created | modified | deleted — <why>

## Last completed

What finished in the most recent write (one short paragraph). A restart treats this as already done.

## In flight

At most one item: what you had started but not finished when you last wrote. Empty if idle. A restart must finish or revert this before starting something new.

## Tests

- <command and result, or "not run yet">

## Orchestrator

- **round**: <int>
- **phase**: implement | gates | fix | done
- **summary_file**: <path or empty>
- **merged_file**: <path or empty>
```

Rules:

- Write the whole file each time.
- Update after a file is saved, a test run finishes, or a checklist box is ticked.
- Do not mark a task item `[x]` until the files for it exist on disk.
- Keep **task**, **language**, **approach**, **worktree**, and **branch** on every rewrite.
- `status: approved` is set only by the orchestrator after both gates APPROVE in the same round.
- On restart, the implementer reads this file first and continues at **next**, after resolving **In flight**.
- A resume without a live directory at **worktree** is not restartable. Uncommitted work lived in that tree.
