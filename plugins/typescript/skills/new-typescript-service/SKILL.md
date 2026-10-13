---
name: new-typescript-service
description: >
  Scaffold a new TypeScript HTTP service on node:http with a strict tsconfig,
  JSON logs, env config, graceful shutdown, and unit plus integration tests.
  Use when the user wants a new TypeScript service or runs
  /new-typescript-service.
disable-model-invocation: true
---

Scaffold a new TypeScript HTTP service. Ask for the service name and the resource it manages if they were not given. Finish each step before the next.

Compiler flags: the greenfield `tsconfig` in `../typescript/organization.md`. Lint, Prettier, and scripts: the greenfield section of `../../shared/toolchain.md`. Tests: `../typescript/testing.md`. Errors: `../typescript/errors.md`. Async shutdown: `../typescript/async.md`.

## Layout

1. `mkdir -p <name> && cd <name>`.
2. Create:
   - `src/main.ts` — read config, construct the store, listen, shut down on SIGINT and SIGTERM.
   - `src/server.ts` — `createServer(store)` returns `http.Server`. No listen call here.
   - `src/<resource>.ts` — a store class and the route handlers. No module-level map.
   - `src/config.ts` — env config with defaults. Fail in `main` when a required variable is missing.
   - `src/logging.ts` — JSON log lines on stdout (`level`, `time`, `msg`).
3. `package.json`: `"type": "module"`, `"engines": { "node": ">=22" }`, greenfield dev dependencies and scripts from `toolchain.md`. No web framework. Runtime dependencies only if a step below needs one (it should not).

## HTTP

4. Use `node:http`. Routes, with `<resource>` pluralized as the user named it:
   - `GET /api/<resource>` — list
   - `POST /api/<resource>` — create
   - `GET /api/<resource>/<id>` — one
   - `DELETE /api/<resource>/<id>` — delete
5. Keep records on the store instance. Tests construct their own store. Do not share a module-level collection.
6. Set `Content-Type: application/json; charset=utf-8` before writing a body. Error body is `{"error":"<message>"}`. Unknown routes and unknown ids are 404. Invalid JSON is 400. A body over 1 MiB is 413.
7. Generate ids with `crypto.randomUUID()`.

## Lifecycle

8. In `src/main.ts`, listen on the configured port (default a specific port you document, overridable by env). On SIGINT and SIGTERM call `server.close()`. Force-exit if close does not finish within 10 seconds. Log the listen and the shutdown. Do not `process.exit` on a request-path error.

## Tests and gates

9. `src/<resource>.test.ts` — table tests for create, list, get, delete, missing id, and invalid input, calling the store or an `http` request against `createServer` without binding a public port when `server.listen(0)` is enough.
10. `src/server.integration.test.ts` — start on port 0, `fetch` the success and 404 paths, close the server in `t.after`.
11. Install, then run `typecheck`, `lint`, `test`, `test:integration`, and `build`. Fix and re-run until all pass.
12. Start `node dist/main.js`, request `GET /api/<resource>`, then stop it with SIGTERM and confirm the process exits.

Do not add a third-party router, ORM, or logger.
