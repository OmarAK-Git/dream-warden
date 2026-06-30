# demo-feature-001 — Verification

## Test suite

```
pytest tests/unit/test_http_client.py tests/unit/test_circuit_breaker.py -v
```

Results: 3 passed, 0 failed (fictional; this is a synthetic example)

## Type checking

```
mypy --strict http_client/ tests/unit/test_http_client.py tests/unit/test_circuit_breaker.py
```

Result: Success: no issues found in 4 source files

## Lint

```
ruff check http_client/ tests/unit/test_http_client.py tests/unit/test_circuit_breaker.py
```

Result: All checks passed.

## Manual smoke test

Pointed the client at a local netcat listener set to hang indefinitely:
```sh
nc -l 8888 &
python -c "from http_client import get; get('http://localhost:8888/', timeout_s=2.0)"
```
Confirmed `requests.exceptions.Timeout` raised after ~2 seconds.

Circuit breaker: manually triggered 5 consecutive failures against a mock that
raises `ConnectionError`. Confirmed `CircuitOpenError` on the 6th call, and
that the circuit reset to HALF_OPEN after 60s in the test.
