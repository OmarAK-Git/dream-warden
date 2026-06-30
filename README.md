# dream-warden

An unofficial, local reimplementation of the **pattern** behind Anthropic's
Managed Agents "Dreams" feature — built to run locally today, until a local
Dreams ships (if it ever does).

> **Not affiliated with or endorsed by Anthropic.** This project is an
> independent implementation of the memory-consolidation pattern described in
> Anthropic's agent research. The `claude` CLI is used as a local synthesis
> engine; no Managed Agents API is required.

---

## What it does

dream-warden turns completed task artifacts into a curated long-term
**playbook** — a structured markdown file of durable, reusable engineering
insights. It runs out-of-band via a post-commit hook and never touches your
source code, tests, or migrations.

### Pipeline

```
commit ──▶ post-commit hook ──▶ queue/            (enqueue {slug, sha}; no synthesis)
                                   │
                consolidate.py ◀───┘  reads playbook.md (read-only) + slug files
                       │              calls Claude headless (tool-less, json-schema)
                       ▼
               proposals/<ts>-<slug>.md            (OUTPUT store; atomic write)
                       │
            conservation_check.py                  (independent gate; nonzero on violation)
                       │
                  approve.py  (you)  ──▶ playbook.md (atomic promote) + ledger/ + commit

# Compaction (periodic; no slug required):
                compaction.py ──▶ proposals/<ts>-compaction.md  ──▶ approve.py
                  (reads full playbook; proposes supersessions for near-duplicates;
                   same conservation gate + human approval; no new entries created)
```

---

## Review-gate philosophy

The synthesis model is **untrusted**. It runs with `--tools ""` (no repo access)
and may only *suggest* additive entries. `consolidate.py` copies every existing
entry **verbatim** and only appends — the model cannot drop or rewrite an entry.
`conservation_check.py` then proves conservation independently. Nothing enters
`playbook.md` until **you** run `approve.py`.

The review gate is the mitigation for memory poisoning.

---

## Conservation guarantee (deterministic, enforced in code)

Every existing playbook entry must end up **retained**, **superseded-by** a new
entry, or **merged-into** one — never silently dropped or duplicated. Every new
entry carries provenance (source slug + commit SHA). `conservation_check.py`
exits nonzero on any violation or a missing completion marker.

This is **conservation-by-construction**: the model emits candidates only; code
copies existing entries verbatim and appends new ones. The checker verifies the
result independently. The model physically cannot drop an entry.

---

## Advisory vs. enforced counts

- **Enforced (conservation check):** entry IDs — every ID in the current playbook
  must appear in every proposal, with a valid disposition. Exit 1 on any drop.
- **Advisory (stale-count warning):** test-count claims in entry text (e.g.
  "17 passed"). `approve.py` warns when it detects these but does not block
  approval. The human reviewer is responsible for verifying them before approving.

---

## Setup

### Requirements

- Python 3.11+
- The `claude` CLI, authenticated (`claude login`)

### Install into a project

```sh
# from your project root:
mkdir -p .workflow
cp -r /path/to/dream-warden .workflow/_dream
.workflow/_dream/install-hook.sh
```

Or clone directly:

```sh
git clone https://github.com/<your-user>/dream-warden .workflow/_dream
.workflow/_dream/install-hook.sh
```

### Standalone mode (development / dry-run)

When running dream-warden as its own repo (not inside a project), declare
standalone mode via env var or marker file:

```sh
# env var (per-invocation):
DREAM_WARDEN_STANDALONE=1 python bin/consolidate.py --slug demo-feature-001 --sha synth01

# or create the marker file once (committed in this repo by default):
touch .dream-standalone
python bin/consolidate.py --slug demo-feature-001 --sha synth01
```

See `CONTRACT.md` §6 for the full `dream_dir()` resolution rules.

---

## Input contract

See `CONTRACT.md` for the full specification. Short version: complete a task,
write its output files to `.workflow/<slug>/`, commit — the hook enqueues it.

The six expected files per task:

| File | Role |
|------|------|
| `state.json` | Completion signal (`{"status": "complete"}`) |
| `plan.md` | Task plan / acceptance criteria |
| `final-report.md` | Outcome summary |
| `verification.md` | Test / lint / type-check results |
| `traceability.md` | Requirement and decision links |
| `review.md` | Human review notes and lessons |

See `example/demo-feature-001/` for a fully fictional sample.

---

## Commands

```sh
# Enqueue a slug manually (the hook does this automatically on commit)
python bin/enqueue.py --slug my-feature --sha <commit-sha>

# Synthesize a proposal from the oldest queue entry (default model: opus)
DREAM_WARDEN_STANDALONE=1 python bin/consolidate.py

# Compact the playbook: detect near-duplicates, propose supersessions
DREAM_WARDEN_STANDALONE=1 python bin/compaction.py
DREAM_WARDEN_STANDALONE=1 python bin/compaction.py --model haiku   # cheaper
DREAM_WARDEN_STANDALONE=1 python bin/compaction.py --dry-run       # preview only

# Validate a proposal against the current playbook
DREAM_WARDEN_STANDALONE=1 python bin/conservation_check.py --proposal proposals/<ts>-<slug>.md

# Promote a reviewed proposal (human gate)
DREAM_WARDEN_STANDALONE=1 python bin/approve.py --proposal proposals/<ts>-<slug>.md

# Regenerate the compact digest after a hand-edit to playbook.md
DREAM_WARDEN_STANDALONE=1 python bin/render_digest.py
```

---

## Sections

| Title | Prefix | DR stands for |
|-------|--------|--------------|
| General Rules | `GR` | — |
| Architecture Gotchas | `AG` | — |
| **Domain Rules** | `DR` | **Domain Rules**: project-specific behavioral constraints and invariants |
| Verified Snippets | `VS` | — |

Rename "Domain Rules" in `bin/dream_lib.py` (`SECTIONS` constant) if your
project uses different terminology. Configure subsystem scope tags via `SCOPES`.

---

## The consolidate.py synthesis seam

The **only** site that changes to swap to a managed Dreams API (when available):

```python
# bin/dream_lib.py — run_claude_json()
cmd = [claude_executable(), "-p", "--output-format", "json", ...]
```

Replace this with `dreams.create(...)` or equivalent. Everything else —
parsing, conservation, atomic write, ledger, approval — is API-agnostic.

---

## The hook

`.git/hooks/post-commit` only enqueues. It is loop-safe: it skips commits
carrying the `[dream-promote]` marker and commits that touch only
`.workflow/_dream/`. Note: `git commit --no-verify` does **not** suppress
`post-commit` — these in-hook guards, not `--no-verify`, break the loop.

Install/refresh with: `.workflow/_dream/install-hook.sh`
