Run a project workflow status check using the project-manager skill.

$ARGUMENTS may be:
- Empty: run a full workflow status check
- A specific question: "is my branch ready for PR", "what should I work on next", "are my commits clean"

**Step 0 — What's in flight**

Always run this first and output the table before anything else.

Run:
```
git branch -a
git for-each-ref --format='%(refname:short) %(ahead-behind:main)' refs/heads
```

Output this table:

```
## What's in flight

| Branch | Ahead/Behind | Feature (from commits) | Last touched | Status |
|--------|-------------|------------------------|--------------|--------|
| feature/my-feature | +3 / 0 | Add genre filter | 5h ago | Not reviewed |
...
```

Status values:
- `Reviewed ✅` — a /review or /pre-commit has been run and passed
- `Not reviewed` — no review run this session
- `DO NOT MERGE 🛑` — review found critical issues
- `Merged` — branch is fully absorbed into main (0 commits ahead)

Include ALL local branches. For remote-only branches fully behind main, list in a
separate collapsed section: "Stale remote branches (fully absorbed — safe to delete)"

**Step 1 — Read current state**

Run:
```
git branch --show-current
git log main..HEAD --oneline
git status --short
git diff main...HEAD --name-only
```

Also read `ROADMAP.md` to understand the current version and what's pending.

**Step 2 — Branch name check**

Apply the branch naming rules from the project-manager skill:
- Correct prefix (`feature/`, `fix/`, `docs/`, `refactor/`, `chore/`)?
- Lowercase with hyphens only?
- Under 50 characters?
- Specific enough to understand the intent?

If on `main` or another protected branch: note it and skip to Step 5.
If the branch name is wrong: provide the exact `git branch -m` command to fix it.

**Step 3 — Commit quality check**

Review each commit from `git log main..HEAD --oneline`:
- Does each follow `<type>: <description>` format?
- Are they all scoped to this feature?
- Any "wip", "fix", "temp", or placeholder messages?

**Step 4 — PR readiness assessment**

1. Branch hygiene — accidental files check
2. Lint — advise running the project lint command if not confirmed clean
3. Schema check — if schema files changed, confirm migration exists
4. Tests — confirm CI would pass or advise running tests locally
5. PR description — is the intent clear enough to review?

**Step 5 — Output**

**What's good** — list what is correct and doesn't need attention.

**What needs fixing before a PR** — specific issues with concrete fix commands.

**Suggested next action** — one clear, concrete thing to do right now.

If $ARGUMENTS contains a specific question, focus on that and keep other sections brief.
