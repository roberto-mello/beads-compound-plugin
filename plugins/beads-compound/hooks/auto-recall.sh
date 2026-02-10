#!/bin/bash
#
# SessionStart: Auto-inject relevant knowledge from memory
#
# Searches the knowledge base for entries relevant to:
# 1. Currently open beads
# 2. Recent activity
# 3. Current git branch context
#
# Injects top results as context for the session
#

MEMORY_DIR="${CLAUDE_PROJECT_DIR:-.}/.beads/memory"
KNOWLEDGE_FILE="$MEMORY_DIR/knowledge.jsonl"

# Exit silently if no knowledge base exists
[[ ! -f "$KNOWLEDGE_FILE" ]] && exit 0

# Get currently open beads
OPEN_BEADS=$(bd list --status=open --json 2>/dev/null | jq -r '.[].id' 2>/dev/null | head -5)
IN_PROGRESS=$(bd list --status=in_progress --json 2>/dev/null | jq -r '.[].id' 2>/dev/null | head -5)

# Get current branch name for context
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)

# Build search terms from bead titles and branch
SEARCH_TERMS=""

# Extract keywords from open/in-progress bead titles
for BEAD_ID in $OPEN_BEADS $IN_PROGRESS; do
  TITLE=$(bd show "$BEAD_ID" --json 2>/dev/null | jq -r '.[0].title // empty' 2>/dev/null)
  if [[ -n "$TITLE" ]]; then
    # Extract key words (ignore common words)
    KEYWORDS=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | grep -oE '\b[a-z]{4,}\b' | grep -vE '^(the|and|for|with|from|that|this|have|been|will|into)$' | head -3)
    SEARCH_TERMS="$SEARCH_TERMS $KEYWORDS"
  fi
done

# Add branch name keywords
if [[ -n "$CURRENT_BRANCH" ]] && [[ "$CURRENT_BRANCH" != "main" ]] && [[ "$CURRENT_BRANCH" != "master" ]]; then
  BRANCH_KEYWORDS=$(echo "$CURRENT_BRANCH" | tr '-_' ' ' | grep -oE '\b[a-z]{4,}\b' | head -2)
  SEARCH_TERMS="$SEARCH_TERMS $BRANCH_KEYWORDS"
fi

# Remove duplicates and limit to top terms
SEARCH_TERMS=$(echo "$SEARCH_TERMS" | tr ' ' '\n' | sort -u | head -5 | tr '\n' ' ')

# If no search terms, show recent entries instead
if [[ -z "$SEARCH_TERMS" ]]; then
  RELEVANT_KNOWLEDGE=$(tail -10 "$KNOWLEDGE_FILE" | jq -r '"\(.type | ascii_upcase): \(.content)"' 2>/dev/null)
else
  RELEVANT_KNOWLEDGE=""

  # Try FTS5 first
  if command -v sqlite3 &>/dev/null; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [[ -f "$SCRIPT_DIR/knowledge-db.sh" ]]; then
      source "$SCRIPT_DIR/knowledge-db.sh"
      DB_PATH="$MEMORY_DIR/knowledge.db"

      # One-time backfill on first run
      kb_backfill "$DB_PATH" "$MEMORY_DIR"
      kb_ensure_db "$DB_PATH"

      RELEVANT_KNOWLEDGE=$(kb_search "$DB_PATH" "$SEARCH_TERMS" 10 | while IFS='|' read -r type content bead tags; do
        echo "$(echo "$type" | tr '[:lower:]' '[:upper:]'): $content"
      done)
    fi
  fi

  # Grep fallback if FTS5 didn't produce results
  if [[ -z "$RELEVANT_KNOWLEDGE" ]]; then
    for TERM in $SEARCH_TERMS; do
      MATCHES=$(grep -i "$TERM" "$KNOWLEDGE_FILE" 2>/dev/null | jq -r '"\(.type | ascii_upcase): \(.content)"' 2>/dev/null | head -3)
      if [[ -n "$MATCHES" ]]; then
        RELEVANT_KNOWLEDGE="$RELEVANT_KNOWLEDGE
$MATCHES"
      fi
    done

    RELEVANT_KNOWLEDGE=$(echo "$RELEVANT_KNOWLEDGE" | sort -u | head -10)
  fi
fi

# If we found relevant knowledge, output it
if [[ -n "$RELEVANT_KNOWLEDGE" ]]; then
  cat << EOF
{"hookSpecificOutput":{"systemMessage":"## Relevant Knowledge from Memory\n\nBased on your current work context:\n\n$RELEVANT_KNOWLEDGE\n\n_Use \`.beads/memory/recall.sh \"keyword\"\` to search for more._"}}
EOF
fi

exit 0
