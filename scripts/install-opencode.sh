#!/bin/bash
#
# Install beads-compound plugin for OpenCode
#
# Merges plugin components into ~/.config/opencode/ without overwriting
# existing configuration. Creates a backup of opencode.json if it exists.
#
# Usage:
#   ./install-opencode.sh
#
# Prerequisites:
#   - jq (for JSON merging)
#   - beads CLI (bd)
#
# What this installs:
#   - 28 agents into ~/.config/opencode/agents/
#   - 24 skills into ~/.config/opencode/skills/
#   - 25 commands merged into opencode.json
#   - Hooks plugin with hook scripts
#   - Memory system (.beads/memory/)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCODE_SRC="$SCRIPT_DIR/opencode"
TARGET="$HOME/.config/opencode"

if [ ! -d "$OPENCODE_SRC" ]; then
  echo "[!] Error: opencode/ directory not found at $OPENCODE_SRC"
  echo "    This installer expects the converted OpenCode plugin alongside it."
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "[!] Error: jq is required for merging configuration."
  echo "    Install it: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

echo "beads-compound OpenCode installer"
echo "Source: $OPENCODE_SRC"
echo "Target: $TARGET"
echo ""

mkdir -p "$TARGET"

# 1. Backup existing opencode.json
if [ -f "$TARGET/opencode.json" ]; then
  BACKUP="$TARGET/opencode.json.backup.$(date +%Y%m%d%H%M%S)"
  cp "$TARGET/opencode.json" "$BACKUP"
  echo "[1/5] Backed up existing opencode.json -> $(basename "$BACKUP")"
else
  echo "[1/5] No existing opencode.json (fresh install)"
fi

# 2. Copy agents (new files, won't conflict with user's agents)
echo "[2/5] Installing agents..."

mkdir -p "$TARGET/agents"
AGENT_COUNT=0

for agent in "$OPENCODE_SRC/agents"/*.md; do
  if [ -f "$agent" ]; then
    cp "$agent" "$TARGET/agents/$(basename "$agent")"
    ((AGENT_COUNT++))
  fi
done

echo "  - Installed $AGENT_COUNT agents"

# 3. Copy skills
echo "[3/5] Installing skills..."

mkdir -p "$TARGET/skills"
SKILL_COUNT=0

for skill in "$OPENCODE_SRC/skills"/*; do
  if [ -f "$skill" ] || [ -d "$skill" ]; then
    cp -r "$skill" "$TARGET/skills/$(basename "$skill")"
    ((SKILL_COUNT++))
  fi
done

echo "  - Installed $SKILL_COUNT skills"

# 4. Install hooks plugin with actual hook scripts
echo "[4/5] Installing hooks plugin..."

mkdir -p "$TARGET/plugins"
HOOKS_DIR="$TARGET/plugins/beads-compound-hooks"
mkdir -p "$HOOKS_DIR"

# Copy hook scripts from the Claude plugin source
CLAUDE_HOOKS="$SCRIPT_DIR/plugins/beads-compound/hooks"

if [ -d "$CLAUDE_HOOKS" ]; then
  for hook in auto-recall.sh memory-capture.sh subagent-wrapup.sh; do
    if [ -f "$CLAUDE_HOOKS/$hook" ]; then
      cp "$CLAUDE_HOOKS/$hook" "$HOOKS_DIR/$hook"
      chmod +x "$HOOKS_DIR/$hook"
    fi
  done
fi

# Rewrite the hooks plugin to use paths relative to its own directory
cat > "$HOOKS_DIR/index.ts" << 'HOOKS_EOF'
import type { Plugin } from "@opencode-ai/plugin"
import { dirname, join } from "path"
import { fileURLToPath } from "url"

const __dirname = dirname(fileURLToPath(import.meta.url))

export const ConvertedHooks: Plugin = async ({ $ }) => {
  return {
    "session.created": async (input) => {
      await $`bash ${join(__dirname, "auto-recall.sh")}`
    },
    "tool.execute.after": async (input) => {
      if (input.tool === "bash") {
        await $`bash ${join(__dirname, "memory-capture.sh")}`
      }
    },
    "message.updated": async (input) => {
      await $`bash ${join(__dirname, "subagent-wrapup.sh")}`
    }
  }
}

export default ConvertedHooks
HOOKS_EOF

echo "  - Installed hooks plugin with scripts"

# 5. Merge opencode.json
echo "[5/5] Merging configuration..."

PLUGIN_JSON="$OPENCODE_SRC/opencode.json"

if [ -f "$TARGET/opencode.json" ]; then
  # Merge: add plugin commands/permissions/tools without removing existing ones
  MERGED=$(jq -s '
    # Start with existing config
    .[0] as $existing |
    .[1] as $plugin |
    $existing |

    # Merge commands (plugin commands added, existing preserved)
    .command = ((.command // {}) * ($plugin.command // {})) |

    # Merge permissions (plugin permissions added, existing preserved)
    .permission = ((.permission // {}) * ($plugin.permission // {})) |

    # Merge tools (plugin tools added, existing preserved)
    .tools = ((.tools // {}) * ($plugin.tools // {}))
  ' "$TARGET/opencode.json" "$PLUGIN_JSON")

  echo "$MERGED" > "$TARGET/opencode.json"
  echo "  - Merged 25 commands into existing config"
else
  cp "$PLUGIN_JSON" "$TARGET/opencode.json"
  echo "  - Created opencode.json with 25 commands"
fi

echo ""
echo "Done. Installed:"
echo ""
echo "  Agents ($AGENT_COUNT):"
echo "    Review, research, design, workflow, and docs agents"
echo ""
echo "  Skills ($SKILL_COUNT):"
echo "    git-worktree, brainstorming, create-agent-skills, agent-browser, etc."
echo ""
echo "  Commands (25):"
echo "    /beads-plan, /beads-work, /beads-review, /beads-brainstorm, etc."
echo ""
echo "  Hooks:"
echo "    auto-recall, memory-capture, subagent-wrapup"
echo ""
echo "To uninstall, restore your backup:"

if [ -n "${BACKUP:-}" ]; then
  echo "  cp $BACKUP $TARGET/opencode.json"
fi

echo "  rm -rf $TARGET/agents/  $TARGET/skills/"
echo "  rm -rf $TARGET/plugins/beads-compound-hooks/"
echo ""
