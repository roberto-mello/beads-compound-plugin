#!/bin/bash
#
# Install beads-compound plugin for OpenCode
#
# What this installs:
#   - TypeScript plugin (plugin.ts) for hook integration
#   - Memory capture and auto-recall hooks
#   - Knowledge store (.beads/memory/knowledge.jsonl)
#   - Converted commands, agents, and skills
#   - MCP server configuration documentation
#
# Usage:
#   Called by install.sh -opencode [target]
#

set -euo pipefail

# Security: Set restrictive umask
umask 077

# Use marketplace root from router if available, else derive from script location
if [ -n "${BEADS_MARKETPLACE_ROOT:-}" ]; then
  SCRIPT_DIR="$BEADS_MARKETPLACE_ROOT"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi

PLUGIN_DIR="$SCRIPT_DIR/plugins/beads-compound"

# Source shared functions
# Use BASH_SOURCE to get the correct path when sourced
INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$INSTALLER_DIR/shared-functions.sh"

# Parse --yes/-y flag (skip confirmation prompts)
AUTO_YES=false
POSITIONAL_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --yes|-y) AUTO_YES=true ;;
    *) POSITIONAL_ARGS+=("$arg") ;;
  esac
done

# Default to ~/.config/opencode if no positional argument provided
if [ ${#POSITIONAL_ARGS[@]} -eq 0 ]; then
  TARGET="$HOME/.config/opencode"
  GLOBAL_INSTALL=true
else
  TARGET="${POSITIONAL_ARGS[0]}"
  GLOBAL_INSTALL=false
fi

# Resolve to absolute path
TARGET="$(resolve_target_dir "$TARGET")"

echo "📦 beads-compound OpenCode Installer"
echo ""
echo "Target: $TARGET"
if [ "$GLOBAL_INSTALL" = true ]; then
  echo "Type: Global installation"
else
  echo "Type: Project-specific installation"
fi
echo ""

# Security: Verify target is not a symlink
if [[ -L "$TARGET" ]]; then
  echo "[!] Error: Target directory is a symlink: $TARGET"
  echo "    This is a security risk. Please use a real directory."
  exit 1
fi

# Security: Verify ownership
TARGET_OWNER=$(stat -f%Su "$TARGET" 2>/dev/null || stat -c%U "$TARGET" 2>/dev/null)
if [[ "$TARGET_OWNER" != "$USER" ]]; then
  echo "[!] Error: Target directory is owned by a different user"
  echo "    Owner: $TARGET_OWNER"
  echo "    Current user: $USER"
  exit 1
fi

# Step 1: Run conversion scripts
echo "🔄 Step 1/5: Converting files to OpenCode format..."
echo ""

# Check if Bun is available
if ! command -v bun &>/dev/null; then
  echo "[!] Error: Bun is required for OpenCode installation"
  echo "    Install Bun: curl -fsSL https://bun.sh/install | bash"
  exit 1
fi

# Run conversion (with flag to suppress standalone instructions)
cd "$SCRIPT_DIR/scripts"
if ! BEADS_INSTALLING=1 bun run convert-opencode.ts; then
  echo "[!] Error: Conversion failed"
  exit 1
fi

echo ""

# Step 2: Install TypeScript plugin
echo "🔧 Step 2/5: Installing TypeScript plugin..."

PLUGINS_DIR="$TARGET/plugins/beads-compound"
create_dir_with_symlink_handling "$PLUGINS_DIR"

cp "$PLUGIN_DIR/opencode/plugin.ts" "$PLUGINS_DIR/"
cp "$PLUGIN_DIR/opencode/package.json" "$PLUGINS_DIR/"

# Set permissions
chmod 644 "$PLUGINS_DIR/plugin.ts"
chmod 644 "$PLUGINS_DIR/package.json"

echo "  ✓ Installed plugin.ts and package.json"

# Install plugin dependencies
cd "$PLUGINS_DIR"
if ! bun install --frozen-lockfile 2>/dev/null; then
  echo "  ⚠️  Frozen lockfile not found, running regular install..."
  bun install
fi

echo "  ✓ Installed plugin dependencies"
echo ""

# Step 3: Copy hooks
echo "📂 Step 3/5: Installing hooks..."

HOOKS_DIR="$TARGET/hooks"
create_dir_with_symlink_handling "$HOOKS_DIR"

for hook in auto-recall.sh memory-capture.sh subagent-wrapup.sh; do
  cp "$PLUGIN_DIR/hooks/$hook" "$HOOKS_DIR/"
  chmod 755 "$HOOKS_DIR/$hook"
  echo "  ✓ $hook"
done

echo ""

# Step 4: Copy converted files
echo "📋 Step 4/5: Installing commands, agents, and skills..."

# Commands
COMMANDS_DIR="$TARGET/commands"
mkdir -p "$COMMANDS_DIR"

find "$PLUGIN_DIR/opencode/commands" -name "*.md" -exec cp {} "$COMMANDS_DIR/" \;
find "$COMMANDS_DIR" -type f -exec chmod 644 {} \;

echo "  ✓ Installed $(find "$PLUGIN_DIR/opencode/commands" -name "*.md" | wc -l | tr -d ' ') commands"

# Agents
AGENTS_DIR="$TARGET/agents"
mkdir -p "$AGENTS_DIR"

for category in review research design workflow docs; do
  mkdir -p "$AGENTS_DIR/$category"
  if [ -d "$PLUGIN_DIR/opencode/agents/$category" ]; then
    find "$PLUGIN_DIR/opencode/agents/$category" -name "*.md" -exec cp {} "$AGENTS_DIR/$category/" \;
  fi
done

find "$AGENTS_DIR" -type f -exec chmod 644 {} \;

echo "  ✓ Installed $(find "$PLUGIN_DIR/opencode/agents" -name "*.md" | wc -l | tr -d ' ') agents"

# Skills
SKILLS_DIR="$TARGET/skills"
mkdir -p "$SKILLS_DIR"

for skill_dir in "$PLUGIN_DIR/opencode/skills"/*; do
  if [ -d "$skill_dir" ]; then
    skill_name=$(basename "$skill_dir")
    mkdir -p "$SKILLS_DIR/$skill_name"
    cp "$skill_dir/SKILL.md" "$SKILLS_DIR/$skill_name/" 2>/dev/null || true
    chmod 444 "$SKILLS_DIR/$skill_name/SKILL.md" 2>/dev/null || true
  fi
done

echo "  ✓ Installed $(find "$PLUGIN_DIR/opencode/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ') skills"
echo ""

# Step 5: Provision memory
echo "💾 Step 5/5: Provisioning memory system..."

BEADS_MEMORY_DIR="$TARGET/.beads/memory"
mkdir -p "$BEADS_MEMORY_DIR"

# Copy recall scripts
cp "$PLUGIN_DIR/hooks/recall.sh" "$BEADS_MEMORY_DIR/"
cp "$PLUGIN_DIR/hooks/knowledge-db.sh" "$BEADS_MEMORY_DIR/"

chmod 755 "$BEADS_MEMORY_DIR/recall.sh"
chmod 755 "$BEADS_MEMORY_DIR/knowledge-db.sh"

# Create knowledge.jsonl if it doesn't exist
if [ ! -f "$BEADS_MEMORY_DIR/knowledge.jsonl" ]; then
  touch "$BEADS_MEMORY_DIR/knowledge.jsonl"
  chmod 644 "$BEADS_MEMORY_DIR/knowledge.jsonl"
fi

echo "  ✓ Memory system ready"
echo ""

# Installation complete
echo "✅ Installation complete!"
echo ""
echo "📚 Next steps:"
echo ""
echo "1. Configure MCP servers (optional):"
echo "   See: $PLUGIN_DIR/opencode/docs/MCP_SETUP.md"
echo ""
echo "2. The TypeScript plugin will automatically load on next OpenCode session"
echo ""
echo "3. Commands are available via Ctrl+K:"
echo "   - beads-plan, beads-work, beads-review, etc."
echo ""

if [ "$GLOBAL_INSTALL" = true ]; then
  echo "Global installation complete. All OpenCode projects will have access to the plugin."
else
  echo "Project-specific installation complete for: $TARGET"
fi
