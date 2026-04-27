---
name: run-jobs
description: >
  Orchestrate the job workflow: pick up the next unblocked job from jobs/pending/,
  run compliance checks, dispatch to the right worker agent, manage the lifecycle
  (pending → active → done/failed), and update documentation on completion. Invoke
  manually — does not run autonomously. Also handles the PR closure flow when invoked
  with "PR merged" or "I closed PR #N".
---

# run-jobs Skill

You are the job workflow orchestrator. You pick up one job at a time, dispatch it
to the right worker, manage its lifecycle, and keep documentation in sync.

This skill is invoked manually. It does not run autonomously.

---

## Execution Protocol

This skill runs under the **Ultimate Protocol** (`.claude/skills/ultimate-protocol/SKILL.md`).

- Zero conversational English during execution
- All file reads, queue surveys, and compliance checks happen silently via tools
- The only text output during a run is targeted questions when a pushback gate requires confirmation
- On completion of each STEP, output is the next tool call — not a summary
- On full run completion (STEP 6 or STEP 7), output the JSON status block:
  ```json
  {"status": "success | failed_needs_review", "job_id": "NNN", "files_mutated": [...], "roadmap_updated": true | false, "review_recommended": true | false}
  ```
- If a pushback gate is hit, output one question only — no prose

---

## STEP 1 — Survey state

Read all four folders and build a complete picture:

1. **`jobs/active/`** — If any file is here, a job is already in flight.
   - Report: which job is active, its job_id, type, and roadmap_ref
   - Ask: "Continue waiting, or force-reset the stale lock?"
   - If force-reset confirmed: move the file back to `jobs/pending/`, append a warning
     note recording the force-reset date and reason, then proceed
   - Do not proceed past this point until the active slot is clear

2. **`jobs/pending/`** — Parse frontmatter from every file. Build list of:
   `{job_id, type, priority, depends_on, roadmap_ref}`

3. **`jobs/done/`** — List filenames only. Extract job_ids from filename prefix
   (e.g. `003-genre-set-building.md` → `003`). Do **not** read file contents.

4. **`jobs/failed/`** — List filenames only. Extract job_ids from filename prefix.

---

## STEP 2 — Select next job

From the pending list:

1. **Filter**: remove jobs where any `depends_on` job_id is NOT in the done set
2. **From the unblocked set**: select by priority (high > normal > low)
3. **Tie-break**: lower job_id wins (older jobs first)

If no unblocked jobs exist:
- List every blocked job with its specific blocker:
  > "Job 005 is blocked — depends_on [003], which is in failed/"
- Stop. Do not proceed.

---

## STEP 3 — Order check (pushback gate)

Re-run the dependency and roadmap-order validation from create-job Step 2.

This catches jobs that were valid when created but are now out of order because
project state has changed.

If a concern is found, present it and ask for explicit confirmation before proceeding.

Do not proceed without a clear answer.

---

## STEP 4 — Pre-execution compliance check (double pass)

Read the selected job file in full. Then run two passes.

### Context preload

Before either pass, read `.ai-agents/PROJECT_CONTEXT.md` — use it as the authoritative project
name and stack reference when constructing the dispatch prompt in STEP 5. If missing, proceed
with context from ROADMAP.md and REFERENCE.md only.

### Pass 1 — Against ROADMAP.md

- Does the job's Task match the roadmap item it references?
- Do the acceptance criteria in the job match those in the ROADMAP.md spec?
  - Job less strict than roadmap → flag as a quality gap
  - Job stricter than roadmap → flag as potential scope creep
- List any project conventions that apply to this job (from REFERENCE.md and WORKFLOW.md)

### Pass 2 — Against REFERENCE.md and project conventions

- Which files will this job touch? Cross-reference REFERENCE.md to confirm the worker
  agent starts with accurate knowledge of current state.
- Does this job touch any known risk areas documented in the audit history?
- Schema change job? Confirm a migration step is in the acceptance criteria.

### Output

Output a **compliance summary**: what was checked, what passed, what was flagged.
This summary is prepended to the dispatch context sent to the worker agent.

---

## STEP 5 — Dispatch

1. **Move** the job file from `jobs/pending/` → `jobs/active/`

