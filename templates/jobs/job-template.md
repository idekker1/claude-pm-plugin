---
job_id: <F03-J02, or NNN when there is no feature doc>
type: implementation | refactor | test | docs | fix | review
depends_on: []
priority: high | normal | low
touches:
  - <every file this job may write, including tests>
review: auto | human
roadmap_ref: "<section — item>"
feature_ref: <F-id, or omit>
created: YYYY-MM-DD
---

## Task

<!-- Specific. References files by path. Actionable without further clarification. Where a
     defect is being fixed, quote the current code so the worker starts from fact. -->

## Acceptance criteria

<!-- Independently testable. "It works" is not an acceptance criterion — each bullet must be
     verifiable by someone who wasn't in the room when this was written. Name the command, the
     observable output, or the state change.

     Reference the feature doc or roadmap section; do not copy their criteria here. Copies
     drift, and then something has to reconcile them. -->

-
-

## Test spec

<!-- Required for type: implementation, refactor, fix. Omit for test, docs, review.

     Write in BEHAVIOURAL terms — observable inputs, outputs and invariants. Never in
     implementation terms: no internal function names, no structure. The spec is written
     before the implementation exists and is used to generate an adversarial test job after
     it merges, by an agent that must not be able to infer the implementation from it.

     This is what stops a green suite meaning "the code agrees with itself". -->

- **Invariants:** <what must always hold — e.g. X is always Y after Z; state never regresses>
- **Inputs to test:** <e.g. empty, absent, boundary, over-limit, concurrent, malformed>
- **Errors to catch:** <e.g. missing field is rejected, not defaulted; unknown id raises, not ignored>
- **Must NOT happen:** <e.g. no writes under a read-only flag; no data loss on retry or interrupt>

## Notes

<!-- The decision records that apply (by id), the invariants in play, files to read first,
     known risks.

     If `depends_on` is sequencing rather than logical — because the `touches` overlap and the
     orchestrator will serialise them anyway — say so, so the order is deliberate rather than
     incidental. -->
