# Commit message template

The `/git-commit` skill fills this shape. Edit this file to change the format.
Do not put extra sections in the commit that are not named here.
Delete a section from this file to stop using it.

A workspace file `<repo>/.grok/commit-message.md` overrides this default.

## Subject (required)

One line. Imperative mood ("Add", "Fix", "Remove"). About 50 characters. No trailing period.

## Body (required)

Why the change exists. Then what changed, if that is not obvious from the subject.
Wrap at 72 characters. Do not paste `git status`.

## Footer (optional)

Use for `BREAKING CHANGE:`, `Closes #N`, or trailers the project already uses.
Omit this section when empty.
