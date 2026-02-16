#!/bin/bash
#
# Interactive model selection for OpenCode installation
# Queries available models via 'opencode models' and lets user select preferences
#
# Usage:
#   ./select-opencode-models.sh [--yes]
#
# With --yes: Uses defaults without prompting
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/shared/model-config.json"

# Parse --yes flag
AUTO_YES=false
for arg in "$@"; do
  case "$arg" in
    --yes|-y) AUTO_YES=true ;;
  esac
done

# Check if opencode is available
if ! command -v opencode &>/dev/null; then
  echo "[!] Error: 'opencode' command not found"
  echo "    OpenCode must be installed to query available models"
  echo "    Visit: https://github.com/smallcloudai/refact"
  exit 1
fi

# Query available models
echo "🔍 Querying available models from OpenCode..."
MODELS_OUTPUT=$(opencode models 2>&1 || true)

# Extract Anthropic/Claude models
CLAUDE_MODELS=$(echo "$MODELS_OUTPUT" | grep -E "anthropic/claude-" | awk '{print $1}' | sort -u || true)

if [ -z "$CLAUDE_MODELS" ]; then
  echo "[!] Warning: No Anthropic/Claude models found in OpenCode"
  echo "    Using defaults from model-config.json"
  exit 0
fi

echo ""
echo "Found $(echo "$CLAUDE_MODELS" | wc -l | tr -d ' ') Claude models:"
echo "$CLAUDE_MODELS" | sed 's/^/  - /'
echo ""

# Load current config
if [ -f "$CONFIG_FILE" ]; then
  CURRENT_HAIKU=$(jq -r '.opencode.haiku' "$CONFIG_FILE")
  CURRENT_SONNET=$(jq -r '.opencode.sonnet' "$CONFIG_FILE")
  CURRENT_OPUS=$(jq -r '.opencode.opus' "$CONFIG_FILE")
else
  CURRENT_HAIKU="anthropic/claude-haiku-4-5-20251001"
  CURRENT_SONNET="anthropic/claude-sonnet-4-5-20250929"
  CURRENT_OPUS="anthropic/claude-opus-4-6"
fi

# If --yes flag, use current config
if [ "$AUTO_YES" = true ]; then
  echo "Using defaults (--yes flag):"
  echo "  haiku:  $CURRENT_HAIKU"
  echo "  sonnet: $CURRENT_SONNET"
  echo "  opus:   $CURRENT_OPUS"
  exit 0
fi

# Interactive selection function
select_model() {
  local tier="$1"
  local current="$2"
  local pattern="$3"

  echo "Select model for $tier tier (current: $current):"
  echo ""

  # Filter models by pattern
  local filtered=$(echo "$CLAUDE_MODELS" | grep -i "$pattern" || echo "$CLAUDE_MODELS")

  # Create numbered list
  local i=1
  local model_array=()
  while IFS= read -r model; do
    model_array+=("$model")
    if [ "$model" = "$current" ]; then
      echo "  $i) $model (current)"
    else
      echo "  $i) $model"
    fi
    ((i++))
  done <<< "$filtered"

  echo "  0) Keep current ($current)"
  echo ""

  # Get user selection
  while true; do
    read -p "Selection (0-$((i-1))): " selection

    if [[ "$selection" =~ ^[0-9]+$ ]]; then
      if [ "$selection" -eq 0 ]; then
        echo "$current"
        return
      elif [ "$selection" -ge 1 ] && [ "$selection" -lt "$i" ]; then
        echo "${model_array[$((selection-1))]}"
        return
      fi
    fi

    echo "Invalid selection. Please enter a number between 0 and $((i-1))."
  done
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Model Selection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Select models for each tier
HAIKU_MODEL=$(select_model "haiku" "$CURRENT_HAIKU" "haiku")
echo ""

SONNET_MODEL=$(select_model "sonnet" "$CURRENT_SONNET" "sonnet")
echo ""

OPUS_MODEL=$(select_model "opus" "$CURRENT_OPUS" "opus")
echo ""

# Confirm selections
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Selected Models:"
echo "  haiku:  $HAIKU_MODEL"
echo "  sonnet: $SONNET_MODEL"
echo "  opus:   $OPUS_MODEL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "Save this configuration? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Configuration not saved."
  exit 0
fi

# Create config directory if needed
mkdir -p "$(dirname "$CONFIG_FILE")"

# Load existing config or create new
if [ -f "$CONFIG_FILE" ]; then
  CONFIG=$(cat "$CONFIG_FILE")
else
  CONFIG='{}'
fi

# Update OpenCode models
CONFIG=$(echo "$CONFIG" | jq ".opencode.haiku = \"$HAIKU_MODEL\"")
CONFIG=$(echo "$CONFIG" | jq ".opencode.sonnet = \"$SONNET_MODEL\"")
CONFIG=$(echo "$CONFIG" | jq ".opencode.opus = \"$OPUS_MODEL\"")

# Ensure Gemini config exists (preserve existing if present)
if ! echo "$CONFIG" | jq -e '.gemini' >/dev/null 2>&1; then
  CONFIG=$(echo "$CONFIG" | jq '.gemini = {
    "haiku": "gemini-2.5-flash",
    "sonnet": "gemini-2.5-pro",
    "opus": "gemini-2.5-pro"
  }')
fi

# Write config file
echo "$CONFIG" | jq . > "$CONFIG_FILE"

echo ""
echo "✅ Configuration saved to: $CONFIG_FILE"
echo ""
echo "Next steps:"
echo "  Run the OpenCode installer to use these model selections"
