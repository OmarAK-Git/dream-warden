# demo-feature-001 — Final Report

## What was built
- Added `timeout_s: float = 10.0` to `http_client.get()` and `http_client.post()`.
  Both methods now pass the value to `requests.Session.request()` as the `timeout`
  argument (connect and read timeout are set to the same value for simplicity).
- Implemented `CircuitBreaker` in `http_client/circuit_breaker.py`:
  - States: CLOSED (normal), OPEN (fast-fail), HALF_OPEN (probe).
  - Opens after `failure_threshold` (default 5) consecutive failures.
  - Resets to CLOSED after `reset_timeout_s` (default 60) seconds without a failure
    in HALF_OPEN state.
- `CircuitOpenError` raised when the circuit is OPEN; callers can catch it to return
  a cached or degraded response.

## Key decisions
- Connect and read timeouts are unified into a single `timeout_s` parameter.
  This was a conscious simplification; the caller cannot set them independently
  in this version. Documented in `docs/adr/adr-007-timeout.md`.
- The circuit breaker is in-process only (no Redis or shared state). Adequate for
  the current single-worker deployment; revisit if horizontally scaled.

## Files changed
- `http_client/__init__.py` — added `timeout_s` parameter
- `http_client/circuit_breaker.py` — new file
- `tests/unit/test_http_client.py` — extended
- `tests/unit/test_circuit_breaker.py` — new file
- `docs/adr/adr-007-timeout.md` — decision record
