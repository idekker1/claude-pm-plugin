Update ROADMAP.md and REFERENCE.md to reflect recently shipped work using the project-manager skill.

Run this after a PR merges to main. The skill will:
1. Read `git log --merges --oneline -5` to identify what shipped
2. Find the corresponding done/ job by matching the branch name
3. Mark completed roadmap items [x]
4. Update REFERENCE.md if API, schema, or architecture changed
5. If all items in a version are now [x]: mark the version complete (✓)
6. Report what was updated and what the next unblocked job is

$ARGUMENTS may be:
- Empty: check recent merges and sync docs
- A PR number: "PR merged #42" — focus sync on that specific PR
