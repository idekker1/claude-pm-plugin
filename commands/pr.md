Ship the current branch using the pr skill: lint → test → confirm commit → push → open PR.

$ARGUMENTS may be empty (auto-generate the commit message) or a commit message to use.

Reads the lint and test commands from `CLAUDE.md`. A red suite stops the ship. Flags explicitly
when the diff touches a `critical_paths` entry, since that requires human review regardless of a
green suite.

Do not run on the default branch — commits there must go through a branch and a PR.
