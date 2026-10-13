# Staged plan — <title>

- **Working directory:** <absolute path>
- **Prompt:** <one paragraph, the request in the user's words>
- **Detail with:** `/go-detail-plan` | `/typescript-detail-plan` | choose per stage

## Decisions

Locked here. A detail-plan run must not re-ask these.

| Decision | Choice | Source |
|---|---|---|
| <name> | <choice> | prompt or interrogation |

## Outcome

What is true when every stage is done. Observable, not a list of tasks.

## Non-goals

Work this plan does not include. Detail-plan treats these as out of scope.

- <item>

## Stage 0 — <title>

**Delivers**

- <one verifiable increment>

**Done when**

- <observable check a person can run or see>

**Depends on**

- None. First stage.

**Open for the detailed plan**

- <names, shapes, or choices that do not change stage boundaries>

**Detail with:** `/go-detail-plan 0`

---

## Stage 1 — <title>

**Delivers**

- <increment that assumes Stage 0>

**Done when**

- <observable check>

**Depends on**

- Stage 0 — <which Done when line>

**Open for the detailed plan**

- <item>

**Detail with:** `/typescript-detail-plan 1`

---

Repeat the stage section for every later stage. Separate stages with `---`. Keep the labels **Delivers**, **Done when**, **Depends on**, and **Open for the detailed plan** so `/go-detail-plan` and `/typescript-detail-plan` can split on the stage heading or the rule.
