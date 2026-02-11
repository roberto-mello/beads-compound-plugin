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

# Find where the plugin source lives
SOURCE_FILE="$HOME/.claude/.beads-compound-source"

if [ ! -f "$SOURCE_FILE" ]; then
  cat <<'NOFIND'
{
  "systemMessage": "[beads-compound] This project uses beads but is missing memory hooks. Could not find plugin source to auto-install."
}
NOFIND
  exit 0
fi

PLUGIN_SOURCE=$(cat "$SOURCE_FILE")
PLUGIN_DIR="$PLUGIN_SOURCE/plugins/beads-compound"

if [ ! -d "$PLUGIN_DIR/hooks" ]; then
  cat <<MISSING
{
  "systemMessage": "[beads-compound] Plugin source at $PLUGIN_SOURCE is missing hooks directory."
}
MISSING
  exit 0
fi

# --- Auto-install memory features ---

# 1. Set up memory directory
PROVISION_SCRIPT="$PLUGIN_DIR/hooks/provision-memory.sh"

if [ -f "$PROVISION_SCRIPT" ]; then
  source "$PROVISION_SCRIPT"
  provision_memory_dir "." "$PLUGIN_DIR/hooks"
else
  # Fallback: minimal setup if provision script missing
  MEMORY_DIR=".beads/memory"
  mkdir -p "$MEMORY_DIR"
  [ ! -f "$MEMORY_DIR/knowledge.jsonl" ] && touch "$MEMORY_DIR/knowledge.jsonl"
fi

# 2. Install hook scripts
HOOKS_DIR=".claude/hooks"
mkdir -p "$HOOKS_DIR"

for hook in memory-capture.sh auto-recall.sh subagent-wrapup.sh knowledge-db.sh provision-memory.sh; do
  if [ -f "$PLUGIN_DIR/hooks/$hook" ]; then
    cp "$PLUGIN_DIR/hooks/$hook" "$HOOKS_DIR/$hook"
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
