# Claude PM Plugin

Project management, design records and multi-agent orchestration for any codebase.

**v2** is a scope-down and a reorientation. v1 was a tracker that did lifecycle bookkeeping;
v2 is an orchestrator that can run **2–3 agents in parallel on one repo** without producing merge
conflicts or a broken default branch. 11 skills became 6, 12 commands became 4, and six required
project files became three.

---

## The idea

**The roadmap is the system. Skills serve it; they don't duplicate it.**

Four layers, and no fact lives in two of them:

| Layer | The question it alone answers | Required when |
|---|---|---|
| `ROADMAP.md` | what, in what order | always |
| `decisions/NNNN-*.md` | why this way, what was rejected, what it costs | any non-trivial design call |
| `features/FNN-*.md` | module boundaries and the **interface contract** | only when 2+ jobs have disjoint `touches` |
| `jobs/*.md` | one agent, one worktree, one PR, testable criteria | always |

Depth scales with the work. A feature doc is warranted only when parallelism is actually
possible — which is exactly when the contract is needed. Single-job work, or multi-job work that
collides on one file, references the roadmap directly.

## How parallelism works: partition, don't merge

Each job declares `touches` — every file it may write. **The orchestrator refuses to dispatch two
jobs whose `touches` overlap.** Conflicts become impossible rather than resolvable.

- Shared files (roadmap, changelog, `decisions/`, `features/`) are written **only** by the
  orchestrator, after merge, serially. Workers never touch them.
- Each job runs in **its own git worktree**, branched from a fresh default branch.
- Agents never merge. They push a branch and stop.
- Merging is a **depth-1 serial queue**: rebase → full test suite → merge → next.
- On a conflict or a red suite, the job returns to `pending/` and **an agent redoes it**. You
  never hand-resolve an agent's conflict.
- **Mechanical gate:** green suite + criteria met + `review: auto` → merge. Anything touching
  `critical_paths` from `CLAUDE.md` holds for you.
- One batch digest, not one notification per PR.

The cost is real and worth naming: same-file work serializes, so features must be decomposed
along file boundaries. That is a forcing function on module design, not a tax.

### Who writes the tests matters

The gate auto-merges on a green suite — so if the agent that writes the implementation also
writes its tests, green means only that *the code agrees with itself*. The tests mirror the
implementation instead of constraining it.

So `implementation`, `refactor` and `fix` jobs carry a behavioural `## Test spec`, written before
the implementation exists. After the job merges, `dispatch` generates a `test` job from that spec
and tells the agent it did not write the code, must write its stubs from the spec **before**
reading the implementation, and must record failures rather than fix them. A red adversarial run
is a defect found in merged code: the branch holds, the failures are reported, and a `fix` job is
queued.

### Prerequisite

**Parallel agents require a test suite running in CI.** Two branches can merge cleanly and still
break the default branch — a rename in one, a new caller in the other. Git cannot detect that;
only a full test run post-rebase can. Without a suite, this is a machine for breaking things
faster, and `/setup` will say so and keep dispatch serial.

---

## Skills

| Skill | Command | Purpose |
|---|---|---|
| `setup` | — | Detect the stack; scaffold `CLAUDE.md`, `ROADMAP.md`, `ARCHITECTURE.md`, `decisions/`, `features/`, `jobs/`, CI |
| `architect` | `/architect` | Design, push back, write the decision record — and a feature doc when parallelism warrants one |
| `create-job` | `/create-job` | Queue work with testable criteria and a complete `touches` list |
| `dispatch` | `/dispatch` | Run the queue: partition → worktrees → serial merge → digest |
| `pm` | — | Git hygiene, and the sole writer of shared documents post-merge |
| `pr` | `/pr` | Ship a branch: lint → test → commit → push → PR |

`setup` and `pm` trigger from their descriptions; they have no command because a one-line wrapper
around a skill adds a file to maintain and nothing else.

**Code review** uses the host's built-in `/code-review`, `/security-review` and `/simplify`. v1
shipped its own `code-reviewer` and `code-guardian`; maintaining 463 lines of review instructions
that compete with the built-ins was worse than using them.

## Project structure created

```
your-project/
├── CLAUDE.md             # constraints, commands, critical_paths — auto-loaded every session
├── ROADMAP.md            # what, in what order; decision index
├── ARCHITECTURE.md       # how the code works today
├── decisions/            # why it works that way; immutable once accepted
├── features/             # module boundaries + interface contracts, when warranted
├── jobs/                 # pending / active / done / failed — all committed
└── .github/
    ├── workflows/test.yml
    └── pull_request_template.md
```

`CLAUDE.md` carries the project's facts because **the harness loads it automatically in every
session.** v1 invented `.ai-agents/PROJECT_CONTEXT.md` for the same purpose, but it only worked if
a skill remembered to read it — so when it was absent, every dependent skill degraded silently.

---

## Install

```bash
git submodule add https://github.com/idekker1/claude-pm-plugin .claude/plugins/pm
bash .claude/plugins/pm/install.sh
```

Or clone to `.claude/plugins/pm` if you'd rather not carry a submodule — the installer only needs
the directory to exist.

Then, in Claude Code:

1. `/setup` — detects your stack and fills in `CLAUDE.md`'s test command, lint command and
   proposed `critical_paths`, and writes a matching CI workflow. It writes **no** workflow if it
   can't match your stack, because a permanently red check teaches you to ignore CI.
2. Edit `ROADMAP.md` — § 1 vision, and the "what this is not" boundary.
3. `/architect` — record the decisions already implicit in your codebase.

## Update

```bash
git submodule update --remote .claude/plugins/pm
bash .claude/plugins/pm/update-skills.sh          # --dry-run to preview
```

Skills are copied, not symlinked. Under v2 they are **never edited per-project** (see below), so
an update can overwrite them safely. The updater also offers to delete the skills v2 dropped —
a leftover copy still loads and still competes for triggering.

---

## The boundary rule

> **A skill contains decision procedures. A project contains facts.** No skill names a file,
> command, language, framework or domain noun belonging to any project.

All project specificity lives in `CLAUDE.md`, `ROADMAP.md` and `decisions/`. This is why skills
are never customised per-project, and why the updater can overwrite them.

v1 violated this: it carried seven references to the codebase it was extracted from, including
review triggers hardcoded to "ML pipeline", "database query files" and "schema migrations". In a
project without a database, none of those could ever fire — the review-recommendation feature was
dead logic that looked installed. v2 replaces them with `critical_paths` declared by the project.

`.github/workflows/genericity.yml` enforces the rule in CI: absolute paths, project vocabulary,
removed v1 scaffolding, duplicate skill names, and any skill or command `install.sh` promises but
doesn't ship. Genericity by mechanism, not by care.

---

## Workflow

```
/architect "<feature>"      # design → decision record (→ feature doc if parallelisable)
/create-job "<work>"        # queue, with touches + testable criteria
/dispatch                   # run 2–3 in parallel, merge serially, report a digest
/dispatch "PR merged"       # post-merge doc sync
```

Day to day:

```
git checkout -b fix/thing
# ... work ...
/code-review                # built-in
/pr                         # lint → test → commit → push → PR
```

## License

MIT
