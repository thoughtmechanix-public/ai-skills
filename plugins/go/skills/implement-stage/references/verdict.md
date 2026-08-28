# Gate verdict schema

Every gate agent writes exactly one markdown file. The orchestrator is the only reader that decides the AND-gate. Do not invent extra headings.

```markdown
# Verdict

- **gate**: feature-review | code-review | test-review
- **verdict**: APPROVE | REQUEST_CHANGES
- **round**: <integer>
- **summary**: <one paragraph>

## Blocking

Issues that withhold APPROVE. Empty section means none.

### B1 — kind: plan-miss | bug | lint | test-gap | false-positive | coverage
- **File**: path:line
- **Description**: what is wrong, with evidence from the plan or the code
- **Suggestion**: the smallest fix
- **Status**: open

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
- Kinds are closed: do not invent new ones.
- File lines are from the current tree, not from memory.
- If you cannot inspect the code, do not APPROVE. Write one blocking item explaining what you could not read.
