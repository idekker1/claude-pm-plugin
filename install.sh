#!/usr/bin/env bash
# Claude PM Plugin — installer
# Run from the root of the project you want to install the plugin into.
# Usage: bash .claude/plugins/pm/install.sh

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"
CLAUDE_DIR="$PROJECT_ROOT/.claude"

echo "Claude PM Plugin — installing into $PROJECT_ROOT"
echo ""

# ── Create .claude directories ───────────────────────────────────────────────

mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/commands"

# ── Copy skills ───────────────────────────────────────────────────────────────

SKILLS=(
  "setup"
  "pm"
  "architect"
  "create-job"
  "dispatch"
  "pr"
)

echo "Installing skills:"
for skill in "${SKILLS[@]}"; do
  dest_dir="$CLAUDE_DIR/skills/$skill"
  src_file="$PLUGIN_DIR/skills/$skill/SKILL.md"

  if [ ! -f "$src_file" ]; then
    echo "  ⚠  Skipping $skill — source not found at $src_file"
    continue
  fi

  if [ -f "$dest_dir/SKILL.md" ]; then
    echo "  ↷  $skill — already exists, skipping"
  else
    mkdir -p "$dest_dir"
    cp "$src_file" "$dest_dir/SKILL.md"
    echo "  ✓  $skill"
  fi
done

echo ""

# ── Copy commands ─────────────────────────────────────────────────────────────

COMMANDS=(
  "architect.md"
  "create-job.md"
  "dispatch.md"
  "pr.md"
)

echo "Installing commands:"
for cmd in "${COMMANDS[@]}"; do
  src_file="$PLUGIN_DIR/commands/$cmd"
  dest_file="$CLAUDE_DIR/commands/$cmd"

  if [ ! -f "$src_file" ]; then
    echo "  ⚠  Skipping $cmd — source not found"
    continue
  fi

  if [ -f "$dest_file" ]; then
    echo "  ↷  $cmd — already exists, skipping"
  else
    cp "$src_file" "$dest_file"
    echo "  ✓  $cmd"
  fi
done

echo ""

# ── Create project structure from templates ───────────────────────────────────

echo "Setting up project structure:"

# Folders
for dir in "jobs/pending" "jobs/active" "jobs/done" "jobs/failed" "decisions" "features" ".github"; do
  full_dir="$PROJECT_ROOT/$dir"
  if [ ! -d "$full_dir" ]; then
    mkdir -p "$full_dir"
    # Add .gitkeep to job lifecycle folders so git tracks them
    if [[ "$dir" == jobs/* ]]; then
      touch "$full_dir/.gitkeep"
    fi
    echo "  ✓  $dir/"
  else
    echo "  ↷  $dir/ — already exists"
  fi
done

# Template files (never overwrite).
#
# "<template path>|<destination, relative to project root>".
#
# Deliberately NOT an associative array: macOS still ships bash 3.2, which has no `declare -A`.
# v1 used one here, so on every macOS install this loop silently copied nothing and left a set
# of empty directories behind — which looked like the plugin had never been set up.
TEMPLATES="
CLAUDE.md.template|CLAUDE.md
ROADMAP.md.template|ROADMAP.md
ARCHITECTURE.md.template|ARCHITECTURE.md
decisions/README.md|decisions/README.md
decisions/decision-template.md|decisions/decision-template.md
features/feature-template.md|features/feature-template.md
jobs/README.md|jobs/README.md
jobs/job-template.md|jobs/job-template.md
.github/pull_request_template.md|.github/pull_request_template.md
"

echo "$TEMPLATES" | while IFS='|' read -r tmpl rel_dest; do
  [ -z "$tmpl" ] && continue

  src="$PLUGIN_DIR/templates/$tmpl"
  dest="$PROJECT_ROOT/$rel_dest"

  if [ ! -f "$src" ]; then
    echo "  ⚠  $rel_dest — template missing at templates/$tmpl"
    continue
  fi

  if [ -f "$dest" ]; then
    echo "  ↷  $rel_dest — already exists"
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  ✓  $rel_dest"
  fi
done

echo ""

# ── Check .gitignore ──────────────────────────────────────────────────────────

# Jobs, features and decisions are versioned artifacts: coordination state for parallel
# agents, and the record of what was done. Both are worthless if they live on one machine.
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
  if grep -qE '^\s*(jobs|features|decisions)/' "$PROJECT_ROOT/.gitignore"; then
    echo "⚠  Your .gitignore excludes jobs/, features/ or decisions/. Remove that rule —"
    echo "   these are versioned artifacts, and the dependency resolver reads jobs/done/."
    echo ""
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo "✓ Claude PM Plugin installed."
echo ""
echo "Next steps:"
echo "  1. Run /setup in Claude Code — it detects your stack and fills in CLAUDE.md"
echo "     (test command, lint command, proposed critical paths) and writes a CI workflow."
echo "  2. Edit ROADMAP.md — § 1 vision and scope, and the 'what this is not' boundary."
echo "  3. Run /architect to record the decisions already implicit in your codebase."
echo "  4. Run /create-job to queue your first task, then /dispatch to run it."
echo ""
echo "Parallel dispatch needs a test suite running in CI. /setup will tell you whether"
echo "this project has one."
