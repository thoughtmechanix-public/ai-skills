---
name: git-prepare-pr
description: >
  Push the current branch and open a GitHub pull request. Draft the title and
  body from the branch's commit messages using the PR template, ask the user
  for any missing PR fields, then push and create the PR only after they
  accept. Use when the user runs /git-prepare-pr, says "open a PR", "create a
  pull request", "push and open a PR", or "prepare a pull request".
---

You open a **GitHub** pull request for the current branch. You push that branch as part of this skill. You do not create the PR or push until the user accepts the draft.

You do not make new commits. If they still have uncommitted work, point them at `/git-commit`.

## Invocation

```
/git-prepare-pr
```

No arguments. If they name a base branch, use that as the proposed base.

## PR template

Read the template **before** drafting. Use the first file that exists:

1. `<repo>/.grok/pr.md`
2. this skill's `references/pr.md`

Follow that file. Do not invent extra sections. Do not copy the template headings into the PR unless the template says they belong there.

## Procedure

### 1. Repo

From the workspace:

```bash
git rev-parse --show-toplevel
git status --porcelain=v1
git branch --show-current
git remote -v
command -v gh
gh auth status
gh repo view --json defaultBranchRef,url,nameWithOwner
```

Stop if this is not a git repo, `gh` is missing, `gh` is not authenticated, or there is no `origin` remote.

If `HEAD` is detached, stop. They need a branch.

If the working tree is not clean, say so and ask whether to abort (and run `/git-commit`) or continue with the commits that already exist. Do not stage or commit here.

Default **base** is the repo's default branch (`defaultBranchRef`). If they named a base, use that instead.

```bash
git fetch origin <base>
git log --format='%h %s' origin/<base>..HEAD
git log --format='%s%n%n%b' origin/<base>..HEAD
```

Stop if there are no commits on this branch that are not on the base.

If the current branch **is** the base (`main`, `master`, or the default branch), ask for a new branch name, create it from `HEAD`, and continue on that branch. Do not push `main` or `master` as the PR head.

If an open PR already exists for this branch (`gh pr view --json url,title,state`), show the URL and ask: **leave it** / **update title and body** / **abort**. Do not open a second PR.

### 2. Draft

From the commit messages (not from memory), fill the template. Title from the primary commit subject when there is one commit; otherwise a short summary of the set.

Show the user:

1. Head branch and base
2. Commit list (`hash subject`)
3. The exact PR title
4. The exact PR body
5. Draft vs ready (propose ready)
6. Reviewers (propose none unless they already named some)

Ask anything the template requires that the commits do not answer (especially **Test plan**). Ask reviewers only if they want any.

Ask with `ask_user_question`: **accept, push, and open PR** / **edit the PR** / **abort**.

- **edit the PR** — revise title, body, base, draft/ready, or reviewers until they accept. Do not push in between.
- **abort** — stop. Do not push. Do not call `gh pr create`.

### 3. Push

Only after **accept, push, and open PR**:

```bash
git push -u origin HEAD
```

Do not pass `--force` or `-f`. If they explicitly ask for a lease after a rejected push, `--force-with-lease` is allowed; still never force-push `main` or `master`.

If push fails, show the output and stop. Do not create the PR.

### 4. Create or update the PR

Write the accepted body to a temp file (exact bytes). Then:

**New PR:**

```bash
gh pr create --base <base> --title <title> --body-file <temp-file> [--draft] [--reviewer <login>,...]
```

**Update existing PR** (only if they chose update in step 1):

```bash
gh pr edit --title <title> --body-file <temp-file>
```

Do not add `--reviewer` on edit unless they asked to change reviewers.

Delete the temp file. Show the PR URL (`gh pr view --json url -q .url`).

## Rules

- Never push or open a PR without an explicit accept.
- Never `git commit` or `git add` as part of this skill.
- Never `--force` / `-f`. Never force-push `main` or `master`.
- Never push tags unless the user asks in this turn.
- Never update git config.
- Prefer `gh`. Do not use the GitHub REST API by hand if `gh` works.
