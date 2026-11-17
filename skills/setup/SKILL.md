---
name: setup
description: >
  Bootstrap this plugin's structure in a project: CLAUDE.md, ROADMAP.md, ARCHITECTURE.md,
  decisions/, features/, jobs/ and a CI workflow matched to the detected stack. Detects the
  project's language, test command and lint command rather than assuming them. Safe to run
  repeatedly — never overwrites an existing file. Invoke when setting up the plugin in a new
  project, or to check what is missing.
---

# Setup

You bootstrap the plugin in a project. Detect what's missing, create it, and **never overwrite
anything that already exists.** Running twice must produce the same result as running once.

Report what you did in plain English: created, skipped, detected, and what the user must fill in
themselves.

---

## STEP 1 — Detect the project

You are writing files that will be read as truth by every later agent, so detect rather than
assume. Determine:

- **Name** — from package metadata, then the git remote, then the directory name.
- **Language and stack** — from the manifest files present (`pyproject.toml`, `setup.py`,
  `requirements.txt`, `package.json`, `go.mod`, `Cargo.toml`, `Gemfile`, `pom.xml`, …).
- **Test command** — from the manifest's scripts, a `Makefile` target, a CI config, or the test
  framework actually imported by files under `test/` or `tests/`. If an existing test file
  exists, the command that runs *it* is the answer.
- **Lint command** — same sources. If there is none, say so; don't invent one.
- **Entry points** — executables, `main`, server start, CLI.
- **Critical paths** — the files where a mistake is expensive: anything on a data-writing path,
  auth, migrations, deployment config. Propose a list; make clear it is a proposal.

If detection is ambiguous, **ask one specific question** rather than writing a confident wrong
answer into `CLAUDE.md`.

## STEP 2 — Report the plan, then create

List what is missing and what you will create. Then create only the missing items.

### Directories

`decisions/`, `features/`, `jobs/pending/`, `jobs/active/`, `jobs/done/`, `jobs/failed/`

Add `.gitkeep` to the four empty job lifecycle folders. **Do not** add the job folders to
`.gitignore` — jobs, features and decisions are versioned artifacts. They are coordination state
for parallel agents and the record of what was done, and both are worthless if they live on one
machine. If the project's `.gitignore` already excludes them, say so and recommend removing that
rule.

### Files, from `templates/`

| Template | Destination |
|---|---|
| `CLAUDE.md.template` | `CLAUDE.md` |
| `ROADMAP.md.template` | `ROADMAP.md` |
| `ARCHITECTURE.md.template` | `ARCHITECTURE.md` |
| `decisions/README.md` | `decisions/README.md` |
| `decisions/decision-template.md` | `decisions/decision-template.md` |
| `features/feature-template.md` | `features/feature-template.md` |
| `jobs/README.md` | `jobs/README.md` |
| `jobs/job-template.md` | `jobs/job-template.md` |
| `.github/pull_request_template.md` | `.github/pull_request_template.md` |

Fill the detected values into `CLAUDE.md` as you copy it — project name, test command, lint
command, proposed `critical_paths`. Leave the rest as clearly-marked placeholders. A placeholder
is honest; a guess is not.

`CLAUDE.md` is the one file the harness loads automatically in every session, which is why the
project's constraints live there rather than in a file a skill has to remember to read.

### CI workflow

Copy the workflow matching the detected stack from `templates/workflows/` to
`.github/workflows/test.yml`, substituting the detected test and lint commands.

**If no stack matches, write no workflow** and say so. Emitting a workflow for the wrong language
is worse than emitting none — it produces a permanently red check that teaches the user to ignore
CI.

## STEP 3 — The parallel-dispatch gate

Check whether a usable test suite exists: a test command *and* test files that actually run.

**If there is no trustworthy suite, say so prominently and state that parallel dispatch is not
available yet:**

> "No test suite detected. `/dispatch` will run one job at a time. Parallel agents need a suite
> that runs in CI — two branches can merge cleanly and still break the default branch (a rename
> in one, a new caller in the other), and only a full test run catches that. Add a suite before
> running agents in parallel."

This is a real prerequisite, not a recommendation. Do not scaffold parallel workflow
documentation into a project that cannot safely use it.

## STEP 4 — Report

- **Created** — each path.
- **Skipped** — each path that already existed.
- **Detected** — name, stack, test command, lint command, entry points.
- **Proposed `critical_paths`** — and ask the user to confirm or correct them, since this list
  drives which work requires human review.
- **Parallel dispatch** — available, or not available and why.
- **Next steps** — fill in the roadmap's vision and scope sections, record the decisions already
  implicit in the codebase with `/architect`, then `/create-job`.

Never claim you created something you skipped.
