# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code plugin that combines beads-based memory management with compound-engineering's multi-agent workflows. It provides:

- Automatic knowledge capture from beads comments (LEARNED/DECISION/FACT/PATTERN/INVESTIGATION)
- Automatic knowledge recall at session start based on current beads
- Five workflow commands for planning, research, review, and checkpointing
- Three hooks for memory capture, auto-recall, and subagent wrapup

## Plugin Installation

Install this plugin into a target project:

```bash
# From plugin directory
./install.sh /path/to/target-project

# Or from target project
bash /path/to/beads-compound-plugin/install.sh
```

Uninstall:

```bash
./uninstall.sh /path/to/target-project
```

**IMPORTANT**: The installer will fail if you try to install into the plugin directory itself. Always install into a separate target project.

## Development Commands

**Test the installer:**
```bash
# Create a test project
mkdir -p /tmp/test-project && cd /tmp/test-project
git init && bd init

# Install plugin
bash ~/Documents/projects/beads-compound-plugin/install.sh

# Verify installation
ls -la .claude/hooks/
ls -la .claude/commands/
cat .claude/settings.json | jq .
```

**Test uninstaller:**
```bash
bash ~/Documents/projects/beads-compound-plugin/uninstall.sh /tmp/test-project
```

**Test hook format:**
```bash
# Verify hooks.json format is valid
cat .claude/settings.json | jq '.hooks'

# Should use string matchers, not object matchers:
# ✓ Correct: {"matcher": "Bash", "hooks": [...]}
# ✗ Wrong:   {"matcher": {"tools": ["BashTool"]}, "hooks": [...]}
```

## Architecture

### Memory System

Knowledge is stored in `.beads/memory/knowledge.jsonl` with this structure:

```json
{
  "key": "learned-oauth-redirect-must-match-exactly",
  "type": "learned",
  "content": "OAuth redirect URI must match exactly",
  "source": "user",
  "tags": ["oauth", "auth", "security"],
  "ts": 1706918400,
  "bead": "BD-001"
}
```

- **Auto-tagging**: Keywords detected in content (auth, database, react, etc.) are added as tags
- **Rotation**: After 1000 entries, oldest 500 are archived to `knowledge.archive.jsonl`
- **Search**: Use `.beads/memory/recall.sh` for manual search

### Hooks System

Three hooks implement the memory and subagent features:

1. **SessionStart**: `auto-recall.sh`
   - Runs at session start
   - Searches knowledge based on open/in-progress beads
   - Extracts keywords from bead titles and git branch
   - Injects top 10 relevant entries as context

2. **PostToolUse**: `memory-capture.sh` (matcher: "Bash")
   - Runs after Bash commands
   - Detects `bd comment add` with knowledge prefixes
   - Extracts and stores in `knowledge.jsonl`
   - Auto-tags based on content keywords

3. **SubagentStop**: `subagent-wrapup.sh`
   - Runs when subagent completes
   - Checks transcript for BEAD_ID
   - Blocks completion until subagent logs at least one knowledge comment
   - Ensures subagent discoveries are captured

### Hook Matcher Format

Hook matchers MUST be regex strings, not objects:

```json
{
  "PostToolUse": [
    {"matcher": "Bash", "hooks": [...]}
  ],
  "PreToolUse": [
    {"matcher": "Edit|Write", "hooks": [...]}
  ]
}
```

Tool names in matchers:
- `Bash`, `Edit`, `Write`, `Read`, `Task`, `Grep`, `Glob`
- Do NOT use "Tool" suffix
- Do NOT use object format like `{"tools": ["BashTool"]}`

### Workflow Commands

Five beads-aware commands are installed to `.claude/commands/`:

1. **beads-plan.md** (`/beads-plan`)
   - Create epic bead and research using multiple agents
   - Dispatch agents in parallel: best-practices-researcher, framework-docs-researcher, repo-research-analyst
   - Create child beads with comprehensive descriptions including testing/validation criteria

2. **beads-work.md** (`/beads-work`)
   - Start work on a bead with auto-recall
   - Update status to in_progress
   - Offer optional investigation using research agents

3. **beads-review.md** (`/beads-review`)
   - Multi-agent code review before closing bead
   - Dispatch language-specific and cross-cutting reviewers in parallel
   - Create follow-up beads for critical issues

4. **beads-research.md** (`/beads-research`)
   - Deep research using specialized agents
   - Synthesize findings into organized comments

5. **beads-checkpoint.md** (`/beads-checkpoint`)
   - Save progress and file beads
   - Capture knowledge comments
   - Commit changes

### Subagent Integration

When delegating work to subagents, include BEAD_ID in the prompt:

```
Task(subagent_type="general-purpose",
     prompt="Investigate OAuth flow. BEAD_ID: BD-001")
```

The `subagent-wrapup.sh` hook will:
1. Extract BEAD_ID from the subagent transcript
2. Block completion until subagent logs knowledge
3. Prompt with the five knowledge prefixes (LEARNED/DECISION/FACT/PATTERN/INVESTIGATION)

## Installation Behavior

The `install.sh` script:
1. Checks for `bd` CLI (fails if not found)
2. Initializes `.beads` if needed (runs `bd init`)
3. Creates `.beads/memory/` directory and `knowledge.jsonl`
4. Copies hooks to `.claude/hooks/`
5. Copies commands to `.claude/commands/`
6. Updates `.claude/settings.json` using jq to merge hooks
7. Updates `.gitignore` to exclude `.beads/`

The `uninstall.sh` script:
1. Removes hooks from `.claude/hooks/`
2. Removes commands from `.claude/commands/`
3. Updates `.claude/settings.json` to delete hook entries (not set to null)
4. Preserves `.beads/` directory and accumulated knowledge

## Key Implementation Details

### Memory Capture Detection

The `memory-capture.sh` hook detects this pattern in Bash commands:

```bash
bd comment add {BEAD_ID} "LEARNED: ..."
bd comment add {BEAD_ID} "DECISION: ..."
bd comment add {BEAD_ID} "FACT: ..."
bd comment add {BEAD_ID} "PATTERN: ..."
bd comment add {BEAD_ID} "INVESTIGATION: ..."
```

Note: The hook expects `bd comments add` (plural) in the regex but most users use `bd comment add` (singular). This may need to be fixed.

### Auto-Recall Search Strategy

The `auto-recall.sh` hook:
1. Gets open/in-progress beads using `bd list --status=open --json`
2. Extracts keywords (4+ chars, excluding common words) from bead titles
3. Adds keywords from git branch name (if not main/master)
4. Searches `knowledge.jsonl` for each keyword
5. Deduplicates and returns top 10 matches
6. Falls back to recent 10 entries if no search terms

### Knowledge Rotation

When `knowledge.jsonl` exceeds 1000 lines:
1. First 500 lines are appended to `knowledge.archive.jsonl`
2. Remaining 500 lines become the new `knowledge.jsonl`
3. Search with `recall.sh --all` to include archive

## Design Differences from Related Projects

**vs. semantic-beads**:
- No worktree enforcement
- No supervisor validation
- No epic isolation complexity
- Same memory system, simpler orchestration

**vs. compound-engineering**:
- Persistent SQLite-backed knowledge (not markdown)
- Issue tracking integration (all workflows create/update beads)
- Auto-recall (knowledge injected automatically)
- Tagged knowledge for better search/retrieval
