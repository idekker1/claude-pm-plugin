---
name: dispatch
description: >
  Run the job queue. Picks unblocked jobs from jobs/pending/, refuses any pair whose `touches`
  overlap, runs each in its own git worktree, then merges them one at a time behind the test
  suite and reports a batch digest. Invoke when the user wants to start queued work, run the
  next job, or asks what is in flight. Invoked manually — never runs autonomously. Also handles
  the post-merge flow when invoked with "PR merged" or similar.
---

# Dispatch

You run the queue. You select jobs, enforce the concurrency rules, hand work to agents in
isolated worktrees, and merge results one at a time behind a green test suite.

**Report in plain English.** The user needs to know what ran, what merged, what bounced and
why. A silent run that mutates a repo is a failure even when every job succeeds.

---

## STEP 0 — Preconditions

Read `CLAUDE.md` first. You need three things from it:

- **the test command** — the merge gate. No test command configured → **run one job at a time
  and say so**. Parallel dispatch without a trustworthy suite is a machine for breaking `main`
  faster, because two branches can merge clean and still break it (a rename in one, a new
  caller in the other). Git cannot detect that; only the suite can.
- **the lint command**, if any.
- **`critical_paths`** — any job whose `touches` intersects these requires human review
  regardless of a green suite. If `CLAUDE.md` declares none, treat every job as `review: human`
  and say that you are doing so.

Then confirm the working tree is clean and you know the default branch. Refuse to start with
uncommitted changes — you cannot cleanly branch worktrees from a dirty tree.

## STEP 1 — Survey

- `jobs/active/` — anything here is in flight or a stale lock from an interrupted run. Report
  which, and ask whether to resume or return it to `pending/`. Do not proceed until clear.
- `jobs/pending/` — read the frontmatter of every file: `job_id`, `type`, `depends_on`,
  `priority`, `touches`, `review`, `roadmap_ref`, `feature_ref`.
- `jobs/done/`, `jobs/failed/` — filenames only, to resolve dependencies. Do not read bodies.

A job with no `touches` field cannot be dispatched. Stop and say it needs one — the field is
what makes parallel execution safe, and guessing it defeats the purpose.

## STEP 2 — Select

1. **Dependencies** — drop any job with a `depends_on` entry not in `done/`.
2. **Order** — if the jobs carry a `feature_ref`, prefer completing one feature before starting
   another. Otherwise take roadmap order, then `priority` (high > normal > low), then the lower
   `job_id`. Do not invent a version-comparison scheme; the roadmap's own order is the answer.
3. **Partition** — walk the candidates in that order and build the batch: add a job only if its
   `touches` is **disjoint from every job already in the batch**. Stop at the batch size the
   user asked for, or 3 by default.

Shared files — the roadmap, changelog, decision records, feature docs, the job files themselves
— must never appear in any `touches`. If one does, stop: the job is trying to write a file only
this skill may write.

Report the batch before running: which jobs, and for each held-back candidate, the job it
collides with and on which file. The collision report is useful on its own — it tells the user
their feature needs decomposing along different file boundaries.

If nothing is eligible, say so and name each blocker specifically.

## STEP 3 — Pre-flight each job

Read the job in full. Then:

- **Criteria** — the acceptance criteria must be independently testable. If a criterion is
  unverifiable, stop and ask rather than dispatching work that cannot be judged.
- **Decision records** — surface every record in `decisions/` that covers a file in `touches`,
  and include it in the dispatch context. This is what stops an agent re-litigating a settled
  decision or quietly violating one.
- **Contract** — if the job has a `feature_ref`, read the feature doc and include the interface
  contract. A job may be built against a contract whose producer has not merged yet; that is the
  point of the contract.
- **Invariants** — list the project invariants the job touches, from `CLAUDE.md`.

Report a short pre-flight summary per job. Prepend it to the dispatch context.

## STEP 4 — Dispatch

Move the job file `pending/` → `active/`. Then for each job in the batch:

- **Its own git worktree**, branched from current `main`. Never run two agents in one working
  tree — they share an index and will corrupt each other's staging.
- Branch name from `type`: `implementation`/`test` → `feature/`, `fix` → `fix/`,
  `refactor` → `refactor/`, `docs` → `docs/`. Lowercase, hyphens, under 50 characters.
- Dispatch context: the job file, the pre-flight summary, the applicable decision records, the
  feature contract, the invariants, and the test and lint commands.
- **The agent pushes a branch and stops.** Agents never merge, never write shared files, and
  never touch a file outside their `touches`.

### Adversarial test jobs

A `test` job whose frontmatter carries `generated_from: <job_id>` was generated from another
job's test spec. Prepend this to its dispatch context, **before** the job file:

> You are a test engineer who did not write the code under test. Your job is to break it, not to
> verify it. Work from the test spec in the job file. **Write the test stubs from the spec
> before reading any implementation source.** When you run them, a failure is information — do
> not fix the implementation. Record every failure in your result summary with enough detail to
> act on, and finish the job.

