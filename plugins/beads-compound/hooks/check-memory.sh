#!/bin/bash
#
# SessionStart hook: detect beads projects missing memory setup
#
# Installed globally by ./install.sh (global install).
# Checks if the current project uses beads but lacks memory hooks,
# and tells the user how to fix it.
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

if [ -f "$SOURCE_FILE" ]; then
  PLUGIN_SOURCE=$(cat "$SOURCE_FILE")
  echo ""
  echo "[beads-compound] This project uses beads but is missing memory hooks."
  echo "  Run per-project install to enable auto-recall and knowledge capture:"
  echo ""
  echo "    bash $PLUGIN_SOURCE/install.sh ."
  echo ""
else
  echo ""
  echo "[beads-compound] This project uses beads but is missing memory hooks."
  echo "  Run per-project install to enable auto-recall and knowledge capture."
  echo "  Re-run the beads-compound installer with this project as the target."
  echo ""
fi
