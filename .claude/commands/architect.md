Design a feature using the architect skill.

$ARGUMENTS — the feature or design question.

1. Reads `CLAUDE.md`, `ROADMAP.md`, `ARCHITECTURE.md` and the relevant records in `decisions/`.
2. Checks the idea against the project's scope, invariants and already-settled decisions — and
   says so plainly when it conflicts with one, rather than designing around it.
3. Presents options with real tradeoffs and makes a recommendation.
4. Writes the decision record to `decisions/`, citing the records it rests on.
5. Writes a feature doc with module boundaries and an interface contract **only** when the work
   decomposes into 2+ jobs whose `touches` are disjoint.

Designs only — implements nothing, queues nothing. Hands off to `/create-job`.
