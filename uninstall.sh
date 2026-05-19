#!/usr/bin/env bash
#
# novel-forge / uninstall.sh
#
# Removes all novel-forge skills from Claude Code and/or Codex skill directories.
#
# Does NOT touch any user project data (.novel-state.json, predictions/,
# rubric_notes.md, manuscripts/, etc.) — those live in your novel project
# directories and uninstalling the skill leaves your work intact.
#
# Usage:
#   bash uninstall.sh          # remove Claude Code install (default)
#   bash uninstall.sh --codex  # remove Codex install
#   bash uninstall.sh --all    # remove both
#
# To re-install: bash install.sh

set -euo pipefail

SUB_SKILLS=(
  novel-init
  novel-predict
  novel-retro
  novel-score
  novel-seed
  novel-status
  novel-publish
  novel-learn-from
  novel-bump
  novel-migrate
)

CLAUDE_SKILLS=("${SUB_SKILLS[@]}")
CODEX_SKILLS=(novel-forge "${SUB_SKILLS[@]}")

TARGET_AGENT="claude"
for arg in "$@"; do
  case "$arg" in
    --claude)
      TARGET_AGENT="claude"
      ;;
    --codex)
      TARGET_AGENT="codex"
      ;;
    --all)
      TARGET_AGENT="all"
      ;;
    --help|-h)
      sed -n '1,17p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "  Usage: bash uninstall.sh [--claude|--codex|--all]"
      exit 1
      ;;
  esac
done

REMOVED=0

remove_skills() {
  local label="$1"
  local target_dir="$2"
  shift 2

  echo ""
  echo "Removing novel-forge from $label:"
  echo "  target: $target_dir/"
  echo ""

  for s in "$@"; do
    local target="$target_dir/$s"
    if [[ -L "$target" ]]; then
      rm "$target"
      echo "  [ok] removed symlink:   $s"
      REMOVED=$((REMOVED + 1))
    elif [[ -d "$target" ]]; then
      rm -rf "$target"
      echo "  [ok] removed directory: $s"
      REMOVED=$((REMOVED + 1))
    else
      echo "  [--] not found:         $s (skipped)"
    fi
  done
}

if [[ "$TARGET_AGENT" == "claude" || "$TARGET_AGENT" == "all" ]]; then
  remove_skills "Claude Code" "$HOME/.claude/skills" "${CLAUDE_SKILLS[@]}"
fi

if [[ "$TARGET_AGENT" == "codex" || "$TARGET_AGENT" == "all" ]]; then
  remove_skills "Codex" "$HOME/.codex/skills" "${CODEX_SKILLS[@]}"
fi

echo ""
if [[ $REMOVED -gt 0 ]]; then
  echo "Uninstalled $REMOVED skill(s)."
else
  echo "Nothing to uninstall — no novel-forge skills found."
fi
echo ""
echo "Note: your novel projects' data (predictions/, rubric_notes.md, .novel-state.json,"
echo "      manuscripts/, starter-rubrics/, etc.) are NOT touched. They live in each"
echo "      project directory. To clean a specific project, delete those files manually."
echo ""
echo "To re-install: bash install.sh [--codex|--all] (from novel-forge source root)"
echo ""
