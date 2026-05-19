#!/usr/bin/env bash
#
# novel-forge / install.sh
#
# Symlinks (or copies) all novel-forge sub-skills into Claude Code and/or Codex
# skill directories so agents can discover them globally.
#
# Re-runnable safely (detects conflicts and asks for confirmation before overwriting).
#
# After install, in any novel project directory: open Claude Code → say "初始化"
# → /novel-init runs the onboarding.
#
# To uninstall: bash uninstall.sh
#
# Usage:
#   bash install.sh                    # Claude Code install, symlink mode (default)
#   bash install.sh --copy             # Claude Code install, copy mode
#   bash install.sh --codex            # Codex install into ~/.codex/skills/
#   bash install.sh --all              # install for both Claude Code and Codex
#   bash install.sh --codex --copy     # Codex install, copy mode
#   bash install.sh --help             # show this help

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

# For Claude Code: install sub-skills only
CLAUDE_SKILLS=("${SUB_SKILLS[@]}")
# For Codex: include the main novel-forge skill directory as well
CODEX_SKILLS=(novel-forge "${SUB_SKILLS[@]}")

# Resolve the directory containing THIS script (the source root)
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

MODE="symlink"
TARGET_AGENT="claude"

for arg in "$@"; do
  case "$arg" in
    --copy)
      MODE="copy"
      ;;
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
      sed -n '1,23p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "  Usage: bash install.sh [--copy] [--claude|--codex|--all]"
      exit 1
      ;;
  esac
done

# Sanity check: confirm we're in the novel-forge root
if [[ ! -d "$SCRIPT_DIR/skills" ]]; then
  echo "ERROR: Missing: $SCRIPT_DIR/skills/"
  echo "  Are you running install.sh from the novel-forge root?"
  exit 1
fi

for s in "${SUB_SKILLS[@]}"; do
  if [[ ! -d "$SCRIPT_DIR/skills/$s" ]]; then
    echo "ERROR: Missing skill directory: $SCRIPT_DIR/skills/$s"
    echo "  Are you running install.sh from the novel-forge root?"
    exit 1
  fi
done

skill_source() {
  local skill="$1"
  if [[ "$skill" == "novel-forge" ]]; then
    echo "$SCRIPT_DIR"
  else
    echo "$SCRIPT_DIR/skills/$skill"
  fi
}

detect_conflicts() {
  local target_dir="$1"
  shift
  local warned=0

  for s in "$@"; do
    local src
    src=$(skill_source "$s")
    local target="$target_dir/$s"
    if [[ -e "$target" || -L "$target" ]]; then
      if [[ -L "$target" ]]; then
        local existing
        existing=$(readlink "$target")
        if [[ "$existing" != "$src" ]]; then
          echo "  WARNING: $target already symlinked to: $existing"
          warned=1
        fi
      else
        echo "  WARNING: $target exists (not a symlink) — will be overwritten"
        warned=1
      fi
    fi
  done

  return "$warned"
}

install_skills() {
  local label="$1"
  local target_dir="$2"
  shift 2

  mkdir -p "$target_dir"

  echo ""
  echo "Installing novel-forge for $label (mode: $MODE)"
  echo "  source: $SCRIPT_DIR"
  echo "  target: $target_dir/"
  echo ""

  for s in "$@"; do
    local src
    src=$(skill_source "$s")
    local dst="$target_dir/$s"

    if [[ -e "$dst" || -L "$dst" ]]; then
      rm -rf "$dst"
    fi

    if [[ "$MODE" == "symlink" ]]; then
      ln -s "$src" "$dst"
      echo "  [ok] symlinked: $s"
    else
      cp -R "$src" "$dst"
      if [[ "$s" == "novel-forge" ]]; then
        rm -rf "$dst/.git"
      fi
      echo "  [ok] copied:    $s"
    fi
  done
}

# --- Conflict detection ---
WARNED=0
if [[ "$TARGET_AGENT" == "claude" || "$TARGET_AGENT" == "all" ]]; then
  detect_conflicts "$HOME/.claude/skills" "${CLAUDE_SKILLS[@]}" || WARNED=1
fi
if [[ "$TARGET_AGENT" == "codex" || "$TARGET_AGENT" == "all" ]]; then
  detect_conflicts "$HOME/.codex/skills" "${CODEX_SKILLS[@]}" || WARNED=1
fi

if [[ $WARNED -eq 1 ]]; then
  echo ""
  read -p "Continue and overwrite? (y/N) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# --- Install ---
if [[ "$TARGET_AGENT" == "claude" || "$TARGET_AGENT" == "all" ]]; then
  install_skills "Claude Code" "$HOME/.claude/skills" "${CLAUDE_SKILLS[@]}"
fi

if [[ "$TARGET_AGENT" == "codex" || "$TARGET_AGENT" == "all" ]]; then
  install_skills "Codex" "$HOME/.codex/skills" "${CODEX_SKILLS[@]}"
fi

echo ""
echo "Install complete!"
echo ""
echo "Next steps:"
echo "  1. cd into your novel project (or create one):"
echo "       mkdir ~/my-novel && cd ~/my-novel"
echo ""
echo "  2. Open Claude Code or Codex in that directory"
echo ""
echo "  3. In the chat, say:"
echo "       /novel-init"
echo ""
if [[ "$TARGET_AGENT" == "claude" || "$TARGET_AGENT" == "all" ]]; then
  echo "Verify Claude install: ls -la ~/.claude/skills/ | grep novel"
fi
if [[ "$TARGET_AGENT" == "codex" || "$TARGET_AGENT" == "all" ]]; then
  echo "Verify Codex install:  ls -la ~/.codex/skills/ | grep novel"
  echo "Note: restart Codex if the new skills do not appear in the current session."
fi
echo ""
if [[ "$MODE" == "symlink" ]]; then
  echo "Mode: symlink — edits to source SKILL.md files take effect immediately."
  if [[ "$TARGET_AGENT" == "codex" ]]; then
    echo "  To switch to frozen copy: bash install.sh --codex --copy"
  elif [[ "$TARGET_AGENT" == "all" ]]; then
    echo "  To switch to frozen copy: bash install.sh --all --copy"
  else
    echo "  To switch to frozen copy: bash install.sh --copy"
  fi
else
  echo "Mode: copy — frozen at install time. Re-run install.sh to update."
fi
echo ""
