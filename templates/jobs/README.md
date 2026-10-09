# Jobs

The dispatch queue. One job is one agent, one worktree, one branch, one PR.

Jobs are **committed**. They are coordination state for parallel agents and the record of what
was done — both worthless if they live on one machine only. Do not add them to `.gitignore`.

```
jobs/pending/   ready, or waiting on a dependency
jobs/active/    in flight
jobs/done/      completed — permanent record
jobs/failed/    attempted and failed — kept for the post-mortem
```

## Frontmatter

See `job-template.md` for the full form. Two fields do the real work:

### `touches` — the concurrency primitive

Every file the job may write, including tests.

The orchestrator **refuses to dispatch two jobs whose `touches` overlap.** This is how parallel
agents avoid merge conflicts: the filesystem is partitioned up front rather than reconciled
afterwards. Under-declaring it is the one way to break the guarantee — and it breaks it for every
other job in the batch, not just this one.

Shared files — `ROADMAP.md`, `CHANGELOG.md`, `decisions/`, `features/`, `jobs/` — are **never** in
`touches`. They are written only by the orchestrator, after merge, serially.

If the work cannot be scoped to a declarable file set, it is too big to be one job.

### `review`

`human` blocks for confirmation even with a green test suite. Required when any `touches` entry
appears under `critical_paths` in `CLAUDE.md`, when the job touches a project invariant, or when
it changes a configuration schema. `auto` is for test-only and docs work. When in doubt, `human`.

## Lifecycle

`pending/` → `active/` on dispatch → `done/` with a `## Result` section (date, branch, PR,
summary), or `failed/` with a `## Failure` section (date, reason, `next_step: retry | abandon |
rewrite`).

A job whose rebase conflicts, or whose test run goes red, **returns to `pending/`** with a note
and is redone by an agent against the new base. Conflicts are not hand-resolved on an agent's
behalf.

Jobs are never deleted from `done/`.

## Ids

Feature-scoped (`F03-J02`) when the work belongs to a feature; otherwise the next free
zero-padded integer. Prefer feature-scoped: a single global counter is a race as soon as two
agents create jobs at once.
