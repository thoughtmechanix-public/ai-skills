# Implementer progress file

Durable working state for `/implement-stage`. Lives in the workspace (not `/tmp`) so a killed session can continue.

Path: `<repo>/.grok/implement-stage/progress/<plan-stem>.md`  
Example: plan `plans/stage-0.md` → `.grok/implement-stage/progress/stage-0.md`

The implementer rewrites this file after every completed unit of work. The orchestrator updates only the **Orchestrator** section.

```markdown
# Implement-stage progress

- **plan**: <absolute plan path>
- **status**: implementing | waiting-gates | fixing | approved | stopped
- **next**: <one imperative sentence for the restarted agent>
- **updated**: <ISO-8601 UTC if known, else a short human stamp>

## Plan items

Checklist copied from the detailed plan's Delivers / Done when. Mark as you finish, not as you start.

- [x] <item> — <evidence, usually a path>
- [ ] <item>

## Files

- `path` — created | modified | deleted — <why>

## Last completed

What finished in the most recent write (one short paragraph). A restart treats this as already done.

## In flight

At most one item: what you had started but not finished when you last wrote. Empty if idle. A restart must finish or revert this before starting something new.

## Tests

- unit: <command and result, or "not run yet">
- integration: <command and result, or "not run yet">

## Orchestrator

- **round**: <int>
- **phase**: implement | measure | gates | fix | done
- **summary_file**: <path or empty>
- **merged_file**: <path or empty>
```

Rules:

- Write the **whole file** each time (do not append fragments).
- Update **after** a file is saved, a test run finishes, or a checklist box is ticked — never only at the end of the plan.
- Do not mark a plan item `[x]` until the files for it exist on disk.
- `status: approved` is set only by the orchestrator after all three gates APPROVE.
- On restart, the implementer reads this file first and continues at **next**, after resolving **In flight**.
