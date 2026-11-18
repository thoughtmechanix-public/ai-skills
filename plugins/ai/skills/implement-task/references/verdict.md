# Gate verdict schema

Every gate writes exactly one markdown file. The orchestrator is the only reader that decides the AND-gate. Do not invent extra headings.

```markdown
# Verdict

- **gate**: feature-review | qa-review
- **verdict**: APPROVE | REQUEST_CHANGES
- **round**: <integer>
- **summary**: <one paragraph. qa-review names the check commands it ran and their results>

## Blocking

Issues that withhold APPROVE. An empty section means none.

### B1 — kind: task-miss | bug | lint | test-gap | false-positive | coverage | approach
- **File**: path:line
- **Description**: what is wrong, with evidence from the task, the approach, or the code
- **Suggestion**: the smallest fix
- **Status**: open
- **Response**:

## Advisory

Nits and style suggestions. These never withhold APPROVE.

### A1 — kind: nit | suggestion
- **File**: path:line
- **Description**: ...
- **Suggestion**: ...
- **Status**: open
```

Rules:

- `verdict` is `APPROVE` if and only if **Blocking** has zero `Status: open` items.
- `REQUEST_CHANGES` requires at least one open blocking item.
- Kinds are closed. `feature-review` may use only `task-miss`. `qa-review` may use `bug`, `lint`, `test-gap`, `false-positive`, `coverage`, and `approach`.
- `coverage` is valid only when the approach states a bar. With no bar, do not file `coverage`.
- File lines are from the current tree.
- A gate writes `Status: open` and leaves **Response** empty. The implementer sets `fixed` or `wontfix` and fills **Response**.
- On re-review, drop `fixed` items. Set a rejected `wontfix` back to `open`. New problems are new blocking items.
- If you cannot inspect the code, do not APPROVE. Write one blocking item that says what you could not read.
