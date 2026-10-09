#!/usr/bin/env bash
# Claude PM Plugin — update skills and commands in an existing project
#
# Run from the root of the project you want to update:
#   bash .claude/plugins/pm/update-skills.sh
#
# Usage:
#   update-skills.sh                        # interactive: show diff, prompt before each change
#   update-skills.sh --yes                  # overwrite all without prompting
#   update-skills.sh --dry-run              # show what would change, no writes
#   update-skills.sh --skills-only          # skip commands
#   update-skills.sh --commands-only        # skip skills
#   update-skills.sh antigravity2.0 pr      # update specific skills only (still updates commands)

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"
CLAUDE_DIR="$PROJECT_ROOT/.claude"

# ── Colours ───────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; RESET=''
fi

# ── Argument parsing ──────────────────────────────────────────────────────────

YES=false
DRY_RUN=false
SKILLS_ONLY=false
COMMANDS_ONLY=false
SELECTED_SKILLS=()

for arg in "$@"; do
  case "$arg" in
    --yes|-y)          YES=true ;;
    --dry-run|-n)      DRY_RUN=true ;;
    --skills-only)     SKILLS_ONLY=true ;;
    --commands-only)   COMMANDS_ONLY=true ;;
    -*)                echo "Unknown flag: $arg"; exit 1 ;;
    *)                 SELECTED_SKILLS+=("$arg") ;;
  esac
done

# ── Sanity checks ─────────────────────────────────────────────────────────────

if [ ! -d "$CLAUDE_DIR" ]; then
  echo -e "${RED}Error:${RESET} No .claude/ directory found in $PROJECT_ROOT."
  echo "Run the installer first: bash .claude/plugins/pm/install.sh"
  exit 1
fi

if $DRY_RUN && $YES; then
  echo -e "${YELLOW}Warning:${RESET} --dry-run and --yes are mutually exclusive. Using --dry-run."
  YES=false
fi

# ── Counters ──────────────────────────────────────────────────────────────────

UPDATED=0
SKIPPED=0
NEW=0
UNCHANGED=0

# ── Helper functions ──────────────────────────────────────────────────────────

show_diff() {
  local src="$1" dest="$2" label="$3"
  echo -e "${CYAN}── $label ──────────────────────────────────────────────────────${RESET}"
  diff --unified=3 "$dest" "$src" | sed \
    -e "s/^+/${GREEN}&${RESET}/" \
    -e "s/^-/${RED}&${RESET}/" \
    -e "s/^@/${YELLOW}&${RESET}/" || true
  echo ""
}

prompt_overwrite() {
  local label="$1"
  if $YES; then return 0; fi
  printf "${BOLD}Update %s?${RESET} [y/N/d(iff)/q(uit)] " "$label"
  read -r answer </dev/tty
  case "$answer" in
    y|Y) return 0 ;;
    q|Q) echo "Aborted."; exit 0 ;;
    *)   return 1 ;;
  esac
}

copy_file() {
  local src="$1" dest="$2"
  if $DRY_RUN; then return; fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
}

# ── Skills ────────────────────────────────────────────────────────────────────

ALL_SKILLS=(
  "setup"
  "pm"
  "architect"
  "create-job"
  "dispatch"
  "pr"
)

# Removed in v2 — deleted from a project on update, since a leftover copy still loads and
# still competes for triggering. See CHANGELOG.md for why each went.
REMOVED_SKILLS=(
  "code-reviewer"
  "code-guardian"
  "run-jobs"
  "antigravity"
  "antigravity2.0"
  "ultimate-protocol"
)

