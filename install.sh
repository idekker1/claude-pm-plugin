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
  "code-reviewer"
  "code-guardian"
  "architect"
  "pr"
  "create-job"
  "run-jobs"
  "antigravity"
  "antigravity2.0"
  "ultimate-protocol"
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
  "setup.md"
  "pm.md"
  "pm-update-roadmap.md"
  "pm-sync.md"
  "pm-review-trigger.md"
  "review.md"
  "audit.md"
  "pre-commit.md"
  "pr.md"
  "architect.md"
  "create-job.md"
  "run-jobs.md"
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
for dir in "jobs/pending" "jobs/active" "jobs/done" "jobs/failed" "issues" ".ai-agents" ".github"; do
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

# Template files (never overwrite)
declare -A TEMPLATE_MAP=(
  ["$PLUGIN_DIR/templates/jobs/README.md"]="$PROJECT_ROOT/jobs/README.md"
  ["$PLUGIN_DIR/templates/jobs/job-template.md"]="$PROJECT_ROOT/jobs/job-template.md"
  ["$PLUGIN_DIR/templates/issues/open.md"]="$PROJECT_ROOT/issues/open.md"
  ["$PLUGIN_DIR/templates/issues/closed.md"]="$PROJECT_ROOT/issues/closed.md"
  ["$PLUGIN_DIR/templates/.github/pull_request_template.md"]="$PROJECT_ROOT/.github/pull_request_template.md"
  ["$PLUGIN_DIR/templates/ROADMAP.md.template"]="$PROJECT_ROOT/ROADMAP.md"
  ["$PLUGIN_DIR/templates/REFERENCE.md.template"]="$PROJECT_ROOT/.ai-agents/REFERENCE.md"
  ["$PLUGIN_DIR/templates/WORKFLOW.md.template"]="$PROJECT_ROOT/WORKFLOW.md"
  ["$PLUGIN_DIR/templates/plugin-config.yaml.template"]="$PROJECT_ROOT/plugin-config.yaml"
)

for src in "${!TEMPLATE_MAP[@]}"; do
  dest="${TEMPLATE_MAP[$src]}"
  rel_dest="${dest#$PROJECT_ROOT/}"
  if [ -f "$dest" ]; then
    echo "  ↷  $rel_dest — already exists"
  else
    cp "$src" "$dest"
    echo "  ✓  $rel_dest"
  fi
done

echo ""

# ── Remind about .gitignore ───────────────────────────────────────────────────

if [ -f "$PROJECT_ROOT/.gitignore" ]; then
  if ! grep -q "plugin-config.yaml" "$PROJECT_ROOT/.gitignore"; then
    echo "⚠  Add plugin-config.yaml to .gitignore before adding Notion credentials:"
    echo "   echo 'plugin-config.yaml' >> .gitignore"
    echo ""
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo "✓ Claude PM Plugin installed."
echo ""
echo "Next steps:"
echo "  1. Edit ROADMAP.md — fill in § 1 (vision) and § 2 (technology decisions)"
echo "  2. Edit .ai-agents/REFERENCE.md — describe your architecture"
echo "  3. Optional: add Notion credentials to plugin-config.yaml for issue sync"
echo "  4. Run /create-job to queue your first task"
echo ""
echo "Run /setup in Claude Code to verify the structure."
