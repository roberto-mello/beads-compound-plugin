#!/bin/bash
#
# Uninstall beads-compound plugin from a project
#
# What this removes:
#   - Hooks from .claude/hooks/
#   - Commands from .claude/commands/
#   - Hook configuration from .claude/settings.json
#
# What this PRESERVES:
#   - .beads/ directory and all data
#   - .beads/memory/ and knowledge.jsonl (your accumulated knowledge)
#   - Any beads you created
#
# Usage:
#   From within plugin directory:
#     ./uninstall.sh /path/to/your-project
#     ./uninstall.sh                         # uninstalls from current directory
#
#   From anywhere:
#     bash /path/to/beads-compound-plugin/uninstall.sh /path/to/your-project
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-.}"
TARGET="$(cd "$TARGET" && pwd)"

echo "beads-compound plugin uninstaller"
echo "Target: $TARGET"
echo ""

REMOVED_COUNT=0

# Remove hooks
echo "[1/3] Removing hooks..."

HOOKS_DIR="$TARGET/.claude/hooks"

if [ -d "$HOOKS_DIR" ]; then
  for hook in memory-capture.sh auto-recall.sh; do
    if [ -f "$HOOKS_DIR/$hook" ]; then
      rm "$HOOKS_DIR/$hook"
      echo "  - Removed $hook"
      ((REMOVED_COUNT++))
    fi
  done
else
  echo "  - No hooks directory found"
fi

# Remove commands
echo "[2/3] Removing workflow commands..."

COMMANDS_DIR="$TARGET/.claude/commands"

if [ -d "$COMMANDS_DIR" ]; then
  for cmd in beads-plan.md beads-work.md beads-review.md beads-research.md beads-checkpoint.md; do
    if [ -f "$COMMANDS_DIR/$cmd" ]; then
      rm "$COMMANDS_DIR/$cmd"
      echo "  - Removed /${cmd%.md} command"
      ((REMOVED_COUNT++))
    fi
  done
else
  echo "  - No commands directory found"
fi

# Update settings.json to remove hook configuration
echo "[3/3] Updating settings..."

SETTINGS="$TARGET/.claude/settings.json"

if [ -f "$SETTINGS" ]; then
  if command -v jq &>/dev/null; then
    EXISTING=$(cat "$SETTINGS")

    # Remove our hooks from configuration and clean up empty/null arrays
    UPDATED=$(echo "$EXISTING" | jq '
      .hooks.SessionStart = [(.hooks.SessionStart // [])[] | select(.hooks[]?.command | contains("auto-recall") | not)] |
      if (.hooks.SessionStart | length) == 0 then del(.hooks.SessionStart) else . end |
      .hooks.PostToolUse = [(.hooks.PostToolUse // [])[] | select(.hooks[]?.command | contains("memory-capture") | not)] |
      if (.hooks.PostToolUse | length) == 0 then del(.hooks.PostToolUse) else . end |
      # Remove null hook arrays if they exist
      if .hooks.PreToolUse == null then del(.hooks.PreToolUse) else . end |
      if .hooks.SubagentStop == null then del(.hooks.SubagentStop) else . end |
      # Remove hooks object if empty
      if (.hooks | to_entries | length) == 0 then del(.hooks) else . end
    ')

    echo "$UPDATED" > "$SETTINGS"
    echo "  - Removed hook configuration from settings.json"
    ((REMOVED_COUNT++))
  else
    echo "  [!] jq not found -- manual settings.json cleanup required"
    echo "      Remove SessionStart and PostToolUse hooks manually"
  fi
else
  echo "  - No settings.json found"
fi

# Summary
echo ""
if [ $REMOVED_COUNT -gt 0 ]; then
  echo "Uninstall complete. Removed $REMOVED_COUNT component(s)."
  echo ""
  echo "PRESERVED:"
  echo "  - .beads/ directory with all your data"
  echo "  - .beads/memory/knowledge.jsonl with accumulated knowledge"
  echo "  - All beads you created"
  echo ""
  echo "To completely remove beads data:"
  echo "  rm -rf $TARGET/.beads/"
  echo ""
  echo "Restart Claude Code to complete uninstallation."
else
  echo "Nothing to uninstall. beads-compound may not be installed here."
fi