if ! $COMMANDS_ONLY; then
  echo -e "${BOLD}Claude PM Plugin — skill update${RESET}"
  echo -e "Plugin: $PLUGIN_DIR"
  echo -e "Project: $PROJECT_ROOT"
  $DRY_RUN && echo -e "${YELLOW}Dry run — no files will be written${RESET}"
  echo ""
  echo -e "${BOLD}Skills:${RESET}"

  # Resolve which skills to process
  if [ ${#SELECTED_SKILLS[@]} -gt 0 ]; then
    SKILLS_TO_PROCESS=("${SELECTED_SKILLS[@]}")
  else
    SKILLS_TO_PROCESS=("${ALL_SKILLS[@]}")
  fi

  for skill in "${SKILLS_TO_PROCESS[@]}"; do
    src_file="$PLUGIN_DIR/skills/$skill/SKILL.md"
    dest_file="$CLAUDE_DIR/skills/$skill/SKILL.md"

    # Source missing in plugin
    if [ ! -f "$src_file" ]; then
      echo -e "  ${YELLOW}⚠${RESET}  $skill — not found in plugin, skipping"
      (( SKIPPED++ )) || true
      continue
    fi

    # New skill — not yet in project
    if [ ! -f "$dest_file" ]; then
      if $DRY_RUN; then
        echo -e "  ${GREEN}+${RESET}  $skill — new (would install)"
      else
        copy_file "$src_file" "$dest_file"
        echo -e "  ${GREEN}+${RESET}  $skill — installed (new)"
      fi
      (( NEW++ )) || true
      continue
    fi

    # Identical — nothing to do
    if diff -q "$src_file" "$dest_file" > /dev/null 2>&1; then
      echo -e "  ${GREEN}✓${RESET}  $skill — up to date"
      (( UNCHANGED++ )) || true
      continue
    fi

    # Changed — show diff and optionally overwrite
    if ! $YES; then
      show_diff "$src_file" "$dest_file" "$skill"
    fi

    if $DRY_RUN; then
      echo -e "  ${YELLOW}~${RESET}  $skill — has changes (dry run, not written)"
      (( SKIPPED++ )) || true
    elif prompt_overwrite "$skill"; then
      copy_file "$src_file" "$dest_file"
      echo -e "  ${GREEN}✓${RESET}  $skill — updated"
      (( UPDATED++ )) || true
    else
      echo -e "  ${YELLOW}↷${RESET}  $skill — skipped"
      (( SKIPPED++ )) || true
    fi
  done

  echo ""
fi

# ── Commands ──────────────────────────────────────────────────────────────────

ALL_COMMANDS=(
  "architect.md"
  "create-job.md"
  "dispatch.md"
  "pr.md"
)

REMOVED_COMMANDS=(
  "setup.md"
  "pm.md"
  "pm-update-roadmap.md"
  "pm-sync.md"
  "pm-review-trigger.md"
  "review.md"
  "audit.md"
  "pre-commit.md"
  "run-jobs.md"
)

if ! $SKILLS_ONLY; then
  # If specific skills were named and --commands-only wasn't passed, skip commands
  # (user named skills explicitly, probably doesn't want commands updated)
  if [ ${#SELECTED_SKILLS[@]} -gt 0 ] && ! $COMMANDS_ONLY; then
    true  # skip commands when specific skills were targeted
  else
    echo -e "${BOLD}Commands:${RESET}"

    for cmd in "${ALL_COMMANDS[@]}"; do
      src_file="$PLUGIN_DIR/commands/$cmd"
      dest_file="$CLAUDE_DIR/commands/$cmd"

      if [ ! -f "$src_file" ]; then
        echo -e "  ${YELLOW}⚠${RESET}  $cmd — not found in plugin, skipping"
        (( SKIPPED++ )) || true
        continue
      fi

      if [ ! -f "$dest_file" ]; then
        if $DRY_RUN; then
          echo -e "  ${GREEN}+${RESET}  $cmd — new (would install)"
        else
          copy_file "$src_file" "$dest_file"
          echo -e "  ${GREEN}+${RESET}  $cmd — installed (new)"
        fi
        (( NEW++ )) || true
        continue
      fi

      if diff -q "$src_file" "$dest_file" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${RESET}  $cmd — up to date"
        (( UNCHANGED++ )) || true
        continue
      fi

      if ! $YES; then
        show_diff "$src_file" "$dest_file" "$cmd"
      fi

      if $DRY_RUN; then
        echo -e "  ${YELLOW}~${RESET}  $cmd — has changes (dry run, not written)"
        (( SKIPPED++ )) || true
      elif prompt_overwrite "$cmd"; then
        copy_file "$src_file" "$dest_file"
        echo -e "  ${GREEN}✓${RESET}  $cmd — updated"
        (( UPDATED++ )) || true
      else
        echo -e "  ${YELLOW}↷${RESET}  $cmd — skipped"
        (( SKIPPED++ )) || true
      fi
    done

    echo ""
  fi
fi

# ── Remove skills and commands dropped in v2 ─────────────────────────────────
#
# A leftover copy is not harmless: it still loads, still competes for triggering, and in the
# case of the protocol skills actively contradicts v2's behaviour. Only runs on a full update
# (no specific skills named), and always asks unless --yes.

if [ ${#SELECTED_SKILLS[@]} -eq 0 ]; then
  REMOVED_FOUND=()
  for skill in "${REMOVED_SKILLS[@]}"; do
    [ -f "$CLAUDE_DIR/skills/$skill/SKILL.md" ] && REMOVED_FOUND+=("skills/$skill/")
  done
  for cmd in "${REMOVED_COMMANDS[@]}"; do
    [ -f "$CLAUDE_DIR/commands/$cmd" ] && REMOVED_FOUND+=("commands/$cmd")
  done

  if [ ${#REMOVED_FOUND[@]} -gt 0 ]; then
    echo -e "${BOLD}Removed in v2 — still present in this project:${RESET}"
    for item in "${REMOVED_FOUND[@]}"; do
      echo -e "  ${YELLOW}−${RESET}  $item"
    done
    echo ""
    echo "  See CHANGELOG.md for why each was dropped. Leaving them in place means two"
    echo "  reviewers competing to trigger, and protocol skills that contradict v2."
    echo ""

    if $DRY_RUN; then
      echo -e "  ${YELLOW}~${RESET}  dry run — not deleted"
    else
      do_delete=false
      if $YES; then
        do_delete=true
      else
        printf "  Delete these? [y/N] "
        read -r reply < /dev/tty || reply="n"
        [[ "$reply" =~ ^[Yy]$ ]] && do_delete=true
      fi

      if $do_delete; then
        for skill in "${REMOVED_SKILLS[@]}"; do
          rm -rf "$CLAUDE_DIR/skills/$skill"
        done
        for cmd in "${REMOVED_COMMANDS[@]}"; do
          rm -f "$CLAUDE_DIR/commands/$cmd"
        done
        echo -e "  ${GREEN}✓${RESET}  removed"
      else
        echo -e "  ${YELLOW}↷${RESET}  kept — expect duplicate triggering"
      fi
    fi
    echo ""
  fi
fi

# ── v1 → v2 migration notes ───────────────────────────────────────────────────

V1_LEFTOVERS=()
[ -d "$PROJECT_ROOT/.ai-agents" ]          && V1_LEFTOVERS+=(".ai-agents/ → CLAUDE.md + ARCHITECTURE.md")
[ -f "$PROJECT_ROOT/WORKFLOW.md" ]        && V1_LEFTOVERS+=("WORKFLOW.md → lint/test/branch rules now live in CLAUDE.md")
[ -f "$PROJECT_ROOT/plugin-config.yaml" ] && V1_LEFTOVERS+=("plugin-config.yaml → Notion sync removed in v2")
[ -d "$PROJECT_ROOT/issues" ]             && V1_LEFTOVERS+=("issues/ → use your tracker; roadmap items for planned work")
[ ! -f "$PROJECT_ROOT/CLAUDE.md" ]        && V1_LEFTOVERS+=("CLAUDE.md missing → run /setup; it replaces PROJECT_CONTEXT.md")

if [ -f "$PROJECT_ROOT/.gitignore" ] && grep -qE '^\s*(jobs|features|decisions)/' "$PROJECT_ROOT/.gitignore"; then
  V1_LEFTOVERS+=(".gitignore excludes jobs/, features/ or decisions/ → remove that rule; they are versioned")
fi

if [ ${#V1_LEFTOVERS[@]} -gt 0 ]; then
  echo -e "${BOLD}v1 → v2 migration — handle these by hand:${RESET}"
  for note in "${V1_LEFTOVERS[@]}"; do
    echo "  • $note"
  done
  echo ""
fi

# ── Summary ───────────────────────────────────────────────────────────────────

if $DRY_RUN; then
  echo -e "${BOLD}Dry run complete.${RESET} Run without --dry-run to apply changes."
else
  echo -e "${BOLD}Done.${RESET} $UPDATED updated, $NEW new, $UNCHANGED unchanged, $SKIPPED skipped."
  if [ $UPDATED -gt 0 ] || [ $NEW -gt 0 ]; then
    echo ""
    echo "Tip: if this project uses the submodule, commit the updated .claude/skills/ files."
  fi
fi
