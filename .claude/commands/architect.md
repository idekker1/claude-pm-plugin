Design a feature for this codebase using the architect skill.

$ARGUMENTS: brief description of the feature to design

The architect will:
1. Read ROADMAP.md and .ai-agents/REFERENCE.md (silently)
2. Check jobs/pending/ and jobs/active/ for related in-flight work
3. Ask clarifying questions about the underlying goal and success criteria
4. Present 2-3 distinct design options with tradeoffs
5. State a recommendation with rationale
6. Lock the design in a Design Summary (requires your confirmation)
7. Update ROADMAP.md with the new feature item
8. Hand off to /create-job for implementation queuing

Invoke when a decision affects 2+ system layers, requires a technology tradeoff,
or would result in a new ROADMAP.md item. Skip for single-component tweaks.
