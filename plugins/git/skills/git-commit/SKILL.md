---
name: git-commit
description: >
  Prepare a local git commit: scan the working tree, summarize the changes,
  draft a message from the commit-message template, and commit only after the
  user accepts both the summary and the message. Then ask whether to tag.
  Use when the user runs /git-commit, says "prepare a commit", "commit these
  changes", "write a commit message", or "commit and tag".
---

You prepare a **local** git commit. You do not push. You do not commit until the user accepts the change summary **and** the commit message.

## Invocation

```
/git-commit
```

No arguments. If they name files, treat that as the proposed set; otherwise consider the whole working tree.

## Message template

Read the template **before** drafting the message. Use the first file that exists:

1. `<repo>/.grok/commit-message.md`
2. this skill's `references/commit-message.md`

Follow that file. Do not invent extra sections. Do not copy the template headings into the git message unless the template says they belong there.

## Procedure

### 1. Repo

From the workspace:

```bash
git rev-parse --show-toplevel
git status --porcelain=v1
git diff HEAD
git diff --cached
git log -5 --oneline
```

Stop if this is not a git repo, or if there is nothing to commit (clean tree, nothing staged or unstaged or untracked).

If a merge, rebase, or cherry-pick is in progress, say so and ask whether to continue.

If `HEAD` is detached, warn and ask before committing.

### 2. Summarize

From the diffs (not from memory), write a short summary:

- Branch
- Files (path, staged / unstaged / untracked)
- What the change does, in a few sentences
- Anything that looks like a secret (`.env`, credentials, private keys) — exclude those from the proposed add list unless the user explicitly includes them

Do not dump the raw diff.

### 3. Draft the message

Fill the template from step 2. Show the user:

1. The summary
2. The proposed `git add` paths
3. The exact commit message as it would be passed to `git commit`

Ask with `ask_user_question`: **accept and commit** / **edit the message** / **change the file list** / **abort**.

- **edit the message** — revise until they accept. Do not commit in between.
- **change the file list** — update the add list, revise the summary/message if needed, ask again.
- **abort** — stop. Do not stage or commit.

### 4. Commit

Only after **accept and commit**:

```bash
git add -- <accepted paths>
```

Write the accepted message to a temp file (exact bytes, no extra commentary). Then:

```bash
git commit -F <temp-file>
git log -1 --stat
```

Do not pass `--no-verify` unless the user asks. If a hook rejects the commit, show the output and stop.

Delete the temp file.

### 5. Tag

After a successful commit, ask with `ask_user_question` whether to tag this commit.

- **No** — stop.
- **Yes** — ask for the tag name (required) and an optional annotation. Create an annotated tag:

```bash
git tag -a <name> -m "<annotation or the commit subject>"
git tag -l <name>
```

Do not overwrite an existing tag. Do not push the tag.

## Rules

- Local only. Never `git push`, never `git push --tags`.
- Never commit without an explicit accept of both the summary and the message.
- Never `git add` paths the user did not accept.
- Never update git config.
- Do not amend unless the user later asks to amend.
