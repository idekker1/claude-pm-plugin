# Changelog

## v2.0.0 — 2026-10-09

**Breaking.** Reoriented from a job tracker into a multi-agent orchestrator. 11 skills → 6,
12 commands → 4, 6 required project files → 3.

### Why

v1's job system did lifecycle bookkeeping — folders, a version gate, a `priority` sort. At one
agent that is adequate. At three it is not, because the problems that matter are concurrency
problems v1 had no mechanism for:

- `jobs/*/*` was gitignored, so the dependency resolver read `done/` as empty in any fresh clone
  or worktree, and the "permanent archive" `jobs/README.md` promised did not exist.
- `job_id` was "scan all folders, find the highest, increment" — a race the moment two agents
  queue work.
- `active/` was described as a lock but had no enforcer.
- Workers wrote `ROADMAP.md` on completion, guaranteeing a conflict per job per batch.
- Worktrees were never mentioned, so parallel agents shared one index.
- The version gate compared versions lexicographically: `V1.10` sorted below `V1.9`.
- Nothing ran the test suite between rebase and merge, so no mechanism could catch a conflict
  that was semantic rather than textual.

v1 also carried the codebase it was extracted from: review triggers hardcoded to "ML pipeline",
"database query files" and "schema migrations". In a project with no database, none could fire —
the review-recommendation feature was dead logic that looked installed.

### Added

- **`dispatch` skill** — replaces `run-jobs`. Refuses to dispatch two jobs whose `touches`
  overlap, runs each in its own git worktree, merges one at a time behind the full test suite,
  bounces conflicts back to `pending/` for an agent to redo, and reports a batch digest in plain
  English.
- **`touches:` job field** — every file a job may write. The partition primitive: conflicts are
  prevented rather than resolved.
- **`review: auto | human` job field** — paired with `critical_paths` in `CLAUDE.md`. A
  mechanical merge gate with a declared escape, replacing v1's hardcoded risk list.
- **`decisions/`** — architecture decision records. The layer v1 lacked: `architect` had nowhere
  to put design reasoning but a row in the roadmap's table, so rejected alternatives and
  consequences were lost and the next agent re-litigated them. Accepted records are immutable;
  changing a decision means superseding it.
- **`features/`** — module boundaries and the **interface contract** between sibling jobs.
  Required only when 2+ jobs have disjoint `touches`, because the contract is what converts a
  dependency into a parallel opportunity. Not a grouping layer; the roadmap already groups.
- **`CLAUDE.md` template** — carries the project's constraints, test and lint commands, and
  `critical_paths`. Replaces `.ai-agents/PROJECT_CONTEXT.md`, which only worked if a skill
  remembered to read it.
- **`ARCHITECTURE.md` template** — replaces `.ai-agents/REFERENCE.md`. At the repo root, no
  dot-folder, no space in the path. Includes a "known gaps" section, which is the part that
  keeps such a file honest.
- **Stack-matched CI workflow templates** — `setup` detects the stack and writes the matching
  one, or writes none and says so. One template for all languages would emit a permanently red
  check.
- **`genericity.yml`** — the plugin's own CI. Fails on absolute paths, project vocabulary,
  references to removed v1 scaffolding, duplicate skill names, and any skill or command
  `install.sh` promises but doesn't ship. Would have failed v1 at seven locations.
- **Adversarial test generation** — carried forward from `ab32e36` and now actually distributed.
  `create-job` gates `implementation`/`refactor`/`fix` jobs on a behavioural `## Test spec`;
  after such a job merges, `dispatch` generates a `test` job from that spec verbatim and
  dispatches it with a preamble instructing the agent that it did not write the code, must write
  stubs from the spec before reading the implementation, and must record failures rather than fix
  them.

  This matters more in v2 than it did in v1: the merge gate auto-merges on a green suite, so if
  the implementing agent also writes the tests, green means only that the code agrees with
  itself. A red adversarial run holds its branch, reports the failures as defects found in merged
  code, and queues a `fix` job — "never merge a red suite" still holds.
- **`.claude/` drift check** in CI. This repo dogfoods itself, and in v1 the two copies diverged:
  the adversarial-test feature above was written into `.claude/skills/create-job` and
  `.claude/skills/run-jobs` but never into `skills/`, so it worked here and reached **no**
  project that installed the plugin. Nothing noticed for four months. CI now fails if the
  self-installed copy differs from the distributed one, or holds a skill no longer shipped.
- **v1 → v2 migration notes** in `update-skills.sh`, plus an offer to delete the dropped skills.

### Changed

- **`setup`** — 435 → ~130 lines. Creates 3 files and 3 directories instead of 12 files. Detects
  the stack rather than assuming it; asks when detection is ambiguous instead of writing a
  confident wrong answer. Refuses to scaffold parallel dispatch where no test suite exists.
