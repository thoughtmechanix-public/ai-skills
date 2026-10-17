# TypeScript — Errors

Loaded by `SKILL.md` when the user is writing or reviewing failure paths.

Handle each failure once. Either recover, or add context and let it propagate. Do not log it and also rethrow the same error with no new context.

## Modes

**Coding.** Pick one policy per module and use it everywhere in that module:

- **Throw** a subclass of `Error` for failures the caller did not ask to inspect field-by-field. Set `cause` when wrapping. Put a stable string `code` on the subclass when callers branch on the failure.
- **Return a result** (`{ ok: true; value: T } | { ok: false; error: E }`) when the failure is a normal outcome the caller must handle in line (validation, parse). Use this when the repo already uses results.

Do not mix both for the same function. Do not return `null` for a failure that has a reason, unless absence is the only fact.

**Review.** On the diff: empty `catch`, `catch (e)` used as `any`, `as Error`, thrown strings, and `error.message` comparisons.

**Audit.** Up to four sub-agents: empty catches; thrown non-Errors; message-string matching; log-and-rethrow of the same error.

## Rules

1. With `useUnknownInCatchVariables` (on under `strict`), a catch binding is `unknown`. Narrow with `instanceof Error` or a custom guard before reading fields.
2. Throw `Error` or a subclass. Do not throw a string or a plain object.
3. Wrap with `cause`. Do not stringify the inner error into the outer message and drop the chain.
4. Branch on a `code` or on `instanceof`, not on `error.message`.
5. `AbortError` / `DOMException` name `AbortError` is cancellation. Do not log it as an application failure.
6. At a process or HTTP boundary, map the error to a stable public shape. Do not send `stack` or an internal message to the client. Log the full error on the server side of that boundary.
7. An empty `catch` is a bug. If the ignore is deliberate, catch the specific type and comment why.
8. `log.Fatal` has no TypeScript equivalent worth adding. A library function throws or returns. Only the entry file exits the process.
9. Do not `as Error` to satisfy a type. Narrow.
10. User-facing text is chosen at the boundary. Internal messages can name the operation (`read config`) and stay stable; put ids and paths in structured fields, not only in the sentence.

## Subclass shape

```ts
export class ConfigError extends Error {
  readonly code = "config";
  constructor(message: string, options?: ErrorOptions) {
    super(message, options);
    this.name = "ConfigError";
  }
}
```

Repeat that shape for each code the caller must distinguish. A single `AppError` with a `code` union is the right collapse when there are many codes and one handling site.

## Anti-patterns

| Smell | What to do |
|---|---|
| `catch { }` | Catch a specific failure and handle it, or let it propagate |
| `catch (e) { throw new Error(String(e)) }` | `throw new OuterError("context", { cause: e })` after narrowing, or rethrow `e` |
| `if (error.message === "not found")` | `code` or `instanceof` |
| Log inside the helper and throw the same error | Log at the boundary, or throw with `cause` and let the boundary log |
| `error as Error` | `instanceof` guard |

## See also

- `async.md` — rejection and `AbortSignal`
- `types.md` — result unions
- `testing.md` — assert `code` or `instanceof`, not message text, unless the message is the contract
