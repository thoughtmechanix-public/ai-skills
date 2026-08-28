---
name: new-go-service
description: Scaffold a new Go HTTP service using our standard layout,
  stack, and idioms. Use only when explicitly invoked.
disable-model-invocation: true
allowed-tools: Bash(go *) Bash(mkdir *) Bash(curl *)
---

Scaffold a new Go HTTP service. Ask for the service name and the resource it
manages if they were not given, then follow these steps in order.

## Layout

1. Create the service root and work inside it for every later step:
   `mkdir -p <name> && cd <name>`. Every command below runs from there.
2. Create `cmd/<name>/` and `internal/<resource>/`.
3. Initialize the module with `go mod init <name>`.

## Stack and idioms

4. Route with the standard library `net/http` using method patterns.
   Mount the collection at `/api/<resource>` and individual items at
   `/api/<resource>/{id}`, so a todos service serves `GET /api/todos`.
   Do not add a third-party router.
5. Keep state in a struct with methods. No package-level mutable state.
   Protect shared maps with a `sync.RWMutex`.
6. Log with `log/slog` to stdout using the JSON handler. No `fmt.Println`
   and no `log.Fatal` outside `main`.
7. Read configuration from the environment with sensible defaults, and
   fail fast with a clear message when something required is missing.
8. Give every handler a JSON error shape of {"error": "message"} and set
   Content-Type before writing the body.

## Lifecycle

9. In `cmd/<name>/main.go`, build the server, then shut it down gracefully:
   use `signal.NotifyContext` for SIGINT and SIGTERM and call
   `srv.Shutdown(ctx)` with a timeout.

## Tests and gates

10. Write table-driven tests with `net/http/httptest` covering the success
    and the error path of every handler. Use subtests with descriptive names.
11. Add a Makefile with `test`, `vet`, and `lint` targets.
12. Run `go vet ./...` and `go test -race ./...`. If either fails, fix it and
    run again until both are clean.
13. Start the server, confirm it answers, then stop it.

Do not proceed to the next step until the current step is complete.
