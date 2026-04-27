---
name: create-job
description: >
  Dispatch a new job into the jobs/pending/ queue. Validates dependency order,
  roadmap alignment, and acceptance-criteria specificity before writing the job file.
  Invoke when you want to queue up a unit of work. Does NOT execute work — only
  produces a well-formed job .md file.
---

# create-job Skill

You are dispatching a new job into the job workflow system. This skill produces
a well-formed job file and writes it to `jobs/pending/`. It does **not** execute work.

---

## Execution Protocol

This skill runs under the **Antigravity Protocol** (`.claude/skills/antigravity/SKILL.md`).

- Read files silently using built-in tools
- This is a **Mode B (Fast Path)** task: read context → validate → write one file → confirm
- If validation raises a concern, stop and ask one specific question — don't guess
- No preambles on the confirm output — output job_id, type, criteria, branch name directly

---

## STEP 1 — Read context

Before evaluating the request:

0. Read `.ai-agents/PROJECT_CONTEXT.md` — use it as the authoritative project name and stack
   reference. If missing, note this and proceed with context from ROADMAP.md.

1. Read `ROADMAP.md` in full
2. List `jobs/pending/`, `jobs/active/`, `jobs/done/`, `jobs/failed/` — read frontmatter
   from each file (job_id, type, depends_on, priority, roadmap_ref)
3. Build a picture of:
   - Current version and what's left in it
   - Jobs in flight (active)
   - Jobs completed (done) — the set of satisfied dependencies
   - Jobs blocked or failed
   - The natural next item(s) on the roadmap given current state

4. Read `issues/open.md` if it exists. Use it to:
   - Check whether an issue already has a job assigned (avoid duplicate jobs)
   - Note relevant open issue IDs that this job will address (for Step 3)

   Do NOT read `issues/closed.md` (resolved issues are not relevant context for new jobs).

This context is required for the validation step. Do not skip it.

---

## STEP 2 — Validate the request

Evaluate the request against three criteria. If any concern is found, address it
before producing the job file. Do not silently create a job set up to fail.

### (a) DEPENDENCY ORDER

Does this job depend on a job that is still pending or active?

If yes, flag it explicitly:
> "Job X cannot start until job [N] is done. Job [N] is currently in pending/."

Offer to either:
- Create the job with the dependency noted (correct — the orchestrator enforces it at run time)
- Reorder if there is a genuine reason to proceed without the dependency

### (b) ROADMAP ALIGNMENT

Does this job correspond to a roadmap item?

If the request doesn't map to any roadmap item **and** isn't a clear bugfix or
housekeeping task, flag it:
> "This work doesn't appear in the roadmap. If it should be there, update the roadmap
> first via `/architect`. If it's a one-off, say so and I'll mark it accordingly."

### (c) SANITY CHECK

Is the request well-defined enough to act on?

A job with vague acceptance criteria produces unverifiable work. If the request is unclear:
- Ask targeted clarifying questions before producing the job file
- Propose concrete acceptance criteria drawn from the roadmap spec if one exists

"It works" is not an acceptance criterion. Each criterion must be independently
testable by someone who wasn't in the room when the job was written.

---

## STEP 3 — Write the job file

### Assign the job_id

Scan all four folders for existing job files. Find the highest existing `job_id`.
Increment by 1. Zero-pad to 3 digits (001, 002, etc.).

### Fill all frontmatter fields

```markdown
---
job_id: <next available, zero-padded>
type: <implementation | schema-change | docs-update | test | refactor | review>
depends_on: [<job_ids from validation step>]   # empty list [] if none
priority: <high | normal | low>
created: <today's date YYYY-MM-DD>
roadmap_ref: "<version — item title>"          # or "" if no roadmap item
---
```

**Type selection guide:**
- `implementation` — new feature or behaviour
- `schema-change` — any migration required
- `docs-update` — Markdown files only, no production code
- `test` — test additions/modifications with no production code changes
- `refactor` — code change with no behaviour change
- `review` — code review of completed work (dispatches code-reviewer skill)

### Task section

Clear, specific, references files by path. Specific enough to act on without further
clarification. Should include what needs to change, which files are involved, and any
hard constraints the project has documented in REFERENCE.md or WORKFLOW.md.

### Acceptance criteria

Testable, not vague. Each bullet must be independently verifiable.

Bad: "The feature works correctly."
Good: "Running `make backfill-nulls` re-queues all tracks with at least one NULL
column; `GET /api/jobs` shows new pending jobs for each re-queued track."

### Notes section

Flag known risks. Quote key lines from the relevant ROADMAP.md spec section. Reference
related jobs. Note files to read before starting.

If this job addresses one or more issues from `open.md`, list them:

    Addresses open issues: C1, M2

This is informational only. Do NOT update `open.md` here — PM updates it when the job
is marked done via run-jobs.

### File location

Write to: `jobs/pending/<job_id>-<slug>.md`

Slug: lowercase, hyphens, under 40 characters, describes the work.

Example: `jobs/pending/003-track-features-null-audit.md`

---

## STEP 4 — Confirm

Output:
- `job_id` assigned
- `type`
- `depends_on` list (and what each dependency is)
- The acceptance criteria list (for verification before the job runs)
- **Suggested branch name** — derive from job type:

  | Job type | Branch prefix |
  |----------|---------------|
  | `implementation` | `feature/` |
  | `schema-change` | `feature/` |
  | `refactor` | `refactor/` |
  | `docs-update` | `docs/` |
  | `test` | `chore/` |
  | `review` | N/A — no branch needed |

  Rules: lowercase, hyphens only (no underscores), under 50 characters total.
  Example: `feature/user-authentication`

- **Open issues addressed**: list issue IDs from open.md that this job will resolve,
  or "none"
- A plain summary of any pushback noted during validation

If pushback was significant, show the full draft job file and ask for confirmation
before writing it to disk.
