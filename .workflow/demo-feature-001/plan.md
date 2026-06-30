# demo-feature-001 — Plan

## Goal
Add a configurable connect+read timeout and a simple circuit-breaker to the
`http_client` module so that slow or unresponsive upstream services cannot block
the worker thread pool indefinitely.

## Acceptance criteria
1. `http_client.get()` and `http_client.post()` accept a `timeout_s: float` keyword
   argument (default 10.0).
2. A `CircuitBreaker` class wraps the client; after N consecutive failures it
   opens and raises `CircuitOpenError` without making a network call.
3. All existing HTTP client tests pass. New unit tests cover: timeout enforcement,
   circuit opens after threshold, circuit resets after cool-down.
4. `mypy --strict` and `ruff` clean on changed files.

## Out of scope
- Retry logic (separate task).
- Persistent circuit-breaker state across processes.