- **`create-job`** — keeps the specification gate verbatim (*"'It works' is not an acceptance
  criterion"*), which is the best thing v1 had and matters more at three agents than at one.
  Now requires `touches`, sets `review`, uses feature-scoped ids, and **references** acceptance
  criteria instead of copying them. Dropped the global counter and the version gate.
- **`architect`** — writes the decision record, and a feature doc only when the depth rule calls
  for one. Must cite the records its design rests on.
- **`pm`** — 242 → ~110 lines. Now explicitly the *sole* writer of shared documents, post-merge,
  serially. Dropped Notion sync and job-queue reporting.
- **`pr`** — reads lint and test commands from `CLAUDE.md`; a red suite stops the ship; flags a
  `critical_paths` diff. No longer hardcodes a model name in the co-author line.
- **Jobs, features and decisions are committed.** `install.sh` and `update-skills.sh` warn if
  `.gitignore` excludes them.

### Fixed

- **`install.sh` copied no template files on macOS.** The template map used a bash 4
  associative array (`declare -A`); macOS ships bash 3.2, which parses `["key"]=` as an
  arithmetic subscript and fails with "operand expected". The script then continued and
  reported success, so every macOS install produced the directories and **none** of
  `ROADMAP.md`, `REFERENCE.md`, `WORKFLOW.md`, `plugin-config.yaml` or the PR template — a set
  of empty folders that looked like the plugin had never been set up. Replaced with a
  newline-delimited `src|dest` list that works on bash 3.2. This is why every skill in v1
  referenced files that did not exist.
- `install.sh` now reports a missing template instead of silently skipping it, and creates the
  destination's parent directory.

### Removed

- **`run-jobs`** → `dispatch`.
- **`code-reviewer`, `code-guardian`** — superseded by the host's built-in `/code-review`,
  `/security-review` and `/simplify`. 463 lines of competing review instructions, versus zero to
  maintain.
- **`antigravity`** — a dead redirect to v2.0 that declared the *same* frontmatter `name` as the
  skill it pointed at, so two skills claimed `antigravity-protocol`.
- **`antigravity2.0`** — fought the harness: banned `grep`/`cat`/`ls`, which are the efficient
  path for codebase surveys, and mandated a declaration line before every tool call. Its one good
  idea — *stop and ask rather than guess* — is now two lines of the `CLAUDE.md` template.
- **`ultimate-protocol`** — mandated zero English output and JSON-only completion blocks, and
  instructed the agent to "fix the code internally without asking the user". `run-jobs` and
  `setup` both ran under it, so the two most mutating skills were the two that could not report
  what they had done. Incompatible with a batch-digest review model, and with any user who wants
  to know what their agents did.
- **Notion sync** — and `plugin-config.yaml` with it.
- **`WORKFLOW.md`** — lint, test and branch rules live in `CLAUDE.md`, which is actually loaded.
- **`.ai-agents/`**, **`issues/`**, and the one-line wrapper commands `/setup`, `/pm`, `/review`,
  `/pre-commit`, `/audit`, `/pm-sync`, `/pm-update-roadmap`, `/pm-review-trigger`.

### Migration

1. `bash .claude/plugins/pm/update-skills.sh` — installs the v2 skills, offers to delete the
   dropped ones, and lists what needs doing by hand.
2. `/setup` — writes `CLAUDE.md` and `ARCHITECTURE.md`, and a CI workflow if the stack matches.
3. Move `.ai-agents/REFERENCE.md` content into `ARCHITECTURE.md`; move `WORKFLOW.md`'s commands
   into `CLAUDE.md`. Delete both, plus `plugin-config.yaml` and `issues/`.
4. Remove any `.gitignore` rule covering `jobs/`, `features/` or `decisions/`.
5. Add `touches` and `review` to every job already in `pending/` — `dispatch` refuses to run a
   job without `touches`, by design.
6. `/architect` — record the decisions already implicit in the codebase, starting with the ones
   someone has already argued about twice.

---

## v1.0.0 — 2026-04-19

Initial release. Extracted and generalized from the MLAI/SLAI project.

Skills: `setup`, `pm`, `architect`, `code-reviewer`, `code-guardian`, `pr`, `create-job`,
`run-jobs`, `antigravity`, `antigravity2.0`, `ultimate-protocol`.

Templates: `ROADMAP.md`, `.ai-agents/REFERENCE.md`, `WORKFLOW.md`, `plugin-config.yaml`,
`jobs/README.md`, `jobs/job-template.md`, `issues/open.md`, `issues/closed.md`,
`.github/pull_request_template.md`.
