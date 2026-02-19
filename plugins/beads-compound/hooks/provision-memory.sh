#!/bin/bash
#
# Shared memory provisioning for beads-compound
#
# Provides a single function to set up .beads/memory/ with knowledge tracking.
# Used by auto-recall.sh (native plugin), check-memory.sh (global install),
# and install.sh (manual install) to avoid duplicating setup logic.
#
# Usage:
#   source provision-memory.sh
#   provision_memory_dir "/path/to/project" "/path/to/hooks/dir"
#

provision_memory_dir() {
  local PROJECT_DIR="$1"
  local HOOKS_SOURCE_DIR="$2"

  local MEMORY_DIR="$PROJECT_DIR/.beads/memory"

  mkdir -p "$MEMORY_DIR"

  # Create empty knowledge file if missing
  if [[ ! -f "$MEMORY_DIR/knowledge.jsonl" ]]; then
    touch "$MEMORY_DIR/knowledge.jsonl"
  fi

  # Copy recall.sh if available
  if [[ -f "$HOOKS_SOURCE_DIR/recall.sh" ]]; then
    cp "$HOOKS_SOURCE_DIR/recall.sh" "$MEMORY_DIR/recall.sh"
    chmod +x "$MEMORY_DIR/recall.sh"
  fi

  # Copy knowledge-db.sh if available
  if [[ -f "$HOOKS_SOURCE_DIR/knowledge-db.sh" ]]; then
    cp "$HOOKS_SOURCE_DIR/knowledge-db.sh" "$MEMORY_DIR/knowledge-db.sh"
    chmod +x "$MEMORY_DIR/knowledge-db.sh"
  fi

  # Setup .gitattributes for union merge (per-directory, scoped to .beads/memory/)
  local GITATTR="$MEMORY_DIR/.gitattributes"

  if [[ ! -f "$GITATTR" ]] || ! grep -q 'knowledge.jsonl' "$GITATTR" 2>/dev/null; then
    echo "knowledge.jsonl merge=union" > "$GITATTR"
    echo "knowledge.archive.jsonl merge=union" >> "$GITATTR"
  fi

  # Ensure .beads/memory/ is not gitignored
  # Many projects gitignore .beads/ for the daemon/cache files,
  # but memory files need to be tracked for cross-machine persistence
  if git -C "$PROJECT_DIR" rev-parse --git-dir &>/dev/null 2>&1; then
    local GITIGNORE="$PROJECT_DIR/.gitignore"
    if [[ -f "$GITIGNORE" ]] && grep -q '\.beads' "$GITIGNORE" 2>/dev/null; then
      if ! grep -q '!\.beads/memory/' "$GITIGNORE" 2>/dev/null; then
        printf '\n# beads-compound: persist knowledge across machines\n!.beads/memory/\n!.beads/memory/**\n' >> "$GITIGNORE"
      fi
    fi
  fi

  # Stage specific known files only (use -f to override parent .gitignore
  # in case negation rules haven't been picked up yet by this git session)
  if git -C "$PROJECT_DIR" rev-parse --git-dir &>/dev/null 2>&1; then
    (cd "$PROJECT_DIR" && git add -f \
      .beads/memory/knowledge.jsonl \
      .beads/memory/.gitattributes \
      .beads/memory/recall.sh \
      .beads/memory/knowledge-db.sh \
      2>/dev/null) || true
  fi
}
