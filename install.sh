#!/bin/bash
#
# Install beads-compound plugin into a project
#
# What this installs:
#   - Memory capture and auto-recall hooks
#   - Knowledge store (.beads/memory/knowledge.jsonl)
#   - Recall script (.beads/memory/recall.sh)
#   - Beads-aware workflow commands (25 commands)
#   - Specialized agents (28 agent definitions)
#   - Skills (15 skills including git-worktree, brainstorming, etc.)
#   - MCP server configuration (Context7)
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
PLUGIN_DIR="$SCRIPT_DIR/plugins/beads-compound"
TARGET="${1:-.}"
TARGET="$(cd "$TARGET" && pwd)"

# Detect if user is trying to install into the plugin directory itself
if [[ "$TARGET" == "$SCRIPT_DIR" || "$TARGET" == "$PLUGIN_DIR" ]]; then
  echo "[!] Error: Cannot install plugin into itself."
  echo ""
  echo "    You're trying to install into: $TARGET"
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

# Verify plugin directory exists
if [ ! -d "$PLUGIN_DIR" ]; then
  echo "[!] Error: Plugin directory not found at $PLUGIN_DIR"
  echo "    Expected marketplace structure with plugins/beads-compound/"
  exit 1
fi

echo "beads-compound plugin installer"
echo "Plugin: $PLUGIN_DIR"
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

echo "[1/9] bd found: $(which bd)"

# Initialize .beads if needed
if [ ! -d "$TARGET/.beads" ]; then
  echo "[2/9] Initializing .beads..."
  (cd "$TARGET" && bd init)
else
  echo "[2/9] .beads already exists"
fi

# Set up memory directory and recall script
echo "[3/9] Setting up memory system..."

MEMORY_DIR="$TARGET/.beads/memory"
mkdir -p "$MEMORY_DIR"

if [ ! -f "$MEMORY_DIR/knowledge.jsonl" ]; then
  touch "$MEMORY_DIR/knowledge.jsonl"
  echo "  - Created knowledge.jsonl"
fi

cp "$PLUGIN_DIR/hooks/recall.sh" "$MEMORY_DIR/recall.sh"
chmod +x "$MEMORY_DIR/recall.sh"
echo "  - Installed recall.sh"

# Install hooks
echo "[4/9] Installing hooks..."

HOOKS_DIR="$TARGET/.claude/hooks"
mkdir -p "$HOOKS_DIR"

for hook in memory-capture.sh auto-recall.sh subagent-wrapup.sh; do
  cp "$PLUGIN_DIR/hooks/$hook" "$HOOKS_DIR/$hook"
  chmod +x "$HOOKS_DIR/$hook"
  echo "  - Installed $hook"
done

# Install commands (all from commands directory)
echo "[5/9] Installing workflow commands..."

COMMANDS_DIR="$TARGET/.claude/commands"
mkdir -p "$COMMANDS_DIR"

CMD_COUNT=0

for cmd in "$PLUGIN_DIR/commands"/*.md; do
  if [ -f "$cmd" ]; then
    cp "$cmd" "$COMMANDS_DIR/$(basename "$cmd")"
    ((CMD_COUNT++))
  fi
done

echo "  - Installed $CMD_COUNT commands"

# Install agents
echo "[6/9] Installing agents..."

AGENTS_DIR="$TARGET/.claude/agents"
mkdir -p "$AGENTS_DIR"

AGENT_COUNT=0

if [ -d "$PLUGIN_DIR/agents" ]; then
  for category in "$PLUGIN_DIR/agents"/*/; do
    if [ -d "$category" ]; then
      category_name=$(basename "$category")
      mkdir -p "$AGENTS_DIR/$category_name"

      for agent in "$category"/*.md; do
        if [ -f "$agent" ]; then
          cp "$agent" "$AGENTS_DIR/$category_name/$(basename "$agent")"
          ((AGENT_COUNT++))
        fi
      done
    fi
  done
fi

echo "  - Installed $AGENT_COUNT agents"

# Install skills
echo "[7/9] Installing skills..."

SKILLS_DIR="$TARGET/.claude/skills"
mkdir -p "$SKILLS_DIR"

SKILL_COUNT=0

if [ -d "$PLUGIN_DIR/skills" ]; then
  for skill_dir in "$PLUGIN_DIR/skills"/*/; do
    if [ -d "$skill_dir" ]; then
      skill_name=$(basename "$skill_dir")
      # Copy entire skill directory (may contain references/, templates/, etc.)
      cp -r "$skill_dir" "$SKILLS_DIR/$skill_name"
      ((SKILL_COUNT++))
    fi
  done
