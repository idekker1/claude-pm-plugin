---
name: setup
description: >
  Bootstrap the Claude PM Plugin structure in a new project. Creates all required
  folders (jobs/, issues/), copies template files (ROADMAP.md, REFERENCE.md, WORKFLOW.md,
  plugin-config.yaml, PR template), and installs skills and commands into .claude/.
  Safe to run multiple times — never overwrites existing files. Invoke when setting
  up the plugin in a new project, or to check which plugin files are missing.
---

# Setup — Claude PM Plugin Bootstrap

You are bootstrapping the Claude PM Plugin in this project. Your job is to detect
what's missing and create it — without touching anything that already exists.

**This skill is idempotent.** Running it twice must produce the same result as
running it once. Never overwrite existing files.

---

## STEP 1 — Detect existing structure (silent)

Check for the existence of each of the following. Build two lists: **present** and
**missing**.

**Folders:**
- `jobs/pending/`
- `jobs/active/`
- `jobs/done/`
- `jobs/failed/`
- `issues/`
- `.ai-agents/`
- `.github/`

**Files:**
- `ROADMAP.md`
- `.ai-agents/REFERENCE.md`
- `WORKFLOW.md`
- `plugin-config.yaml`
- `jobs/README.md`
- `issues/open.md`
- `issues/closed.md`
- `.github/pull_request_template.md`

Do NOT read file contents — only check existence (use `ls` or equivalent). Do not
output anything during this step.

---

## STEP 2 — Create missing structure

For each item in the **missing** list, create it using the templates below. For items
in the **present** list, skip entirely — output nothing about them yet.

### Folders to create (with .gitkeep so git tracks empty dirs)

```
jobs/pending/.gitkeep
jobs/active/.gitkeep
jobs/done/.gitkeep
jobs/failed/.gitkeep
issues/
.ai-agents/
.github/
```

### `ROADMAP.md`

```markdown
# [Project Name] — Roadmap

**Last updated:** YYYY-MM-DD
**Current version: V0.1**

> This document is the strategic reference for all AI agents working on this codebase.
> Read this alongside `.ai-agents/REFERENCE.md` before making any changes.

---

## § 1 — Vision & Scope

[Describe what this project does and what success looks like. One paragraph.]

---

## § 2 — Technology Decisions (Final)

These decisions are made. Don't revisit them without strong reason.

| Concern | Choice | Rationale |
|---------|--------|-----------|
| [e.g. Database] | [e.g. PostgreSQL] | [why] |

---

## § 3 — V0.1 — Initial Release

- [ ] [First feature or milestone]

---

## § 10 — Open Questions

[Design decisions not yet made. Remove this section once all questions are resolved.]
```

### `.ai-agents/REFERENCE.md`

```markdown
# [Project Name] — AI Agent Reference

> **Purpose:** Definitive reference for any AI agent working on this codebase.
> Read this before making any changes. For strategic direction, read `ROADMAP.md`.

---

## § 1 — Project Overview

[One paragraph: what this project is, what it does, what the main components are.]

**Current version: V0.1**

---

## § 2 — Architecture

[Describe how the system is structured: services, databases, key components.]

---

## § 3 — Directory Layout

[Key directories and what they contain.]

---

## § 4 — Database Schema

[Tables, columns, relationships. Update when schema changes.]

---

## § 5 — Configuration

[Environment variables, config files, key settings.]

---

## § 6 — MCP / Integration Tools (if applicable)

[Any MCP server tools or external integrations.]

---

## § 7 — API Endpoints (if applicable)

[REST API routes, methods, request/response shapes.]

---

## § 8 — Known Limitations & Extension Points

[Things that are deliberately out of scope or known constraints.]
```

### `WORKFLOW.md`

```markdown
# Developer Workflow

## Branch Naming

| Work type | Prefix | Example |
|-----------|--------|---------|
| New feature | `feature/` | `feature/user-authentication` |
| Bug fix | `fix/` | `fix/null-pointer-login` |
| Documentation | `docs/` | `docs/update-api-reference` |
| Refactor | `refactor/` | `refactor/extract-query-layer` |
| CI / tooling | `chore/` | `chore/add-ruff-pre-commit` |

Rules: lowercase only, hyphens as separators, under 50 characters total.

## Commit Messages

Format: `<type>: <description in imperative mood>`

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`

Rules: under 72 chars, imperative mood ("add X" not "added X"), no period at end.

