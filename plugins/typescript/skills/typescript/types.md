# TypeScript — Types

Loaded by `SKILL.md` when the user is designing or reviewing types.

Prefer a narrow type at the boundary and a plain type in the rest of the program. Do not make the caller parse what the callee already knew.

## Modes

**Coding.** Model each alternative as a union member with a literal tag (`kind`, `type`, or `status`). Parse untrusted input (`JSON`, `env`, `FormData`, query strings) into that union before the rest of the code sees it. If the repo already depends on a parser (Zod, Valibot, ArkType, Typia), use it. If it does not, write a type guard or a parse function that returns the union. Do not add a parser dependency for one call site.

**Review.** Look for `any`, `as` that skips a check, `!`, `Function` / `Object` / `{}`, and exported types that are wider than the values the module actually produces.

**Audit.** Up to three sub-agents:

1. **Escape hatches** — `any`, `as any`, `@ts-ignore`, `@ts-expect-error` without an explanation, and `!`.
2. **Boundary parsing** — `JSON.parse`, `await response.json()`, and `process.env` reads whose result is used without a parse or a guard.
3. **Public surface** — types and functions exported from the package entry that leak a class, a third-party type, or a bag of optional fields where a union would do.

## Rules

1. `unknown` is the input type until a guard or parser narrows it. `any` is not a boundary type.
2. Discriminate unions with a literal tag. Do not use a boolean plus optional fields to mean two different states.
3. `interface` for an object shape that is extended or implemented. `type` for unions, intersections, tuples, and mapped types.
4. Prefer a string-literal union, or a `const` object plus `typeof` lookup, over a numeric `enum`. A string `enum` is acceptable only when the repo already uses that pattern.
5. Accept the smallest structural type the function uses. Return a specific type, not a class instance, unless the class is the contract.
6. Put `readonly` on data the function must not mutate. Treat an index read as possibly missing unless the type already excludes that (`noUncheckedIndexedAccess` in `organization.md`).
7. Constrain generics. A function generic that is only `T` with no use in a parameter is `any` with extra steps. Do not default a type parameter to `any`.
8. Use `satisfies` when a value must be checked against a type and still keep its literal inference (config objects, route maps).
9. Use `import type` for type-only imports when `verbatimModuleSyntax` is on.
10. Brand an id (`UserId`) only when two string ids are easy to swap. Do not brand every primitive.
11. Do not export a type that only this package constructs unless callers must name it.
12. A type assertion is allowed after a check the compiler cannot see. The next line must be that check, or a comment that names the invariant.

## Anti-patterns

| Smell | What to do |
|---|---|
| `any` parameter or return | Name the type, or use `unknown` and narrow |
| `value as SomeType` on input | Parse or guard, then use the narrowed value |
| `value!` because the checker complained | Narrow, or change the type so absence is visible |
| `Record<string, any>` config | A named type, parsed at the edge |
| Optional fields that are present only in one state | A discriminated union |
| Generic helper used once | Inline it |
| Public function returns the storage class | Return the data type callers need |

## See also

- `errors.md` — typed failures
- `organization.md` — where the public types are exported
- `testing.md` — tests take the public type, not a cast to reach internals
