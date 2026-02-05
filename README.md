# Beads Compound Plugin

A Claude Code plugin that combines beads-based memory with compound-engineering's multi-agent workflows.

## Philosophy

**Each unit of engineering work should make subsequent units easier—not harder.**

This plugin achieves this through:
- **Persistent memory**: Beads-based knowledge capture and automatic recall
- **Multi-agent workflows**: Leverage specialized agents for research, review, and planning
- **Lightweight by default**: Most work runs normally with automatic knowledge capture
- **Opt-in orchestration**: Heavy workflows only when you need them

## What This Provides

### Always-On Features

1. **Automatic Knowledge Capture**
   - Any `bd comment add` with LEARNED/DECISION/FACT/PATTERN/INVESTIGATION gets extracted
   - Stored in searchable `.beads/memory/knowledge.jsonl`
   - Auto-tagged based on content
   - Subagents are automatically prompted to log learnings before completing

2. **Automatic Knowledge Recall**
   - Session start hook injects relevant knowledge based on your current beads
   - No manual searching required for common workflows

3. **Beads Integration**
   - All workflows are beads-aware
   - Commands create/update beads automatically
   - Knowledge is linked to beads for context

### Workflow Commands

| Command | Description |
|---------|-------------|
| `/beads:plan` | Research and plan using compound-engineering agents, create beads |
| `/beads:work` | Work on a bead with agent assistance |
| `/beads:review` | Multi-agent code review before closing bead |
| `/beads:research` | Deep research using specialized agents, results logged to bead |
| `/beads:checkpoint` | Save progress, file beads, capture knowledge |

### Agents Available

The plugin includes compound-engineering's specialized agents:

**Review Agents (14)**
- `kieran-rails-reviewer`, `kieran-python-reviewer`, `kieran-typescript-reviewer`
- `security-sentinel`, `performance-oracle`, `architecture-strategist`
- `data-integrity-guardian`, `code-simplicity-reviewer`
- And more...

**Research Agents (4)**
- `best-practices-researcher`, `framework-docs-researcher`
- `git-history-analyzer`, `repo-research-analyst`

**Design Agents (3)**
- `design-implementation-reviewer`, `design-iterator`, `figma-design-sync`

All agents automatically log their findings as knowledge comments on the relevant bead.

## Installation

Prerequisites: [beads CLI](https://github.com/steveyegge/beads) and `jq`

```bash
# Clone the plugin (one time)
git clone <this-repo> ~/beads-compound-plugin

# Install into your project
cd ~/beads-compound-plugin
./install.sh /path/to/your-project

# Or from your project directory
cd /path/to/your-project
bash ~/beads-compound-plugin/install.sh
```

Restart Claude Code after installing.

## Uninstall

```bash
cd ~/beads-compound-plugin
./uninstall.sh /path/to/your-project
```

This removes the plugin but preserves your `.beads/` data and accumulated knowledge.

## Importing Existing Plans

Have a plan in a markdown file? Import it into beads:

```bash
cd /path/to/your-project
bash ~/Documents/projects/beads-compound-plugin/scripts/import-plan.sh your-plan.md "Epic Title"
```

This creates:
- Epic bead with full plan as description
- Child beads for each implementation step
- Knowledge comments from research/decisions sections

See [IMPORTING-PLANS.md](IMPORTING-PLANS.md) for details and [examples/example-plan.md](examples/example-plan.md) for format.

## Usage

### Normal Workflow (Lightweight)

```bash
# Create a bead
bd create "Fix login bug" -d "Users can't log in with OAuth"

# Work on it normally
# Edit files, commit, etc.

# Log what you learned (auto-captured)
bd comment add BD-001 "LEARNED: OAuth redirect URI must match exactly"

# Close when done
bd close BD-001
```

**What happens automatically:**
- Knowledge extracted to `.beads/memory/knowledge.jsonl`
- Next session, relevant knowledge is injected if you work on similar beads

**Delegating to subagents:**

When you delegate work to a subagent, include a `BEAD_ID` in the prompt. The subagent will automatically be prompted to log learnings before completing:

```
Task(subagent_type="general-purpose", prompt="Investigate the OAuth flow. BEAD_ID: BD-001")
```

The subagent cannot complete until it adds at least one knowledge comment (LEARNED/DECISION/FACT/PATTERN/INVESTIGATION). This ensures subagent discoveries are captured automatically.

### Research & Planning Workflow

```bash
# Use agents to research and plan
/beads:plan "Add two-factor authentication"

# This will:
# 1. Create an epic bead
# 2. Dispatch research agents in parallel
# 3. Gather best practices, framework docs, existing patterns
# 4. Log findings as INVESTIGATION/FACT/DECISION
# 5. Create child beads for implementation steps
```

### Review Workflow

```bash
# After implementing a feature
/beads:review BD-005

# This will:
# 1. Dispatch multiple review agents in parallel
# 2. Security, performance, code quality, architecture checks
# 3. Log findings as comments on the bead
# 4. Create follow-up beads for issues found
```

### Deep Research Workflow

```bash
# Need to understand something complex
/beads:research BD-007 "How does Rails handle concurrent updates?"

# This will:
# 1. Dispatch specialized research agents
# 2. Search git history, docs, best practices
# 3. Log comprehensive findings to the bead
# 4. Tag knowledge for future recall
```

## Architecture

### Memory System

Knowledge is stored in `.beads/memory/knowledge.jsonl` with structure:

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

**Auto-tagging**: Keywords in content are detected and added as tags (auth, database, react, etc.)

**Rotation**: After 1000 entries, oldest 500 are moved to archive

**Search**: Use `.beads/memory/recall.sh` or let auto-recall inject at session start

### Hooks

| Hook | When | What |
|------|------|------|
| `SessionStart:auto-recall` | Session start | Inject relevant knowledge |
| `PostToolUse:memory-capture` | After `bd comment add` | Extract and store knowledge |
| `SubagentStop:subagent-wrapup` | Subagent completing | Prompt subagent to log learnings |

### Agents Integration

All compound-engineering agents are included and modified to:
- Accept `BEAD_ID` in their prompts
- Log findings using `bd comment add` with appropriate prefixes
- Tag knowledge based on their specialty

## Differences from semantic-beads

**Simpler orchestration**: No worktree enforcement, no complex supervisor validation. Just use agents with beads.

**More agents**: Full compound-engineering agent library instead of custom supervisors.

**Automatic context**: Auto-recall hook vs. manual recall.

**No epic complexity**: Can still create epic beads, but no special isolation/dispatch logic. Just use agents normally.

## Differences from compound-engineering

**Beads-based memory**: Persistent SQLite knowledge base vs. markdown docs.

**Issue tracking integration**: All workflows create/update beads automatically.

**Auto-recall**: Knowledge injected automatically vs. manual search.

**Tagged knowledge**: Auto-tagging enables better search and retrieval.

## Configuration

### Disable auto-recall

Edit `.claude/settings.json` and remove the `SessionStart` hook.

### Customize tagging

Edit `.claude/hooks/memory-capture.sh` and modify the tag detection list.

### Add custom agents

Place agent markdown files in `.claude/agents/` following compound-engineering's format.

## License

MIT
