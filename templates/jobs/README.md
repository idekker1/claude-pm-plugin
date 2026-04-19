# Job Workflow System

The `jobs/` folder is the dispatch queue for all planned work on this codebase.
Each job is a Markdown file with structured frontmatter describing a discrete unit of
work. Jobs move through a four-stage lifecycle managed by the `create-job` and
`run-jobs` skills.

---

## Folder Structure

```
jobs/
├── pending/    # Jobs waiting to be picked up
├── active/     # Exactly one job running at a time (acts as a lock)
├── done/       # Completed jobs (permanent record)
└── failed/     # Jobs that failed (kept for post-mortem and retry decisions)
```

- **pending/** — jobs that are ready to run (all dependencies met) or waiting on
  dependencies. The orchestrator resolves dependencies at selection time.
- **active/** — at most one file here at a time. Its presence means a job is in
  flight. If a job was interrupted and left here, it is a stale lock.
- **done/** — immutable archive. Jobs are never deleted from done/.
- **failed/** — jobs that were attempted and failed. Kept for context; a failed job
  may be retried or abandoned.

---

## Job File Format

### File naming

```
<job_id>-<short-slug>.md
```

Examples: `001-setup-database.md`, `003-add-search-endpoint.md`

The slug is lowercase, hyphens only, under 40 characters.

### Standard frontmatter (all jobs)

```markdown
---
job_id: 001
type: <implementation | schema-change | docs-update | test | refactor | review>
depends_on: []          # list of job_ids this job requires in done/ first
priority: <high | normal | low>
created: YYYY-MM-DD
roadmap_ref: "V0.1 — Initial database setup"   # or empty string if no roadmap item
---

## Task

What needs to be done, specific enough to act on without further clarification.
References files by path. No ambiguous scope.

## Acceptance criteria

- Concrete, testable condition 1
- Concrete, testable condition 2
- ...

"It works" is not an acceptance criterion. Each bullet must be independently verifiable.

## Notes

Optional: risks, constraints, files to read before starting, related jobs, quoted
sections from ROADMAP.md spec.

If this job addresses open issues:
    Addresses open issues: C1, M2
```

### Additional section for done/ jobs

```markdown
## Result

completed: YYYY-MM-DD
branch: feature/slug-here
pr: 42          # or "N/A" for non-code jobs
summary: One paragraph describing what was done, including any deviations from the plan.
```

### Additional section for failed/ jobs

```markdown
## Failure

failed: YYYY-MM-DD
reason: What went wrong — specific error, conflict, or blocker.
next_step: <retry | abandon | rewrite>
```

---

## Creating a Job

Use the `/create-job` skill. It will:

1. Read the roadmap and existing jobs to understand project state
2. Validate the request for dependency order, roadmap alignment, and specificity
3. Assign the next job_id and write the file to `jobs/pending/`
4. Push back constructively if the request is unclear or out of order

---

## Running Jobs

Use the `/run-jobs` skill. It will:

1. Survey all four folders
2. Select the highest-priority unblocked job
3. Run a compliance check against ROADMAP.md and .ai-agents/REFERENCE.md
4. Dispatch to the appropriate worker agent
5. Manage the lifecycle: move to active/, then done/ or failed/
6. Update ROADMAP.md and REFERENCE.md on success

**Only one job runs at a time.** Invoke `/run-jobs` again to pick up the next job.

---

## Dependency Resolution

A job is **unblocked** when every job_id in its `depends_on` list is in `jobs/done/`.

A job is **blocked** when any `depends_on` job_id is in pending/, active/, or failed/.

The orchestrator never skips a dependency silently. If a blocked job is the only
option, it reports the specific blocker and stops.

---

## Lifecycle

```
Created by /create-job
       │
       ▼
   pending/          ← waiting; may be blocked by depends_on
       │
       │  /run-jobs selects it
       ▼
   active/           ← exactly one file; signals a job is in flight
       │
       ├──── success ──▶  done/    + ROADMAP.md updated
       │
       └──── failure ──▶  failed/  + failure reason logged
```

---

## Stale Lock Scenario

If a job is in `active/` but no agent is running (session was interrupted):

When `/run-jobs` is invoked and finds a file in `active/`:
1. It reports which job is active and when it was last modified
2. It asks: "Continue waiting, or force-reset the stale lock?"
3. If you confirm force-reset: the file is moved back to `pending/` with a warning

**Never manually move files between folders** — the skills maintain invariants that
a manual move will break.

---

## PR Closure Flow

When a PR is merged, invoke `/run-jobs` with "PR merged #N". The skill will:

1. Identify what shipped via `git log --merges`
2. Find the corresponding `done/` job by branch name in `## Result`
3. Verify ROADMAP.md items are correctly marked `[x]`
4. Check if REFERENCE.md needs updating
5. Report: what was synced, any doc gaps found
