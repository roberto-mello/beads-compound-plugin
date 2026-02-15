#!/bin/bash
#
# SessionStart hook: auto-install memory features in beads projects
#
# Installed globally by ./install.sh (global install).
# Detects beads projects missing memory hooks and installs them automatically.
#

# Only relevant if this project has .beads/ initialized
if [ ! -d ".beads" ]; then
  exit 0
fi

# Already has memory hooks -- nothing to do
if [ -f ".claude/hooks/memory-capture.sh" ]; then
  exit 0
fi

# Find where the hook scripts are installed
# Try multiple locations in order:
# 1. Global hooks directory (manual install)
# 2. Same directory as this script (marketplace/plugin install)
# 3. Plugin source path (legacy)

HOOKS_SOURCE_DIR=""

# Option 1: Global hooks directory
if [ -f "$HOME/.claude/hooks/memory-capture.sh" ]; then
  HOOKS_SOURCE_DIR="$HOME/.claude/hooks"
fi

# Option 2: Same directory as this script (for marketplace installs)
if [ -z "$HOOKS_SOURCE_DIR" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  if [ -f "$SCRIPT_DIR/memory-capture.sh" ]; then
    HOOKS_SOURCE_DIR="$SCRIPT_DIR"
  fi
fi

# Option 3: Legacy plugin source path (backward compatibility)
if [ -z "$HOOKS_SOURCE_DIR" ] && [ -f "$HOME/.claude/.beads-compound-source" ]; then
  PLUGIN_SOURCE=$(cat "$HOME/.claude/.beads-compound-source")
  PLUGIN_DIR="$PLUGIN_SOURCE/plugins/beads-compound"
  if [ -f "$PLUGIN_DIR/hooks/memory-capture.sh" ]; then
    HOOKS_SOURCE_DIR="$PLUGIN_DIR/hooks"
  fi
fi

# Verify we found the hooks
if [ -z "$HOOKS_SOURCE_DIR" ] || [ ! -f "$HOOKS_SOURCE_DIR/memory-capture.sh" ]; then
  cat <<'NOFIND'
{
  "systemMessage": "[beads-compound] Memory hook scripts not found. Install via: /plugin install beads-compound"
}
NOFIND
  exit 0
fi

# --- Auto-install memory features ---

# 1. Set up memory directory
PROVISION_SCRIPT="$HOOKS_SOURCE_DIR/provision-memory.sh"

if [ -f "$PROVISION_SCRIPT" ]; then
  source "$PROVISION_SCRIPT"
  provision_memory_dir "." "$HOOKS_SOURCE_DIR"
else
  # Fallback: minimal setup if provision script missing
  MEMORY_DIR=".beads/memory"
  mkdir -p "$MEMORY_DIR"
  [ ! -f "$MEMORY_DIR/knowledge.jsonl" ] && touch "$MEMORY_DIR/knowledge.jsonl"
fi

# 2. Install hook scripts from source directory
HOOKS_DIR=".claude/hooks"
mkdir -p "$HOOKS_DIR"

for hook in memory-capture.sh auto-recall.sh subagent-wrapup.sh knowledge-db.sh provision-memory.sh recall.sh; do
  if [ -f "$HOOKS_SOURCE_DIR/$hook" ]; then
    cp "$HOOKS_SOURCE_DIR/$hook" "$HOOKS_DIR/$hook"
    chmod +x "$HOOKS_DIR/$hook"
  fi
done

# 3. Configure settings.json with hook definitions
SETTINGS=".claude/settings.json"

if [ -f "$SETTINGS" ] && command -v jq &>/dev/null; then
  EXISTING=$(cat "$SETTINGS")

  UPDATED=$(echo "$EXISTING" | jq '
    .hooks.SessionStart = (
      [(.hooks.SessionStart // [])[] | select(.hooks[]?.command | contains("auto-recall") | not)] +
      [{"hooks":[{"type":"command","command":"bash .claude/hooks/auto-recall.sh","async":true}]}]
    ) |
    .hooks.PostToolUse = (
      [(.hooks.PostToolUse // [])[] | select(.hooks[]?.command | contains("memory-capture") | not)] +
      [{"matcher":"Bash","hooks":[{"type":"command","command":"bash .claude/hooks/memory-capture.sh","async":true}]}]
    ) |
    .hooks.SubagentStop = (
      [(.hooks.SubagentStop // [])[] | select(.hooks[]?.command | contains("subagent-wrapup") | not)] +
      [{"hooks":[{"type":"command","command":"bash .claude/hooks/subagent-wrapup.sh"}]}]
    ) |
    if .hooks.PreToolUse == null then del(.hooks.PreToolUse) else . end |
    if .hooks.SubagentStop == null then del(.hooks.SubagentStop) else . end
  ')
  echo "$UPDATED" > "$SETTINGS"
elif [ ! -f "$SETTINGS" ]; then
  mkdir -p "$(dirname "$SETTINGS")"
  cat > "$SETTINGS" << 'SETTINGS_EOF'
{
  "hooks": {
    "SessionStart": [
      {"hooks": [{"type": "command", "command": "bash .claude/hooks/auto-recall.sh", "async": true}]}
    ],
    "PostToolUse": [
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "bash .claude/hooks/memory-capture.sh", "async": true}]}
    ],
    "SubagentStop": [
      {"hooks": [{"type": "command", "command": "bash .claude/hooks/subagent-wrapup.sh"}]}
    ]
  }
}
SETTINGS_EOF
fi

# Report success
cat <<'EOF'
{
  "systemMessage": "[beads-compound] Auto-installed memory hooks. Restart Claude Code to activate auto-recall and knowledge capture.",
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Memory hooks were just auto-installed for this project (auto-recall, knowledge capture, subagent wrapup). Tell the user to restart Claude Code to activate them."
  }
}
EOF
