Run a quick consistency check on changed files before committing, using the code-guardian skill.

Runs in Diff mode: only reviews files changed since the last commit or since branching from main.

The guardian will:
1. Lint changed files first
2. Check pattern consistency against .ai-agents/REFERENCE.md conventions
3. Check complexity (nesting, function length)
4. Check comment hygiene
5. Scan for TODOs/FIXMEs without context
6. Verify test coverage for new public functions

Fixes minor issues directly. Escalates larger issues to issues/ without blocking.

Run this before `git add` and `git commit`.