## Day-to-Day Workflow

```
git checkout -b feature/my-feature   # branch from main
# ... develop ...
/pre-commit                          # guardian pass before commit
git add -p && git commit -m "feat: ..."
/review src/path/to/changed/files    # deep review before PR
/pr                                  # lint → commit → push → open PR
# merge on GitHub
git checkout main && git pull
/run-jobs "PR merged #N"             # sync roadmap + docs
```

## Claude Code Skills

| Command | What it does |
|---------|-------------|
| `/setup` | Bootstrap plugin structure in this project |
| `/pm` | Project status: branches, job queue, roadmap |
| `/architect [feature]` | Design a feature before building it |
| `/create-job [task]` | Queue a unit of work |
| `/run-jobs` | Execute next unblocked job |
| `/review [path]` | Deep code review |
| `/pre-commit` | Quick consistency check before committing |
| `/pr` | Ship: lint → commit → push → open PR |
| `/audit` | Full codebase audit, generate issue reports |
| `/pm-sync` | Sync issue reports to Notion (if configured) |
| `/pm-update-roadmap` | Mark shipped items [x] in roadmap |

## Job Workflow

```
/architect feature        # design and roadmap entry
/create-job 'task'        # queue implementation work
/run-jobs                 # pick up and execute job
/pr                       # ship the branch
/run-jobs "PR merged #N"  # sync docs after merge
```
```

### `plugin-config.yaml`

```yaml
# Claude PM Plugin — project configuration
# See: https://github.com/[your-repo]/claude-pm-plugin

# ── Notion Integration ─────────────────────────────────────────────────────────
# Set enabled: true and provide IDs to sync audit reports to Notion.
# WARNING: Do not commit credentials — add plugin-config.yaml to .gitignore
notion:
  enabled: false
  workspace_id: ""          # Notion workspace ID
  bugs_database_id: ""      # Database for Critical/Major/Minor issues
  tasks_database_id: ""     # Database for Architectural roadmap items
```

### `jobs/README.md`

Create from the job system documentation template (see templates/jobs/README.md in the plugin repo).

### `issues/open.md`

```markdown
# Open Issues

Last updated: YYYY-MM-DD

| ID | Severity | Title | File | Job | Status |
|----|----------|-------|------|-----|--------|
```

### `issues/closed.md`

```markdown
# Closed Issues

Last updated: YYYY-MM-DD

| ID | Severity | Title | Closed | Job | How Resolved |
|----|----------|-------|--------|-----|--------------|
```

### `.github/pull_request_template.md`

```markdown
## Summary

-

## Changes

-

## Test plan

- [ ] Tests pass locally
- [ ] Linting clean
- [ ] No new warnings or regressions

## Checklist

- [ ] Branch name follows `type/slug` convention
- [ ] Commit messages follow `type: description` format
- [ ] ROADMAP.md updated if a feature shipped
- [ ] `.ai-agents/REFERENCE.md` updated if API or schema changed

🤖 Reviewed with [Claude PM Plugin](https://github.com/[your-repo]/claude-pm-plugin)
```

---

## STEP 3 — Install skills and commands

The plugin's skill and command files should already be present in `.claude/skills/`
and `.claude/commands/` (the install script handles this). If running in a context
where they are not yet installed, report this and provide the install command:

```
bash .claude/plugins/pm/install.sh
```

Do not copy files yourself in this step — that is the install script's job.

---

## STEP 4 — Report

Output two sections:

**Created:**
List every file and folder that was just created. If nothing was created, say
"Nothing to create — structure is already complete."

**Skipped (already exists):**
List every file and folder that was already present and left untouched.

Then output the next step prompt:

```
Plugin structure is ready. Next steps:
1. Edit ROADMAP.md — fill in § 1 (project vision) and § 2 (technology decisions)
2. Edit .ai-agents/REFERENCE.md — describe your architecture and directory layout
3. If using Notion sync: add your workspace and database IDs to plugin-config.yaml
   and add plugin-config.yaml to .gitignore
4. Run /create-job to queue your first task
```

---

## What NOT to do

- Do not overwrite any existing file — skip it and add it to the "Skipped" list
- Do not ask for confirmation before creating missing structure — just create it
- Do not read or validate existing file contents — only check existence
- Do not create files outside the expected locations
- Do not run the job workflow or any other skill — this is setup only
