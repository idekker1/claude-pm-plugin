---
id: F<NN>
title: <name>
status: planned | in-progress | shipped
roadmap_ref: "<section>"
rests_on: [D-NNNN]
---

# F<NN> — <name>

<!-- One paragraph: what this delivers and why now. -->

## Why this feature has a doc

<!-- A feature doc is only warranted when this work has 2+ jobs whose `touches` are DISJOINT —
     i.e. when the jobs can actually run in parallel. State that here.

     If the jobs would all write the same file, they are serial, this doc buys nothing, and the
     jobs should reference the roadmap directly. Delete the doc rather than keeping a title and
     a one-item checklist.

     Despite the folder name, this template covers refactors, migrations and hardening batches
     too — anything that decomposes into parallel work. -->

## Module boundaries

Separate files **on purpose** — the file boundaries are the parallelism boundaries.

| Module | Responsibility |
|---|---|
| | |

<!-- Note any constraint on what these may import, especially if the project has a protected
     path that must not depend on new code. -->

## Interface contract

Pinned **before** implementation. A job may be built against this contract before its producer
exists — that is what converts a dependency into a parallel opportunity.

```
<!-- Signatures and data shapes, in enough detail to build and test against without reading
     the producer's code. Be precise about the error and absent cases: that is where sibling
     jobs disagree. -->
```

<!-- Call out any part of the contract that is load-bearing for correctness rather than
     convenience, and say what breaks if it is collapsed or ignored. -->

## Jobs

| Job | Module | Depends on |
|---|---|---|
| F<NN>-J01 | | — |
| F<NN>-J02 | | contract only |

<!-- "contract only" means the job does not wait for its producer to merge. Say which jobs run
     in parallel and which are genuinely serial, and why. -->

## Acceptance

<!-- Referenced from the roadmap item, not copied. Note explicitly any criterion that cannot be
     met by unit tests and needs a run against real data or a real environment — those are the
     ones that get skipped otherwise. -->
