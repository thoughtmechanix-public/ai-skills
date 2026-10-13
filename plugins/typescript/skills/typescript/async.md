# TypeScript — Async

Loaded by `SKILL.md` when the user is writing or reviewing promises, `async` functions, timers, or concurrent I/O.

Every promise has an owner. If you cannot say who handles its rejection, do not start it.

## Modes

**Coding.** Start the shutdown path first when work outlives the request: accept an `AbortSignal`, and pass it into every I/O call that supports it.

**Review.** Floating promises, `async` functions with no `await`, sequential `await` in a loop over independent work, missing `AbortSignal` on new I/O, and `setTimeout` / `setInterval` with no clear on abort.

**Audit.** Up to three sub-agents: floating promises (including `arr.forEach(async ...)`); timers and listeners with no teardown; `Promise.all` over unbounded input.

## Rules

1. `await` the promise, return it, or attach `.catch`. `void promise` is allowed only when the next expression handles rejection (a function named for fire-and-forget that itself catches). A bare `void save()` to silence the checker is a floating promise.
2. Do not use `forEach`, `map`, or `filter` with an `async` callback to do sequential or concurrent work. Use a `for...of` loop when order matters, or `Promise.all` / a limited pool when it does not.
3. `Promise.all` fails fast. `Promise.allSettled` is for "collect every result, including failures." Do not use `allSettled` and then ignore the rejected entries.
4. Pass `AbortSignal` into `fetch`, database clients, and child processes when the caller can cancel. Check `signal.aborted` before starting a chunk of work that cannot be cancelled.
5. Clear timers and remove listeners in the same block that registered them, on both success and abort (`finally` or an abort listener).
6. Do not mark a function `async` when it does not `await`. Return the promise you already have.
7. Do not put `async` work in a constructor. Export an async factory.
8. Cap fan-out. A `Promise.all` over an API list needs a concurrency limit when the list can be large.
9. `await` in a loop is correct when the next step depends on the previous one or you need backpressure. Do not "optimize" that into `Promise.all` without saying why order stopped mattering.
10. Treat an unhandled rejection as a bug, not as logging configuration.

## Decision

| Situation | Use |
|---|---|
| Independent I/O, fail on first error | `Promise.all` |
| Independent I/O, need every outcome | `Promise.allSettled` |
| Order matters, or shared mutable state | `for...of` with `await` |
| Caller may leave | `AbortSignal` through the I/O |
| Many more items than you can run at once | A pool with a fixed limit |

## Anti-patterns

| Smell | What to do |
|---|---|
| `items.forEach(async (item) => { ... })` | `for...of` or `Promise.all(items.map(...))` |
| `void fetch(url)` with no catch | `await` it, or handle the rejection in a named helper |
| `setInterval` in a request handler | Start it in the process owner and clear it on shutdown |
| Catch-all that swallows `AbortError` and real errors | Branch on abort vs failure (`errors.md`) |
| Sequential `await` over unrelated hosts, "to be safe" | `Promise.all` unless order is a requirement |

## See also

- `errors.md` — rejections and abort
- `testing.md` — fake timers, no `setTimeout` sleeps in tests
- `debugging.md` — unhandled rejections and hung processes
