# Pull request template

The `/git-prepare-pr` skill fills this shape. Edit this file to change the format.
Do not put extra sections in the PR that are not named here.
Delete a section from this file to stop using it.

A workspace file `<repo>/.grok/pr.md` overrides this default.

The **Title** line is the GitHub PR title. Every other filled section is the PR body.

## Title (required)

One line. Imperative or summary of the branch. About 70 characters.

## Summary (required)

Why this change exists and what a reviewer should know. Start from the commit messages; do not paste `git log` raw.

## Test plan (required)

How a reviewer can verify the change. Concrete steps or commands.

## Footer (optional)

Use for `BREAKING CHANGE:`, `Closes #N`, or trailers the project already uses.
Omit this section when empty.
