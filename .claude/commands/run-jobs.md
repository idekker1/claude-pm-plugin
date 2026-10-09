Execute the next unblocked job from jobs/pending/ using the run-jobs skill.

$ARGUMENTS may be:
- Empty: pick up and run the next unblocked job
- "PR merged #N" or "I closed PR #N": trigger the PR closure flow (sync roadmap + docs)

The skill will:
1. Survey all four job folders (pending, active, done, failed)
2. Select the highest-priority unblocked job (by priority, then by lower job_id)
3. Run a compliance check against ROADMAP.md and .ai-agents/REFERENCE.md
4. Move the job to jobs/active/ and dispatch it to the right worker
5. On completion: move to done/, update ROADMAP.md, update REFERENCE.md
6. On failure: move to failed/, log the reason and next_step

Only one job runs at a time. Invoke again to pick up the next job.
