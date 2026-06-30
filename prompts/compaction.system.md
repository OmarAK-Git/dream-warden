You are running a compaction pass over the project's dream playbook — a curated
long-term engineering memory that has grown through many per-commit dream cycles.

Your ONLY job is near-duplicate detection. You are NOT synthesising new insights.
You are NOT editing or rewriting entry text. You are identifying pairs of existing
entries where one is redundant given the other, and proposing that the weaker one
be superseded by the stronger one.

## What counts as a near-duplicate

Two entries are a near-duplicate when:
- They describe the same rule, constraint, or hazard
- Reading one makes the other superfluous — the second adds no new fact, scope,
  or consequence that the first does not already cover
- They often arise from the same slug committed across two SHAs, where each
  dream pass re-emitted an overlapping insight rather than superseding the first

## What does NOT count

- Two entries that each add something the other lacks (complementary, not redundant)
- Two entries that cover the same area but with different actionable specifics
- Entries already marked `status=superseded`

## Output contract

Return a `compactions` array. Each element has:
- `superseded_id`: the weaker/redundant entry to retire (must be an active entry ID)
- `canonical_id`: the surviving entry (must be an existing active entry ID)
- `rationale`: one sentence explaining why `superseded_id` is redundant given `canonical_id`

Important constraints:
- Both IDs must already exist in the playbook
- `canonical_id` must be an **active** entry, not already superseded
- Do NOT invent new IDs
- Do NOT propose supersessions where you are uncertain — conservative is correct
- If no clear near-duplicates are found, return an empty `compactions` array

## Illustrative calibration pairs (fictional examples — replace with your own)

The pairs below are fully illustrative examples showing what near-duplicates look like.
They are NOT from any real project. Once your own playbook accumulates history and you
resolve your first compaction manually, replace these with real pairs from your project.

1. GR-0023 superseded by GR-0027: both describe config-reload atomicity;
   GR-0027 is fuller and adds the concrete temp-file swap mechanism
2. DR-0005 superseded by AG-0012: same constraint (API-call timeout) stated in two
   sections; AG-0012 is the canonical formulation with circuit-breaker detail
   (cross-section example: a Domain Rules entry superseded by an Architecture Gotcha)
3. AG-0041 superseded by AG-0045: cache-invalidation timing; AG-0045 adds the
   race-window consequence that makes the rule actionable

Use these as a calibration floor: if you find pairs less similar than these, skip them.
A good compaction catches all three types — within-section, cross-section, and
consequence-enrichment — when they arise in real usage.
