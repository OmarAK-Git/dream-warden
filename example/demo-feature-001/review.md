# demo-feature-001 — Review

## Reviewer notes (fictional)

Overall: ACCEPTED. The implementation is clean and the circuit breaker is
well-tested. A few observations for the playbook:

1. **Timeout is an architectural contract, not just a parameter.** Adding `timeout_s`
   touched every call site that uses the HTTP client — there were more than expected
   (12 across 4 modules). Future tasks adding parameters to widely-used primitives
   should budget time for a call-site audit upfront.

2. **In-process state is a silent assumption.** The circuit breaker's failure counter
   resets on process restart. This is acceptable now but will become a latent issue
   if we horizontally scale before documenting the constraint. Added a note to the ADR
   but worth a General Rule about in-process-only state assumptions.

3. **The smoke test was essential.** The unit tests mocked `requests.Session`; the
   smoke test caught that the timeout was being passed as `(timeout_s, timeout_s)`
   instead of just `timeout_s` (requests accepts either a float or a (connect, read)
   tuple, and the test mock accepted both). Fixed before merge.

## Status: COMPLETE
