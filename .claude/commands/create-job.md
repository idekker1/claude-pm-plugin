Queue a unit of work using the create-job skill.

$ARGUMENTS — a description of the work to queue.

Validates roadmap alignment, that the acceptance criteria are independently testable, and that
the `touches` list is complete enough to schedule safely. Writes one file to `jobs/pending/`.

Hands off to `/architect` first if the work needs a feature doc — that is, if it decomposes into
two or more jobs whose `touches` are disjoint and therefore need a pinned interface contract.

Does not execute work.