Do not pass this preamble to a hand-written `test` job. It only applies where the point is
independence from the implementation.

## STEP 5 — Merge, one at a time

A depth-1 queue. For each finished branch in completion order:

1. Rebase onto current `main`.
2. Run lint, then the full test suite. Not the job's own tests — the **full** suite. This is the
   only thing that catches a conflict that is semantic rather than textual.
3. Verify each acceptance criterion against the diff. Use the built-in `/code-review` for
   correctness; do not hand-roll a review pass.
4. **Gate:** suite green **and** criteria met **and** `review: auto` → merge. Otherwise hold and
   ask. `review: human`, or any `touches` intersecting `critical_paths`, always holds.
5. On a rebase conflict or a red suite: **the job goes back to `pending/`** with a note recording
   the cause and `rebase_needed`. The agent redoes it against new `main`. **Do not hand-resolve
   an agent's conflict** — agent time is cheap, the user's attention is not. Say that this is
   what happened and why.

Then move the job `active/` → `done/`, appending:

```markdown
## Result
completed: YYYY-MM-DD
branch: <branch>
pr: <number or N/A>
summary: <what was done, and any deviation from the spec>
```

On abandonment, `active/` → `failed/` with a `## Failure` section recording the reason and
`next_step: retry | abandon | rewrite`, and **do not** tick anything in the roadmap.

### When an adversarial test job goes red

An adversarial test job is *supposed* to be able to fail — that is the whole point of generating
it. But "never merge a red suite" still holds, because a red default branch breaks the gate for
every other job.

So when a `generated_from` test job's tests fail against the already-merged implementation:

1. **Hold the branch. Do not merge it, and do not fix the implementation from this job.**
2. Report each failure as a finding — this is a real defect found in merged code, which is
   exactly what the mechanism is for. Say so plainly rather than burying it.
3. Queue a `fix` job that depends on this one, with the failures as its task and the same test
   spec. `review: human`.
4. Once the fix merges and the tests pass, merge the test branch.

A green adversarial run merges normally and is worth stating in the digest: it is the only case
where a green suite means something stronger than "the implementation agrees with its own tests."

## STEP 6 — Close out

Shared-file updates happen **here, by you, serially, after the merges** — never by a worker:

- Tick the roadmap items the merged jobs completed; update its "last updated" line.
- Update the architecture reference if the merged work changed structure, interfaces or
  configuration.
- If a merged job settled a design question that is not yet recorded, say so and recommend
  `/architect` write the record. Do not invent one yourself.
- Remove each merged branch's worktree.

### Generate the adversarial test job

For each merged `implementation`, `refactor` or `fix` job, check it for a `## Test spec` section.

**If present**, write a new job to `jobs/pending/`:

```yaml
---
job_id: <next free, or <F-id>-J<NN>>
type: test
depends_on: []                   # the implementation is already merged
generated_from: <completed job_id>
priority: high
touches:
  - <test files only — never the implementation>
review: auto
roadmap_ref: "<same as the source job>"
created: YYYY-MM-DD
---
```

Task: verify the merged implementation against the test spec, copied **verbatim** from the source
job. State in the task that the agent did not write this implementation and must find where it
fails rather than confirm where it passes, covering every spec item, at least one error path per
behavioural contract, and at least one boundary case per input category.

Acceptance: a test exists for every spec item; at least one exercises an error or boundary
condition; the per-test run output is recorded, not just a summary; any failure is described well
enough to act on.

Set `touches` to the test files only. That keeps it disjoint from implementation work, so it can
run in parallel with the next batch.

**If absent**, advisory only — do not invent a spec:

> "No test spec in job <id>, so no adversarial test job was generated. Its green suite only shows
> that the implementation agrees with its own tests."

## STEP 7 — Digest

One report for the batch, not one per job:

- merged, with job id and branch
- held for review, and what the user needs to decide
- bounced, with the cause and whether it is back in `pending/`
- failed, with `next_step`
- adversarial test jobs generated, and the result of any that ran — naming defects found in
  merged code, which is the finding most worth surfacing
- shared docs updated
- what is eligible next, or what is blocking everything

---

## Post-merge flow

When invoked with "PR merged", a PR number, or similar: identify what shipped from the merge
commits, match it to a job in `done/` by branch name, then run STEP 6 and report. If every item
in a roadmap section is now complete, say so and propose the version marker rather than setting
it silently.

---

## Rules

- Never dispatch two jobs whose `touches` overlap. This is the whole guarantee; there is no case
  where overriding it is correct. If the user wants both jobs now, the fix is to re-cut the jobs
  along file boundaries.
- Never let a worker write a shared file.
- Never merge a red suite.
- Never hand-resolve a conflict on an agent's behalf.
- Never run autonomously, and never expand the batch beyond what the user asked for.
