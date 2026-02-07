#!/bin/bash
#
# Install beads-compound plugin into a project
#
# What this installs:
#   - Memory capture and auto-recall hooks
#   - Knowledge store (.beads/memory/knowledge.jsonl)
#   - Recall script (.beads/memory/recall.sh)
#   - Beads-aware workflow commands (/beads:plan, /beads:work, /beads:review, etc.)
#   - Compound-engineering agents (links to agent definitions)
#
# Usage:
#   From within plugin directory:
#     ./install.sh /path/to/your-project
#     ./install.sh                          # installs to current directory (not recommended)
#
#   From anywhere:
#     bash /path/to/beads-compound-plugin/install.sh /path/to/your-project
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-.}"
TARGET="$(cd "$TARGET" && pwd)"

# Detect if user is trying to install into the plugin directory itself
if [[ "$TARGET" == "$SCRIPT_DIR" ]]; then
  echo "[!] Error: Cannot install plugin into itself."
  echo ""
  echo "    You're trying to install into: $SCRIPT_DIR"
  echo "    This is the plugin source directory, not a project."
  echo ""
  echo "    Usage from plugin directory:"
  echo "      ./install.sh /path/to/your-project"
  echo ""
  echo "    Or cd to your project first:"
  echo "      cd /path/to/your-project"
  echo "      bash $SCRIPT_DIR/install.sh"
  echo ""
  exit 1
fi

echo "beads-compound plugin installer"
echo "Plugin: $SCRIPT_DIR"
echo "Target: $TARGET"
echo ""

# Check for bd
if ! command -v bd &>/dev/null; then
  echo "[!] beads CLI (bd) not found."
  echo ""
  echo "    Install it first:"
  echo "      macOS:  brew install steveyegge/beads/bd"
  echo "      npm:    npm install -g @beads/bd"
  echo "      go:     go install github.com/steveyegge/beads/cmd/bd@latest"
  echo ""
  exit 1
fi

echo "[1/6] bd found: $(which bd)"

# Initialize .beads if needed
if [ ! -d "$TARGET/.beads" ]; then
  echo "[2/6] Initializing .beads..."
  (cd "$TARGET" && bd init)
else
  echo "[2/6] .beads already exists"
fi

# Set up memory directory and recall script
echo "[3/6] Setting up memory system..."

MEMORY_DIR="$TARGET/.beads/memory"
mkdir -p "$MEMORY_DIR"

if [ ! -f "$MEMORY_DIR/knowledge.jsonl" ]; then
  touch "$MEMORY_DIR/knowledge.jsonl"
  echo "  - Created knowledge.jsonl"
fi

cp "$SCRIPT_DIR/hooks/recall.sh" "$MEMORY_DIR/recall.sh"
chmod +x "$MEMORY_DIR/recall.sh"
echo "  - Installed recall.sh"

# Install hooks
echo "[4/6] Installing hooks..."

HOOKS_DIR="$TARGET/.claude/hooks"
mkdir -p "$HOOKS_DIR"

for hook in memory-capture.sh auto-recall.sh subagent-wrapup.sh; do
  cp "$SCRIPT_DIR/hooks/$hook" "$HOOKS_DIR/$hook"
  chmod +x "$HOOKS_DIR/$hook"
  echo "  - Installed $hook"
done

# Install commands
echo "[5/6] Installing workflow commands..."

COMMANDS_DIR="$TARGET/.claude/commands"
mkdir -p "$COMMANDS_DIR"

for cmd in beads-plan.md beads-work.md beads-review.md beads-research.md beads-checkpoint.md; do
  cp "$SCRIPT_DIR/commands/$cmd" "$COMMANDS_DIR/$cmd"
  echo "  - Installed /${cmd%.md} command"
done

# Wire up settings.json
echo "[6/6] Configuring settings..."

SETTINGS="$TARGET/.claude/settings.json"

