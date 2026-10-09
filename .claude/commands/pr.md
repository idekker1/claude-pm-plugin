Ship the current branch: lint → confirm commit → push → open PR.

Run this after a code-reviewer or code-guardian pass says the branch is ready.
Do NOT run this on `main` directly.

$ARGUMENTS may be:
- Empty: use current branch, auto-generate commit message and PR description
- A custom commit message: use that instead of the generated one

---

**Step 1 — Orient**

Run:
```
git branch --show-current
git log main..HEAD --oneline
git status --short
git diff main...HEAD --name-only
```

Output a brief summary:
```
Branch: <name>
Commits ahead of main: <N>
Uncommitted changes: <yes / no>
```

If on `main`: stop — commits to main must go through a branch + PR.
If nothing ahead of main AND no uncommitted changes: stop — nothing to ship.

---

**Step 2 — Accidental files check**

Inspect `git status --short` and `git diff main...HEAD --name-only` for:
- `.env` or any secrets file
- Build artifacts (`*.pyc`, `__pycache__/`, `.DS_Store`, `dist/`, `build/`)
- Database dumps or large generated files
- `node_modules/`

If any are present: stop, tell the user which files to remove, and provide the exact
`git rm --cached <file>` command. Do not proceed until these are cleared.

---

**Step 3 — Lint**

Run the project's lint command (check `WORKFLOW.md` for the correct command).
Common examples: `make lint`, `ruff check .`, `eslint src/`, `npm run lint`.

If it exits non-zero:
1. Report which files/lines failed
2. Run the auto-fix command if one exists
3. Re-run lint — if still failing, report what needs manual fixing and stop
4. If auto-fix changed files, note them — they will be included in the commit

If lint passes: continue.

---

**Step 4 — Stage and confirm commit message**

Run `git diff --stat HEAD` to show what will be committed.

If $ARGUMENTS provided a commit message, use that.
Otherwise, generate a commit message from the branch name and `git diff main...HEAD --stat`:
- Format: `<type>: <imperative description>`
- Type derived from branch prefix: `fix/` → `fix`, `feature/` → `feat`, `chore/` → `chore`, etc.
- Description: concise summary of what changed, not a list of files

**STOP HERE** — output the proposed commit message and ask the user to confirm or edit it
before proceeding. Do not commit without explicit confirmation.

Example stop point:
```
Proposed commit message:
  feat: add genre-coherence filter to set builder

Confirm this message? (or provide your own)
```

Wait for user response before moving to Step 5.

---

**Step 5 — Commit**

Once the user confirms the message, run:
```
git add -p   ← stage interactively, or list specific files if the diff is clean
git commit -m "<confirmed message>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

If the commit hook fails: report the failure, do NOT use `--no-verify`. Fix the
underlying issue and retry.

---

**Step 6 — Push**

Run:
```
git push -u origin <branch-name>
```

If push is rejected (non-fast-forward): report it and stop. Do not force-push.
Explain that the user needs to pull and resolve conflicts first.

---

**Step 7 — Open PR**

Generate a PR description using `git log main..HEAD --oneline` and `git diff main...HEAD --stat`.

If `.github/pull_request_template.md` exists, use it as the base and fill in each section.
Otherwise, use this structure:

```
## What
<1–2 sentences: what does this branch do?>

## Why
<1 sentence: why is this change being made?>

## Changes
<bullet list of key changes — behaviour changes, not a file list>

## Testing
<how was this tested?>

## Risks / follow-ups
<known limitations or next steps — or "none">

🤖 Reviewed and shipped with Claude PM Plugin
```

Run:
```
gh pr create --title "<commit message subject>" --body "<generated description>"
```

Output the PR URL when done.

---

**Step 8 — Summary**

Output a final status block:
```
---
## Shipped

**Branch:** <name>
**PR:** <URL>
**Commits:** <N commits in PR>
**Next step:** Monitor CI — if it passes, the PR is ready for merge.
---
```