2. **Construct the dispatch prompt** for the worker agent. Include:
   - Full job file content
   - Compliance summary from Step 4
   - Relevant ROADMAP.md sections (quoted)
   - Relevant REFERENCE.md sections (file paths, schema state, known constraints)
   - Branch naming instruction — map job type to branch prefix:

     | Job type | Branch prefix |
     |----------|---------------|
     | `implementation` | `feature/` |
     | `schema-change` | `feature/` |
     | `refactor` | `refactor/` |
     | `docs-update` | `docs/` |
     | `test` | `chore/` |
     | `review` | N/A — no branch needed |

     Rules: lowercase, hyphens only (no underscores), under 50 characters total.

3. **Worker agent routing by job type:**

   | Type | Worker |
   |------|--------|
   | `implementation` | General Claude Code agent |
   | `refactor` | General Claude Code agent |
   | `test` | General Claude Code agent |
   | `schema-change` | General Claude Code agent |
   | `docs-update` | Read/write only (no code execution) |
   | `review` | `code-reviewer` skill |

---

## STEP 6 — On worker completion

### SUCCESS

1. **Append `## Result` section** to the job file:
   ```markdown
   ## Result

   completed: YYYY-MM-DD
   branch: <branch name used>
   pr: <PR number or "N/A">
   summary: <one paragraph: what was done, any deviations from the plan>
   ```

2. **Move** `jobs/active/` → `jobs/done/`

3. **Roadmap sync**: check if the completed job maps to a `[ ]` item in ROADMAP.md.
   If yes, mark it `[x]` and update the "Last updated" date.

   Also check REFERENCE.md for needed updates:
   - New or changed API endpoint? → Update the endpoints section
   - Schema migration? → Update the schema section
   - New or changed integration tool? → Update the tools section
   - New service or infrastructure change? → Update the architecture section

4. **Review recommendation**: if the job type was `implementation`, `schema-change`,
   or `refactor` AND any of these apply:
   - Change to the core analysis or ML pipeline
   - Change to database query files
   - Change to schema migrations
   - More than 10 files changed

   Then RECOMMEND a review job — do **not** create it automatically. Output:
   > "A code review is recommended for this change. Run:
   > `/create-job type=review depends_on=[<job_id>] 'Review implementation of <description>'`"

5. **Issue registry update**: Check the completed job file's Notes section for a line
   matching `Addresses open issues: <IDs>`. For each issue ID:

   a. Read `issues/open.md`. Find the row with that ID.
   b. Remove that row from `open.md`.
   c. Append the row to `issues/closed.md` with Closed date and Job # filled.
   d. Update the "Last updated" date at the top of both files.
   e. If Notion is enabled (`plugin-config.yaml notion.enabled: true`): update the
      Notion bug entry status to "Fixed". This step is non-blocking — if it fails,
      log the failure but do not fail the job completion.

6. **Report**: job_id, branch created, ROADMAP items updated, issues moved to closed.md,
   Notion status updates (if any), review recommendation (if any), next unblocked job.

### FAILURE

1. **Append `## Failure` section** to the job file:
   ```markdown
   ## Failure

   failed: YYYY-MM-DD
   reason: <what went wrong — specific error, conflict, or blocker>
   next_step: <retry | abandon | rewrite>
   ```

2. **Move** `jobs/active/` → `jobs/failed/`

3. **Do NOT update ROADMAP.md**

4. **Report**: what failed, `next_step` recommendation:
   - `retry` — failure was environmental/transient; job spec is correct
   - `abandon` — work is no longer relevant; leave in failed/
   - `rewrite` — job spec was the problem; create a new job that supersedes this one

---

## STEP 7 — PR closure flow

Triggered when the user says "PR merged", gives a PR number, or says "I closed PR #N".

1. Run `git log --merges --oneline -5` to identify what shipped
2. Cross-reference with `jobs/done/` to find the corresponding job by matching the
   branch name in its `## Result` section
3. Run full roadmap and docs sync:
   - Verify ROADMAP.md items are correctly marked `[x]`
   - Check if REFERENCE.md needs updating (new endpoints, schema changes, new tools)
   - Run version string consistency check across ROADMAP.md and REFERENCE.md
4. If all items in a version section are now `[x]`:
   - Update the version header to include `✓` (`### V1.1 — Hardening · ✓`)
   - Update the "Current version" string at the top of ROADMAP.md
5. Report: what was synced, any doc gaps found, next unblocked job
