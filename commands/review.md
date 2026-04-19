Review the code at $ARGUMENTS using the code-reviewer skill.

Run all four analysis passes:
1. Correctness & safety — bugs, error handling, edge cases, security
2. Code standards — naming, structure, language idioms, type hints
3. Performance — query efficiency, async patterns, unnecessary allocations
4. Maintainability — modularity, coupling, testability

For minor issues (typos, missing type hints, small logic fixes): apply
the fix directly and note it in the report.

For architectural concerns: add them to the roadmap section of the report
with priority and effort estimates. Do not attempt to fix these.

Output a structured review report with a Handoff block at the end.
