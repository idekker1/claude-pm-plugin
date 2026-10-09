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

## Notes

<!-- The decision records that apply (by id), the invariants in play, files to read first,
     known risks.

     If `depends_on` is sequencing rather than logical — because the `touches` overlap and the
     orchestrator will serialise them anyway — say so, so the order is deliberate rather than
     incidental. -->
