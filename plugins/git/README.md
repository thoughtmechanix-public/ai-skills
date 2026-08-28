# git

Git workflow skills and a force-push guard.

## Skills

| Skill | Role |
|---|---|
| `git-commit` | Scan changes, draft a message from the template, commit locally after accept, then offer a tag |
| `git-prepare-pr` | Push the branch and open a GitHub PR from the commit messages, after the user accepts |

Templates (edit these, not `SKILL.md`):

| Skill | Default | Workspace override |
|---|---|---|
| `git-commit` | `skills/git-commit/references/commit-message.md` | `<repo>/.grok/commit-message.md` |
| `git-prepare-pr` | `skills/git-prepare-pr/references/pr.md` | `<repo>/.grok/pr.md` |

## Hooks

`PreToolUse` on shell commands denies `git push --force` / `git push -f` when the command also names `main` or `master`. `--force-with-lease` is allowed.
