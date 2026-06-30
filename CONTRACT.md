# dream-warden Input Contract

This document defines the seam between your project's task workflow and the
dream-warden consolidation engine. Wire up this contract and the engine can
synthesize durable playbook entries from any completed task.

---

## 1. Task directory layout

Every completed task must live at:

```
<repo-root>/.workflow/<slug>/
```

where `<slug>` is a short stable identifier for the task (e.g. `feature-oauth`,
`bugfix-timeout`, `refactor-db-layer`). This is also the value passed to
`--slug` when enqueueing manually.

---

## 2. Required input files

The consolidation engine reads up to six files from the slug directory. Provide
as many as your workflow generates; missing files are silently skipped (but
`final-report.md` + at least one other should always be present).

| File | Purpose | What it feeds |
|------|---------|---------------|
| `state.json` | Machine-readable status; must contain `{"status": "complete"}` for auto-enqueue to proceed without `--allow-incomplete` | Completion gate |
| `plan.md` | The original task plan / acceptance criteria | Scope and intent context |
| `final-report.md` | Outcome summary — what was built, what changed | Primary synthesis source |
| `verification.md` | Test results, type-check output, lint results | Evidence backing for entries |
| `traceability.md` | Requirement / decision links | Cross-reference context |
| `review.md` | Human review notes, open questions, post-mortem | Gotchas and lessons |

Configure which files are read in `bin/dream_lib.py` (`SLUG_FILES` and
`LEAN_SLUG_FILES` constants).

---

## 3. The "task is complete" signal

`consolidate.py` reads `state.json` and checks for `status == "complete"` before
synthesizing. Use `--allow-incomplete` to bypass this check (e.g. for dry-runs
against the example task or for tasks that predate the status field).

---

## 4. Section taxonomy

| Section title | Prefix | Meaning (DR = Domain Rules) |
|---------------|--------|---------------------------|
| General Rules | `GR` | Process / working-agreement rules that hold across all tasks |
| Architecture Gotchas | `AG` | Non-obvious structural traps, init-order hazards, hidden producer-consumer contracts |
| Domain Rules | `DR` | Project-specific behavioral constraints, business-logic invariants, or compliance rules |
| Verified Snippets | `VS` | Commands or patterns proven by a verbatim run, worth copy-pasting on the next task |

**DR — Domain Rules** is the section for rules specific to your project's domain.
Rename the section title in `bin/dream_lib.py` (`SECTIONS` constant) if your project
uses different terminology (e.g. "API Contract Rules", "Security Invariants").

AG and DR entries carry a `scope=` attribute for differential loading. Configure
the scope vocabulary in `bin/dream_lib.py` (`SCOPES` constant).

---

## 5. Entry format

```
<!-- entry id=GR-0001 source=demo-feature-001 sha=synth01 status=active -->
- **GR-0001** - <insight text> _(demo-feature-001 @synth01)_

<!-- entry id=AG-0003 source=feature-oauth sha=synth02 status=active scope=auth,api -->
- **AG-0003** - <insight text> _(feature-oauth @synth02)_
```

The HTML marker is the contract; the bullet is for humans. Never hand-edit markers —
use the dream loop so provenance and the conservation invariant stay intact.

---

## 6. dream_dir() resolution

The engine locates its working directory (playbook, queue, proposals, ledger) via
`dream_dir()` in `bin/dream_lib.py`. Two modes — **must be declared, not inferred**:

| Mode | How to declare | Resolved path |
|------|---------------|---------------|
| **installed** | Copy dream-warden to `<project>/.workflow/_dream/` | `<project>/.workflow/_dream/` |
| **standalone** | Set `DREAM_WARDEN_STANDALONE=1` env var, or create `.dream-standalone` at repo root | repo root |

If neither signal is present, `dream_dir()` raises immediately with a message naming
both options. This is intentional — silent path guessing is a hidden-divergence hazard.

---

## 7. The consolidate.py synthesis seam

The single call to the Claude CLI in `bin/dream_lib.py::run_claude_json()` is the
**only site** that must change to swap from the local `claude -p` invocation to a
managed Anthropic Dreams API call (if/when one becomes available):

```python
# Current local call (dream_lib.py):
cmd = [claude_executable(), "-p", "--output-format", "json", ...]

# Future managed call would replace this with dreams.create(...) or equivalent.
```

Everything else — parsing, conservation checking, atomic write, ledger, approval —
is API-agnostic and requires no changes.

---

## 8. Example task

See `example/demo-feature-001/` for a fully fictional sample showing the expected
file shapes. The operational copy used for dry-runs lives at
`.workflow/demo-feature-001/`.

Dry-run command (standalone mode):

```sh
DREAM_WARDEN_STANDALONE=1 python bin/consolidate.py \
  --slug demo-feature-001 --sha synth01 --allow-incomplete
```
