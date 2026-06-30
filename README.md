# dream-warden

![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Dependencies](https://img.shields.io/badge/dependencies-zero-brightgreen)

Turn finished task work into long-term agent memory — without the model rewriting your notes in place.

When you complete a task, dream-warden reads what you wrote in `.workflow/<slug>/`, proposes new playbook entries, and waits for you to approve before anything becomes memory. The post-commit hook handles the boring part (queuing). You run two commands when you're ready.

> **Not affiliated with Anthropic.** Unofficial local take on the memory-consolidation pattern behind Managed Agents "Dreams." Uses the authenticated `claude` CLI as a synthesis engine today; no Managed Agents API required.

---

## Install (once)

**You need:** Python 3.11+, and `claude login`.

From your project root:

```sh
git clone --depth 1 https://github.com/<your-user>/dream-warden /tmp/dream-warden
/tmp/dream-warden/install.sh .workflow/_dream
.workflow/_dream/install-hook.sh
rm -rf /tmp/dream-warden
```

This copies only the runtime files — no dev fixtures or demo tasks. Done. Commits that touch `.workflow/<slug>/` get queued automatically. Your playbook lives at `.workflow/_dream/playbook.md`.

---

## Day-to-day use

This is the whole loop:

```
finish task  →  commit  →  consolidate  →  read proposal  →  approve (or don't)
     ▲              │            │                              │
     │         hook enqueues    │                              │
     │         (automatic)      │                              │
     └──────────────────────────┴──────────────────────────────┘
```

**1. Finish a task and commit.** Put artifacts in `.workflow/<slug>/` (see [What goes in a task folder](#what-goes-in-a-task-folder)) and commit as usual. The hook adds the slug to `queue/` — no extra step.

**2. Consolidate when you're ready.** When something is sitting in the queue:

```sh
cd .workflow/_dream
python bin/consolidate.py
```

This writes a proposal under `proposals/`. Nothing in your playbook changes yet.

**3. Approve if you like it.**

```sh
python bin/approve.py
```

Reads the newest proposal, promotes it into `playbook.md`, and commits with a `[dream-promote]` marker so the hook doesn't re-queue itself. Don't like it? Delete the proposal file and move on.

That's it. Most of the time you never touch anything else.

---

## Catch-up mode (many tasks queued)

If you finished several tasks and want to process them in one sitting:

```sh
cd .workflow/_dream
python bin/backfill.py          # synthesize queued slugs into one proposal (resumable)
python bin/approve.py           # or batch_approve.py if you ran consolidate per task
```

`backfill.py` is the "many enqueues → one consolidated proposal" path. `batch_approve.py` is for when you already have several proposal files and want to promote them all in order.

---

## What goes in a task folder

Each completed task lives at `.workflow/<slug>/`. The hook enqueues on commit; consolidation reads whatever files exist (missing ones are skipped).

| File | What it's for |
|------|----------------|
| `state.json` | Set `"status": "complete"` when the task is done (consolidation checks this) |
| `final-report.md` | What you built / changed |
| `verification.md` | Test or lint output |
| `review.md` | Lessons, gotchas, review notes |
| `plan.md` | Original plan (optional context) |
| `traceability.md` | Requirement links (optional context) |

See `CONTRACT.md` for the full spec.

---

## Optional maintenance

**Compaction** — run occasionally when the playbook feels repetitive. Finds near-duplicates and proposes supersessions (same review-and-approve flow, no new entries):

```sh
python bin/compaction.py
python bin/approve.py
```

**Hand-edited the playbook?** Regenerate the compact digest agents load at startup:

```sh
python bin/render_digest.py
```

---

## What you get

dream-warden maintains two views of the same memory:

- **`playbook.md`** — source of truth (full entries, provenance, history)
- **`playbook.digest.md`** — compact startup view; auto-updated on approve

Entries are grouped into four sections (General Rules, Architecture Gotchas, Domain Rules, Verified Snippets). Rename or retag in `bin/dream_lib.py` if your project uses different names. AG/DR entries can carry scope tags so agents load only what's relevant to the current task — see `SCOPES` in the same file.

---

## Why it's safe (short version)

These aren't hygiene features — a memory store that shapes every future session is a poisoning surface ([OWASP ASI06](https://owasp.org/www-project-top-10-for-agentic-applications/)), and the human review gate is the mitigation.

- **Proposals, not in-place edits.** The model never writes directly to your playbook. You always review a separate file first.
- **Nothing gets dropped.** Existing entries are preserved by construction; a separate checker verifies that before approve will run.
- **No repo access during synthesis.** The model runs tool-less (`--tools ""`); it only sees the playbook text and your task files.
- **You are the gate.** Bad synthesis can't become memory unless you run `approve.py`.

More detail: conservation guarantees, loop guards, and the advisory vs. enforced checks are documented in `CONTRACT.md`.

---

## Advanced / reference

<details>
<summary>All commands (you probably won't need most of these)</summary>

Run from `.workflow/_dream/` unless noted.

```sh
python bin/consolidate.py              # synthesize oldest queued slug
python bin/backfill.py                 # synthesize many slugs into one proposal
python bin/compaction.py               # propose near-duplicate supersessions
python bin/approve.py                  # promote newest proposal
python bin/approve.py --proposal proposals/<file>.md
python bin/batch_approve.py            # promote all pending proposals in order
python bin/conservation_check.py --proposal proposals/<file>.md
python bin/render_digest.py            # after hand-editing playbook.md
python bin/enqueue.py --slug X --sha Y # manual enqueue (hook does this for you)
```

Default model is `opus` (`--model` or `DREAM_MODEL` env var to override).

</details>

<details>
<summary>Developing dream-warden itself (standalone mode)</summary>

If you're hacking on this repo — not installing it into another project — the `.dream-standalone` marker at the repo root tells scripts to use the repo root as the dream directory. See `CONTRACT.md` §6. Run `dev/bootstrap-workflow.sh` to copy fictional fixtures into `.workflow/demo-feature-001/` for dry-runs. The post-commit hook is only wired for installed layout; in standalone dev you pass `--slug` and `--sha` explicitly or enqueue manually.

</details>

<details>
<summary>Synthesis seam (for swapping to a future Dreams API)</summary>

All model calls go through `dream_lib.run_claude_json()` in `bin/dream_lib.py`. Replace that one function with `dreams.create(...)` or equivalent; everything else stays the same.

</details>

---

## License

MIT — see [LICENSE](LICENSE).
