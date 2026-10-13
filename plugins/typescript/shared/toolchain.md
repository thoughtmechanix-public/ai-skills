# TypeScript toolchain

How skills in this plugin detect and run tools. Do not hard-code a second stack in a skill. Greenfield compiler options live in `../skills/typescript/organization.md`.

## Package manager

Use the package root that owns the files you are changing (nearest `package.json`; in a workspace, that package).

| Lockfile | Manager | Script | Exec |
|---|---|---|---|
| `pnpm-lock.yaml` | pnpm | `pnpm run <script>` | `pnpm exec` |
| `bun.lock` or `bun.lockb` | bun | `bun run <script>` | `bunx` |
| `yarn.lock` | yarn | `yarn <script>` | `yarn exec` |
| `package-lock.json`, or none | npm | `npm run <script>` | `npx --no-install` |

If several lockfiles exist, use the one the repo documents. Otherwise prefer pnpm, then bun, then yarn, then npm.

## Formatter

Walk from the file toward the package root.

1. `biome.json` or `biome.jsonc`, and `biome` on `PATH` or in `node_modules/.bin` → `biome format --write <file>` (check: `biome format <file>`).
2. A Prettier config (`.prettierrc`, `.prettierrc.*`, `prettier.config.*`, or a `"prettier"` key in `package.json`) and `prettier` available → `prettier --write <file>` (check: `prettier --check <file>`).
3. If only one of those binaries exists, use it.
4. If neither exists, skip. Do not add a formatter unless a scaffold skill is creating the package.

The `PostToolUse` hook `hooks/bin/format-after-edit.sh` implements this for `.ts`, `.tsx`, `.mts`, and `.cts`.

## Typecheck

Run the package script `typecheck` when it exists. Otherwise `tsc --noEmit -p <tsconfig>` for the config that covers the changed files.

## Lint

1. Package script `lint` when it exists.
2. Else a Biome config → `biome check <paths>`.
3. Else an ESLint config (`eslint.config.js`, `eslint.config.mjs`, `eslint.config.ts`, `eslint.config.cjs`, `.eslintrc`, `.eslintrc.*`) → ESLint on those paths.
4. Else record `no linter configured` and still run typecheck.

A lint artifact that omits typecheck is not a pass. Typecheck failures are lint findings.

## Tests

- Unit: `*.test.ts` and `*.test.tsx`, excluding `*.integration.test.ts` and `*.integration.test.tsx`.
- Integration: `*.integration.test.ts` and `*.integration.test.tsx`.

Run the package scripts `test` and `test:integration` when they exist. Otherwise:

- `vitest` dependency → `vitest run` for unit files, and `vitest run` limited to integration files.
- `jest` dependency → the repo's Jest command, with integration files selected by path.
- Otherwise → `node --test --experimental-strip-types` on the unit files, then the same on the integration files.

Do not add a test framework the package does not already depend on. `new-typescript-cli` and `new-typescript-service` are the exception: they scaffold `node:test`.

## Coverage

**Touched package:** a workspace package, or the only package, that contains a changed non-test `.ts` or `.tsx` file.

**Bar:** 80% statements on each touched package. Do not average packages together. A new exported function at 0% line coverage fails even when the package is otherwise above 80%.

Produce text output:

1. Package script `test:coverage` when it exists.
2. Else Vitest → `vitest run --coverage`, using the repo's coverage provider. If the provider is not installed, write that fact. Do not invent a percentage.
3. Else Jest → `jest --coverage`.
4. Else Node → `node --test --experimental-strip-types --experimental-test-coverage` on the unit files.

The report must list each touched package's statement percentage. A repo-wide total alone is not a measurement.

## Measure procedure

`/typescript-implement-stage` runs this from the implementer worktree. Write `<lint_file>` and `<coverage_file>`. Do not edit source to make it pass.

1. List changed and untracked `*.ts`, `*.tsx`, `*.mts`, `*.cts` with `git status --porcelain`.
2. Map those files to touched packages.
3. Append the formatter check, Lint, and Typecheck commands and their output to `<lint_file>`.
4. Run unit tests with coverage, then integration tests. Write the commands and output to `<coverage_file>`.
5. If no `package.json` or no `tsconfig` covers the changes, write that fact into both files.

## Greenfield lint and format

Only `new-typescript-cli` and `new-typescript-service` add this, and only in a package they are creating.

Dev dependencies: `typescript`, `@types/node`, `eslint`, `@eslint/js`, `typescript-eslint`, `prettier`.

`.prettierrc.json`:

```json
{}
```

`eslint.config.js`:

```js
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  { ignores: ["dist/**"] },
  eslint.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
);
```

`package.json` scripts:

| Script | Command |
|---|---|
| `typecheck` | `tsc --noEmit` |
| `lint` | `eslint .` |
| `test` | `node --experimental-strip-types --test $(find src -type f \( -name '*.test.ts' -o -name '*.test.tsx' \) ! -name '*.integration.test.ts' ! -name '*.integration.test.tsx')` |
| `test:integration` | `node --experimental-strip-types --test $(find src -type f \( -name '*.integration.test.ts' -o -name '*.integration.test.tsx' \))` |
| `test:coverage` | `node --experimental-strip-types --test --experimental-test-coverage $(find src -type f \( -name '*.test.ts' -o -name '*.test.tsx' \) ! -name '*.integration.test.ts' ! -name '*.integration.test.tsx')` |
| `build` | `tsc` |
| `format` | `prettier --write .` |

`*.integration.test.ts` also matches `*.test.ts`. The `find` exclusions keep integration tests out of `test` and `test:coverage`.
