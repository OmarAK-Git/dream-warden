# demo-feature-001 — Traceability

## Requirements satisfied
- REQ-HTTP-004: "The HTTP client must not block a worker thread for more than N seconds
  on any single request." Satisfied by the `timeout_s` parameter.
- REQ-HTTP-007: "Repeated failures to an upstream must not cascade into full pool
  exhaustion." Satisfied by the circuit breaker.

## Decisions recorded
- ADR-007 (`docs/adr/adr-007-timeout.md`): unified connect+read timeout chosen over
  separate parameters for simplicity; revisit if callers need fine-grained control.

## Open items deferred
- Retry logic (exponential backoff) → next task.
- Distributed circuit-breaker state (Redis) → deferred until horizontal scaling needed.
