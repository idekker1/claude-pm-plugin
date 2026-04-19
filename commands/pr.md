Ship the current branch: lint → confirm commit → push → open PR.

Run this after a code-reviewer or code-guardian pass says the branch is ready.
Do NOT run this on `main` directly.

$ARGUMENTS may be:
- Empty: use current branch, auto-generate commit message and PR description
- A custom commit message: use that instead of the generated one

See the pr skill for the full workflow: `.claude/skills/pr/SKILL.md`
