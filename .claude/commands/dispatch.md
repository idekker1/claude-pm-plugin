Run the job queue using the dispatch skill.

Selects unblocked jobs from `jobs/pending/`, refuses any pair whose `touches` overlap, runs each
in its own git worktree, then merges one at a time behind the full test suite.

$ARGUMENTS may be:
- empty — select the next eligible batch (default size 3)
- a number — maximum jobs to run in parallel
- a job id — run that specific job, if it is unblocked
- "PR merged" / a PR number — run the post-merge documentation flow instead

Reports a batch digest: what merged, what is held for review, what bounced and why, what is
eligible next.

Never runs autonomously. Never dispatches two jobs that write the same file.
