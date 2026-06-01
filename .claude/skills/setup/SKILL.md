---
name: setup
description: >
  Bootstrap the Claude PM Plugin structure in a new project. Creates all required
  folders (jobs/, issues/), copies template files (ROADMAP.md, REFERENCE.md, WORKFLOW.md,
  plugin-config.yaml, PR template), and installs skills and commands into .claude/.
  Detects project context (name, language, stack) and writes .ai-agents/PROJECT_CONTEXT.md
  so all other skills can reference the current project without hardcoded content.
  Safe to run multiple times — never overwrites existing files. Invoke when setting
  up the plugin in a new project, or to check which plugin files are missing.
---

# Setup — Claude PM Plugin Bootstrap

You are bootstrapping the Claude PM Plugin in this project. Your job is to detect
what's missing and create it — without touching anything that already exists.

**This skill is idempotent.** Running it twice must produce the same result as
running it once. Never overwrite existing files.

---

## Execution Protocol

This skill runs under the **Ultimate Protocol** (`.claude/skills/ultimate-protocol/SKILL.md`).

This is a resource-intensive task: it reads multiple manifest files, infers project context,
creates up to 12 files, and verifies skill installation.

- Zero conversational English during execution — all file reads and existence checks happen silently
- No output between steps — every action is a tool call, not a narration
- On completion, output the JSON status block:
  ```json
  {
    "status": "success | failed_needs_review",
    "created": ["list of files/folders created"],
    "skipped": ["list of files/folders already present"],
    "project_context": {"name": "...", "language": "...", "description": "..."},
    "install_check": "ok | missing — run install.sh"
  }
  ```
- If a file write fails, set `"status": "failed_needs_review"` and list the failure in `"errors": [...]`

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
- `.ai-agents/PROJECT_CONTEXT.md`
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

**Before creating ROADMAP.md or REFERENCE.md:** run STEP 2.5 detection logic first (even
if PROJECT_CONTEXT.md is not in the missing list) so you have `project_name` available to
substitute into the templates. Replace every occurrence of `[Project Name]` in the templates
below with the detected project name before writing.

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

## STEP 2.5 — Detect project context and write PROJECT_CONTEXT.md

**Skip this step entirely if `.ai-agents/PROJECT_CONTEXT.md` is already present.**

Probe the repo root silently for the following files and extract context from whichever
exist. Priority order: first match wins for `project_name` and `description`.

### Detection priority

| File | Extract |
|------|---------|
| `package.json` | `name`, `description`; language = `Node.js / TypeScript` or `Node.js / JavaScript` |
| `pyproject.toml` | `[project] name`, `[project] description`; language = `Python` |
| `setup.py` | first `name=` argument; language = `Python` |
| `Cargo.toml` | `[package] name`, `[package] description`; language = `Rust` |
| `go.mod` | `module` line; language = `Go` |
| `README.md` | First H1 as `project_name`, first non-blank paragraph after H1 as `description` |
| git remote | `git remote get-url origin` → extract repo name from URL as fallback |

If no source yields a name, use `"unknown"`.

### Template for `.ai-agents/PROJECT_CONTEXT.md`

```markdown
# Project Context

> Auto-generated by /setup. Edit freely — /setup will not overwrite this file.
> All skills read this file for project identity. Keep it current.

## Identity

**Name:** <project_name>
**Language / Stack:** <language>
**Description:** <description>
**Context generated:** <YYYY-MM-DD>

## Source of detection

<which file(s) the above was derived from>

## Additional context

<!-- Add team conventions, key contacts, deployment notes, or anything skills should
     know about this project that is not in ROADMAP.md or REFERENCE.md -->
```

Write this file to `.ai-agents/PROJECT_CONTEXT.md`. This file is the single source
of project identity for all agent skills. No other skill writes to it.

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

## STEP 4 — Output status JSON

Following the Ultimate Protocol, output ONLY the JSON status block. No prose.

```json
{
  "status": "success",
  "created": ["list every file and folder just created, or empty array"],
  "skipped": ["list every file and folder already present and left untouched, or empty array"],
  "project_context": {
    "name": "<detected project name>",
    "language": "<detected language / stack>",
    "description": "<detected description>"
  },
  "install_check": "ok | missing — run: bash .claude/plugins/pm/install.sh",
  "next_steps": [
    "Edit ROADMAP.md — fill in § 1 (project vision) and § 2 (technology decisions)",
    "Edit .ai-agents/REFERENCE.md — describe your architecture and directory layout",
    "Edit .ai-agents/PROJECT_CONTEXT.md — add team conventions and deployment notes",
    "If using Notion sync: add IDs to plugin-config.yaml and add it to .gitignore",
    "Run /create-job to queue your first task"
  ]
}
```

---

## What NOT to do

- Do not overwrite any existing file — skip it and add it to the "skipped" list
- Do not ask for confirmation before creating missing structure — just create it
- Do not read or validate existing file contents — only check existence
- Do not create files outside the expected locations
- Do not run the job workflow or any other skill — this is setup only
- Do not output prose during execution — follow the Ultimate Protocol (zero English, JSON only)
- Do not hardcode any project name or stack in the skill itself — all project content comes
  from detection and lives in PROJECT_CONTEXT.md