if [ -f "$SETTINGS" ]; then
  if command -v jq &>/dev/null; then
    EXISTING=$(cat "$SETTINGS")

    UPDATED=$(echo "$EXISTING" | jq '
      # Add/update SessionStart hook
      .hooks.SessionStart = (
        [(.hooks.SessionStart // [])[] | select(.hooks[]?.command | contains("auto-recall") | not)] +
        [{"hooks":[{"type":"command","command":"bash .claude/hooks/auto-recall.sh","async":true}]}]
      ) |
      # Add/update PostToolUse hook with matcher
      .hooks.PostToolUse = (
        [(.hooks.PostToolUse // [])[] | select(.hooks[]?.command | contains("memory-capture") | not)] +
        [{"matcher":"Bash","hooks":[{"type":"command","command":"bash .claude/hooks/memory-capture.sh","async":true}]}]
      ) |
      # Add/update SubagentStop hook for auto-wrapup
      .hooks.SubagentStop = (
        [(.hooks.SubagentStop // [])[] | select(.hooks[]?.command | contains("subagent-wrapup") | not)] +
        [{"hooks":[{"type":"command","command":"bash .claude/hooks/subagent-wrapup.sh"}]}]
      ) |
      # Remove any null hook arrays
      if .hooks.PreToolUse == null then del(.hooks.PreToolUse) else . end |
      if .hooks.SubagentStop == null then del(.hooks.SubagentStop) else . end
    ')
    echo "$UPDATED" > "$SETTINGS"
    echo "  - Merged hooks into existing settings.json"
  else
    echo "  [!] jq not found -- manual settings.json setup required"
    echo "      Add SessionStart and PostToolUse hooks manually"
  fi
else
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
  echo "  - Created settings.json"
fi

# Update .gitignore
GITIGNORE="$TARGET/.gitignore"

if [ -f "$GITIGNORE" ]; then
  if ! grep -qE '^\.beads/?$' "$GITIGNORE" 2>/dev/null; then
    echo "" >> "$GITIGNORE"
    echo "# Beads (ephemeral task data)" >> "$GITIGNORE"
    echo ".beads/" >> "$GITIGNORE"
    echo "  - Updated .gitignore"
  fi
else
  cat > "$GITIGNORE" << 'EOF'
# Beads (ephemeral task data)
.beads/
.mcp.json
EOF
  echo "  - Created .gitignore"
fi

# Check for recommended frontend skills
FRONTEND_SKILLS_MISSING=()

# Check global skills directory
GLOBAL_SKILLS="$HOME/.claude/skills"

# Check project skills directory
PROJECT_SKILLS="$TARGET/.claude/skills"

if [ ! -f "$GLOBAL_SKILLS/web-design-guidelines.md" ] && [ ! -f "$PROJECT_SKILLS/web-design-guidelines.md" ]; then
  FRONTEND_SKILLS_MISSING+=("web-design-guidelines")
fi

if [ ! -f "$GLOBAL_SKILLS/vercel-react-best-practices.md" ] && [ ! -f "$PROJECT_SKILLS/vercel-react-best-practices.md" ]; then
  FRONTEND_SKILLS_MISSING+=("vercel-react-best-practices")
fi

echo ""
echo "Done. Installed:"
echo ""
echo "  Workflow Commands:"
echo "    /beads:plan     - Research and plan using multiple agents"
echo "    /beads:work     - Work on a bead with context and assistance"
echo "    /beads:review   - Multi-agent code review before closing"
echo "    /beads:research - Deep research with specialized agents"
echo "    /beads:checkpoint - Save progress and capture knowledge"
echo ""
echo "  Memory System:"
echo "    - Auto-recall at session start (based on current beads)"
echo "    - Auto-capture from bd comment (LEARNED/DECISION/FACT/PATTERN/INVESTIGATION)"
echo "    - Knowledge stored at .beads/memory/knowledge.jsonl"
echo "    - Search: .beads/memory/recall.sh \"keyword\""
echo ""

if [ ${#FRONTEND_SKILLS_MISSING[@]} -gt 0 ]; then
  echo "Recommended (frontend projects):"
  for skill in "${FRONTEND_SKILLS_MISSING[@]}"; do
    echo "  - Install $skill skill for enhanced review capabilities"
  done
  echo ""
  echo "  Install globally:"
  for skill in "${FRONTEND_SKILLS_MISSING[@]}"; do
    echo "    claude-code skill add $skill"
  done
  echo ""
  echo "  Or per-project:"
  echo "    cd $TARGET"
  for skill in "${FRONTEND_SKILLS_MISSING[@]}"; do
    echo "    claude-code skill add $skill --project"
  done
  echo ""
fi

echo "Usage:"
echo "  1. Create or work on beads normally with bd commands"
echo "  2. Use /beads:plan for complex features requiring research"
echo "  3. Use /beads:review before closing beads to catch issues"
echo "  4. Log learnings with: bd comment add ID \"LEARNED: ...\""
echo "  5. Knowledge will be recalled automatically next session"
echo ""
echo "Restart Claude Code to load the plugin."
echo ""
echo "To uninstall: bash $SCRIPT_DIR/uninstall.sh $TARGET"
