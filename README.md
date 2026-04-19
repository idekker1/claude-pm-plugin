# Claude PM Plugin

A distributable Claude Code plugin for project management, code quality, and structured
workflow across any codebase. Extracted and generalized from the SLAI project.

---

## What's Included

### Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `setup` | `/setup` | Bootstrap project structure (run once) |
| `pm` | `/pm` | Git workflow, roadmap maintenance, Notion sync, job status |
| `architect` | `/architect` | Feature design: options, tradeoffs, roadmap updates |
| `code-reviewer` | `/review` | Deep 4-pass code review before PRs |
| `code-guardian` | `/pre-commit` | Daily consistency checks, comment hygiene |
| `pr` | `/pr` | Ship: lint → commit → push → open PR |
| `create-job` | `/create-job` | Queue work with dependency validation |
| `run-jobs` | `/run-jobs` | Execute jobs, manage lifecycle, sync docs |
| `antigravity` | automatic | High-efficiency coding protocol (v1) |
| `antigravity2.0` | automatic | High-efficiency coding protocol (v2.0) |
| `ultimate-protocol` | "ultimate mode" | Zero-English execution protocol |

### Project Structure Created

```
your-project/
├── ROADMAP.md                        # Versioned roadmap with tech decisions
├── WORKFLOW.md                       # Branch naming, commit format, workflow
├── plugin-config.yaml                # Notion opt-in config (do not commit credentials)
├── .ai-agents/
│   └── REFERENCE.md                  # Living technical reference
├── jobs/
│   ├── README.md                     # Job system documentation
│   ├── pending/                      # Jobs waiting to run
│   ├── active/                       # One job at a time (lock)
│   ├── done/                         # Completed jobs (permanent record)
│   └── failed/                       # Failed jobs (post-mortem)
├── issues/
│   ├── open.md                       # Current issues
│   └── closed.md                     # Resolved issues
└── .github/
    └── pull_request_template.md      # PR checklist
```

---

## Installation

### Step 1 — Add as git submodule

```bash
git submodule add https://github.com/idekker1/claude-pm-plugin .claude/plugins/pm
```

### Step 2 — Run the installer

```bash
bash .claude/plugins/pm/install.sh
```

The installer copies skills into `.claude/skills/` and commands into `.claude/commands/`,
then creates all missing project structure from templates. **Existing files are never
overwritten** — run it on any project at any stage.

### Step 3 — Initialize your project docs

Edit the generated files:

1. **`ROADMAP.md`** — Fill in § 1 (project vision) and § 2 (technology decisions)
2. **`.ai-agents/REFERENCE.md`** — Describe your architecture, schema, API endpoints
3. **`WORKFLOW.md`** — Update the lint and test commands for your stack

Then run `/setup` in Claude Code to verify everything is in place.

---

## Updating the Plugin

```bash
git submodule update --remote .claude/plugins/pm
bash .claude/plugins/pm/install.sh   # copies updated skills, skips existing project files
```

Skills are copied (not symlinked), so projects can customize them without affecting
the upstream plugin. Re-running the installer updates skills that haven't been
customized (new files are created, existing customized files are left alone).

---

## Notion Integration (Optional)

The PM skill can sync audit reports to a Notion workspace. To enable:

1. Add `plugin-config.yaml` to `.gitignore`
2. Edit `plugin-config.yaml`:
   ```yaml
   notion:
     enabled: true
     workspace_id: "your-workspace-id"
     bugs_database_id: "your-bugs-db-id"
     tasks_database_id: "your-tasks-db-id"
   ```
3. Run `/pm-sync` to test the connection

---

## Workflow Overview

### Feature development (full loop)

```
/architect "feature description"     # design + roadmap entry
/create-job "implementation task"    # queue job
/run-jobs                            # execute job
/pr                                  # ship branch
/run-jobs "PR merged #N"             # sync roadmap + docs
```

### Daily workflow

```
git checkout -b fix/bug-name
# ... fix code ...
/pre-commit                          # consistency check
git add -p && git commit -m "fix: ..."
/review src/changed/files            # deep review
/pr                                  # ship
```

### Project status

```
/pm                                  # branches, jobs, roadmap summary
/pm "what should I work on next?"   # next unblocked job with full criteria
```

---

## Convention-Based Paths

All skills use fixed paths — no per-project configuration needed:

| What | Where |
|------|-------|
| Roadmap | `ROADMAP.md` (repo root) |
| Technical reference | `.ai-agents/REFERENCE.md` |
| Job queue | `jobs/pending/`, `jobs/active/`, `jobs/done/`, `jobs/failed/` |
| Issue tracking | `issues/open.md`, `issues/closed.md` |
| PR template | `.github/pull_request_template.md` |
| Plugin config | `plugin-config.yaml` (repo root) |

---

## Skill Loop — How They Work Together

```
architect ──────────────────────────────────────────────┐
  Reads: ROADMAP.md, REFERENCE.md, jobs/               │
  Writes: ROADMAP.md (planned items [ ])               │
  Hands off: "run /create-job [description]"           │
                                                        │
create-job ─────────────────────────────────────────────┤
  Reads: ROADMAP.md, all job folders, issues/open.md   │
  Writes: jobs/pending/<id>-<slug>.md                  │
                                                        │
run-jobs ────────────────────────────────────────────────┤
  Reads: all job folders, ROADMAP.md, REFERENCE.md     │
  Dispatches: worker agent or code-reviewer skill      │
  Writes (on success): jobs/done/, ROADMAP.md [x],     │
    REFERENCE.md, issues/open.md → closed.md           │
                                                        │
pr ──────────────────────────────────────────────────────┤
  Reads: git state, WORKFLOW.md, PR template           │
  Runs: lint → commit → push → gh pr create            │
                                                        │
pm (post-merge) ─────────────────────────────────────────┘
  Reads: git log --merges, jobs/done/, ROADMAP.md
  Writes: ROADMAP.md final [x], REFERENCE.md, version ✓
```

---

## License

MIT