fi

echo "  - Installed $SKILL_COUNT skills"

# Install MCP configuration
echo "[8/9] Configuring MCP servers..."

if [ -f "$PLUGIN_DIR/.mcp.json" ]; then
  if [ -f "$TARGET/.mcp.json" ]; then
    if command -v jq &>/dev/null; then
      # Merge MCP servers into existing config
      EXISTING=$(cat "$TARGET/.mcp.json")
      PLUGIN_MCP=$(cat "$PLUGIN_DIR/.mcp.json")
      MERGED=$(printf '%s\n%s\n' "$EXISTING" "$PLUGIN_MCP" | jq -s '.[0].mcpServers = ((.[0].mcpServers // {}) * .[1].mcpServers) | .[0]')
      echo "$MERGED" > "$TARGET/.mcp.json"
      echo "  - Merged MCP servers into existing .mcp.json"
    else
      echo "  [!] jq not found -- skipping MCP merge (manual setup required)"
    fi
  else
    cp "$PLUGIN_DIR/.mcp.json" "$TARGET/.mcp.json"
    echo "  - Created .mcp.json with Context7 MCP server"
  fi
else
  echo "  - No MCP configuration found in plugin"
fi

# Wire up settings.json
echo "[9/9] Configuring settings..."

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

GLOBAL_SKILLS="$HOME/.claude/skills"
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
echo "  Commands ($CMD_COUNT):"
echo "    Workflow: /beads:plan, /beads:brainstorm, /beads:work, /beads:review, /beads:compound, /beads:checkpoint"
echo "    Planning: /deepen-plan, /plan-review, /triage, /resolve-parallel"
echo "    Utility:  /lfg, /changelog, /create-agent-skill, /generate-command, /heal-skill"
echo "    Testing:  /test-browser, /xcode-test, /reproduce-bug, /report-bug"
echo "    Docs:     /deploy-docs, /release-docs, /feature-video, /agent-native-audit"
echo "    Parallel: /resolve-pr-parallel, /resolve-todo-parallel"
echo ""
echo "  Agents ($AGENT_COUNT):"
echo "    Review, research, design, workflow, and docs agents"
echo ""
echo "  Skills ($SKILL_COUNT):"
echo "    git-worktree, brainstorming, create-agent-skills, agent-native-architecture, beads-knowledge,"
echo "    agent-browser, andrew-kane-gem-writer, dhh-rails-style, dspy-ruby, every-style-editor,"
echo "    file-todos, frontend-design, gemini-imagegen, rclone, skill-creator"
echo ""
echo "  Memory System:"
echo "    - Auto-recall at session start (based on current beads)"
echo "    - Auto-capture from bd comment (LEARNED/DECISION/FACT/PATTERN/INVESTIGATION)"
echo "    - Knowledge stored at .beads/memory/knowledge.jsonl"
echo "    - Search: .beads/memory/recall.sh \"keyword\""
echo ""
echo "  MCP Servers:"
echo "    - Context7 (framework documentation)"
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
echo "  3. Use /beads:brainstorm to explore ideas before planning"
echo "  4. Use /beads:review before closing beads to catch issues"
echo "  5. Log learnings with: bd comment add ID \"LEARNED: ...\""
echo "  6. Knowledge will be recalled automatically next session"
echo ""
echo "Restart Claude Code to load the plugin."
echo ""
echo "To uninstall: bash $SCRIPT_DIR/uninstall.sh $TARGET"
