---
job_id: 000
type: implementation
depends_on: []
priority: normal
created: YYYY-MM-DD
roadmap_ref: ""
---

## Task

[Describe what needs to be done. Be specific — reference files by path, describe
the exact change needed, and list any hard constraints. Specific enough to act on
without further clarification.]

## Acceptance criteria

- [Concrete, independently testable condition]
- [Concrete, independently testable condition]

## Test spec

<!-- Required for type: implementation, schema-change, refactor. Omit for docs-update, review.
     Write in behavioral terms (observable inputs/outputs/invariants) — not implementation terms.
     This spec is used to auto-generate an adversarial test job after implementation completes. -->

- **Invariants:** [e.g., X is always Y after calling Z, state never regresses]
- **Inputs to test:** [e.g., empty list, null, value > MAX, concurrent calls]
- **Errors to catch:** [e.g., missing field returns 400 not 500, unknown ID raises not silently ignores]
- **Must NOT happen:** [e.g., side-effects under read-only flag, data loss on retry]

## Notes

[Optional: risks, constraints, files to read before starting, related jobs,
quoted ROADMAP.md sections, open issues addressed]

Addresses open issues: [C1, M2 — or remove this line if none]
