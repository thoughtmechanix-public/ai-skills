# TypeScript — Code organization

Loaded by `SKILL.md` when the user is placing code, editing `tsconfig`, or reviewing module boundaries.

Match the structure the repo already has. Add a folder when a boundary is real, not before.

## Modes

**Coding.** New code goes next to the feature it serves. The process entry (`src/cli.ts`, `src/main.ts`, or the existing bin) wires dependencies and does not contain business rules.

**Review.** New cycles, a new root `index.ts` that re-exports every module, logic added to the entry file, and a second config mechanism beside the one the repo uses.

**Audit.** Up to three sub-agents: import cycles; modules that both talk to the network and implement domain rules; `tsconfig` flags below the repo's own strictness.

## Rules

1. Follow the package's existing file names. In a new package, module files are kebab-case (`load-config.ts`).
2. Colocate tests: `load-config.test.ts`, `load-config.integration.test.ts` (`../../shared/toolchain.md`).
3. The public surface of a package is `package.json` `"exports"`. Export from that entry what callers need. Do not add a barrel that exists only to shorten imports inside the same package.
4. One concern per module. A file that fetches, parses, and renders is three modules once any of those needs its own test.
5. No circular imports. If two modules need each other, pull the shared type into a third module that imports neither.
6. Do not put business logic in `src/cli.ts` or `src/main.ts`. Those files read config, construct the graph, and start or stop the process.
7. Inside a package, import by relative path. Use a path alias only when the repo already defined one.
8. Do not add a second tsconfig, bundler, or package manager beside the one the repo uses.
9. Named exports. A default export is for a framework file that requires one.
10. Dependencies point inward: entry → application → domain. The domain module does not import the server or the CLI parser.

## Greenfield compiler options

Used when a scaffold skill creates a package, and as the checklist when a standards audit finds a new `tsconfig` with no local standard. Do not "upgrade" an existing repo to this list as a drive-by.

```json
{
  "compilerOptions": {
    "target": "ES2023",
    "module": "Node16",
    "moduleResolution": "Node16",
    "lib": ["ES2023"],
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "declaration": true,
    "sourceMap": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

`"type": "module"` in `package.json`. Engines: Node 22 or newer.

## Greenfield layout

CLI and HTTP packages from the scaffold skills:

```
src/cli.ts                 CLI entry only
src/main.ts                HTTP entry only
src/<feature>.ts           domain and I/O wrappers
src/<feature>.test.ts
src/<feature>.integration.test.ts
```

A library package uses the same `src/` rules and no `main.ts` unless it is also a program.

## Anti-patterns

| Smell | What to do |
|---|---|
| `src/index.ts` re-exports every file, and features import from it | Features import the module they use; `exports` stays the public entry |
| `utils.ts` or `helpers.ts` that grows without a domain | Name the module for the job (`format-duration.ts`) |
| Shared mutable `let` at module scope | Pass state into a function, or keep it on an object the entry constructs |
| Path alias added for one import | Relative import |
| New package dropped at the repo root of a workspace | The workspace's existing package location |

## See also

- `types.md` — what the public entry should export
- `testing.md` — test file placement
- `../../shared/toolchain.md` — lint, test, and coverage commands
