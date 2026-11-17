---
name: create-job
description: >
  Queue a unit of work as a job file in jobs/pending/. Validates that the work maps to the
  roadmap, that its acceptance criteria are independently testable, and that its `touches` list
  is complete enough for the orchestrator to schedule it safely. Invoke when the user wants to
  queue work, add a task, or turn a roadmap item into something an agent can run. Produces one
  job file — does NOT execute work.
---

# create-job

You turn an intention into a job an agent can execute and a reviewer can judge. One job, one
file, written to `jobs/pending/`. You do not execute anything.

The value here is the **specification gate**. A job with vague criteria produces work nobody can
verify, and with parallel agents nobody is watching closely enough to catch it. Be strict.

---

## STEP 1 — Context

Read, in order: `CLAUDE.md` (constraints, test command, `critical_paths`), the roadmap in full,
and the architecture reference. List `jobs/pending/`, `active/`, `done/`, `failed/` and read the
frontmatter of each to see what is queued, in flight, and already satisfied.

If the work belongs to an existing feature, read its feature doc for the module boundaries and
the interface contract.

## STEP 2 — Validate before writing

Three checks. If any fails, resolve it before producing a file — do not quietly create a job
that is set up to fail.

**(a) Roadmap alignment.** Does this map to a roadmap item? If not, and it isn't a clear bugfix
or housekeeping, say so:

> "This isn't in the roadmap. If it belongs there, run `/architect` first. If it's a one-off,
> confirm and I'll mark it as such."

**(b) Criteria are testable.** *"It works" is not an acceptance criterion.* Each bullet must be
independently verifiable by someone who wasn't in the room when the job was written. Name the
command, the observable output, the state change. If the request is too vague to produce such
criteria, ask a specific question rather than inventing them.

Criteria are **referenced, not copied**, from the roadmap item or feature doc. Copying creates
drift and forces a reconciliation pass later.

**(c) `touches` is complete.** Every file the job may write, including tests. This is the field
the orchestrator uses to decide what can run in parallel, so an under-declared list silently
breaks the guarantee for every other job in the batch.

Shared files — the roadmap, changelog, `decisions/`, `features/`, `jobs/` — are **never** in
`touches`. They are written by the orchestrator after merge.

If the work cannot be scoped to a declarable file set, it is too big to be one job. Say so and
propose a split.

**(d) Test spec** — for `implementation`, `refactor` and `fix` jobs. Skip for `test`, `docs`
and `review`.

Check whether the request contains enough behavioural description to produce a test spec:
observable inputs, outputs, invariants and error cases. If it does, write a `## Test spec`
section into the job. If it doesn't and the job is non-trivial, ask:

> "What should be tested? Describe the behaviour from the outside: what inputs produce what
> outputs, what error cases must be handled, what must always hold, and what must never happen."

Write it in **behavioural terms only** — never internal function names or structure. The spec is
written before the implementation exists, and it is later handed to an agent that must not be
able to infer the implementation from it.

**Why this matters more than it looks.** The merge gate auto-merges on a green suite. If the
agent that writes the implementation also writes its tests, green means "the code agrees with
itself" — the tests mirror the implementation instead of constraining it, and the gate is
measuring nothing. The spec exists so an adversarial test job can be generated from it *after*
the implementation merges, written by an agent that did not write the code.

**Soft gate.** If the user declines, create the job and note:

> "No test spec. Adversarial test generation will be skipped for this job, so its green suite
> only shows the implementation agrees with its own tests."

**Waiver** for trivial or cosmetic work with no observable behaviour change — note it in Notes:
`Test spec waived: no observable behaviour change.`

**Does it need a feature doc?** If this work needs **2+ jobs whose `touches` are disjoint**,
they can run in parallel — and then the interface between them must be pinned first. Hand off:

> "This decomposes into N parallel jobs. Run `/architect` to pin the module boundaries and the
> interface contract first, then I'll queue them against it."

If the jobs would collide on the same file anyway, they are serial, a feature doc buys nothing,
and the jobs reference the roadmap directly. Don't create ceremony for work that has no
parallelism to coordinate.

## STEP 3 — Write

### Job id

- Part of a feature → `F<NN>-J<NN>`, scoped to the feature.
- Otherwise → the next free zero-padded integer across all four folders.

Prefer feature-scoped ids. A single global counter is a race as soon as two agents create jobs
at once.

### Frontmatter

```yaml
---
job_id: <id>
type: implementation | refactor | test | docs | fix | review
depends_on: []                 # job_ids that must be in done/ first
priority: high | normal | low
touches:                       # REQUIRED — every file this job may write
  - <path>
review: auto | human
roadmap_ref: "<section — item>"
feature_ref: <F-id>            # omit when there is no feature doc
created: YYYY-MM-DD
---
```

`review: human` is required when any `touches` entry appears in `CLAUDE.md`'s `critical_paths`,
when the job touches a project invariant, or when it changes a configuration schema. `auto` is
for test-only and docs work. When in doubt, `human`.

### Body

**Task** — specific, references files by path, actionable without further clarification. Quote
the exact current code where a defect is being fixed.

**Acceptance criteria** — the testable bullets from STEP 2(b).

**Test spec** — from STEP 2(d), for `implementation`, `refactor` and `fix` jobs. Four parts:
invariants, inputs to test, errors to catch, and what must not happen.

**Notes** — the decision records that apply, the invariants in play, files to read first, known
risks, and why any `depends_on` exists. If a dependency is sequencing rather than logical
(overlapping `touches`), say so explicitly so the order is deliberate rather than incidental.

Write to `jobs/pending/<job_id>-<slug>.md`. Slug: lowercase, hyphens, under 40 characters.

## STEP 4 — Confirm

Report: job id, type, `touches`, `review` and why, `depends_on` and what each is, the acceptance
criteria, whether a test spec is present (or waived, or declined), the suggested branch name, and
whether this job can run in parallel with anything currently queued — naming the collision if not.

If validation raised anything substantive, show the draft and ask before writing.
