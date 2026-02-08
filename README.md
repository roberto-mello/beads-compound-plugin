# Beads Compound Plugin Marketplace

A Claude Code plugin marketplace providing beads-based persistent memory with compound-engineering's multi-agent workflows.

## Philosophy

**Each unit of engineering work should make subsequent units easier, not harder.**

This plugin achieves this through:

- **Task Tracking**: Uses Steve Yegge's [Beads](https://github.com/steveyegge/beads) for persistent, structured memory for agents, replacing messy markdown plans with a dependency-aware graph, allowing agents to handle long-horizon tasks without losing context.
- **Persistent Memory**: Uses Beads comments as basis to automatically capture and recall knowledge, allowing agents to learn with each iteration.
- **Multi-Agent Workflows**: 27 specialized agents for research, review, design, and planning
- **Lightweight by Default**: Most work runs normally with automatic knowledge capture
- **Opt-In Orchestration**: Heavy workflows only when you need them

## Available Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| **beads-compound** | 0.2.0 | 27 agents, 11 commands, 5 skills, persistent memory |

## Quick Install

Prerequisites: [beads CLI](https://github.com/steveyegge/beads) (`bd`) and `jq`

```bash
# Clone the marketplace
git clone https://github.com/roberto-mello/beads-compound-plugin.git
cd beads-compound-plugin

# Install into your project
./install.sh /path/to/your-project

# Restart Claude Code
```

### Cross-Platform Conversion

For OpenCode or Codex compatibility:

```bash
# Convert to OpenCode format
bunx @every-env/compound-plugin install ./plugins/beads-compound --to opencode

# Convert to Codex format
bunx @every-env/compound-plugin install ./plugins/beads-compound --to codex
```

## What's Included

### Always-On Features

1. **Automatic Knowledge Capture** -- Any `bd comment add` with LEARNED/DECISION/FACT/PATTERN/INVESTIGATION gets extracted and stored in searchable `.beads/memory/knowledge.jsonl`

2. **Automatic Knowledge Recall** -- Session start hook injects relevant knowledge based on your current beads

3. **Subagent Knowledge Enforcement** -- Subagents are prompted to log learnings before completing

### Workflow Commands (11)

| Command | Description |
|---------|-------------|
| `/beads-brainstorm` | Explore ideas collaboratively before planning |
| `/beads-plan` | Research and plan using multiple agents, create epic + child beads |
| `/beads-deepen` | Enhance plan with parallel research agents |
| `/beads-plan-review` | Multi-agent review of epic plan |
| `/beads-triage` | Prioritize and categorize child beads |
| `/beads-work` | Work on a bead with context, auto-recall, and agent assistance |
| `/beads-review` | Multi-agent code review before closing bead |
| `/beads-research` | Deep research using 5 specialized agents |
| `/beads-checkpoint` | Save progress, capture knowledge, commit |
| `/beads-compound` | Document solved problems as persistent knowledge |
| `/beads-resolve-parallel` | Resolve multiple beads in parallel |

### Agents (27)

**Review (14)**: architecture-strategist, code-simplicity-reviewer, security-sentinel, performance-oracle, data-integrity-guardian, pattern-recognition-specialist, kieran-rails-reviewer, kieran-python-reviewer, kieran-typescript-reviewer, dhh-rails-reviewer, julik-frontend-races-reviewer, agent-native-reviewer, data-migration-expert, deployment-verification-agent

**Research (5)**: best-practices-researcher, framework-docs-researcher, repo-research-analyst, git-history-analyzer, learnings-researcher

**Design (3)**: design-implementation-reviewer, design-iterator, figma-design-sync

**Workflow (4)**: pr-comment-resolver, bug-reproduction-validator, lint, spec-flow-analyzer

**Docs (1)**: ankane-readme-writer

### Skills (5)

| Skill | Description |
|-------|-------------|
| `git-worktree` | Manage git worktrees for parallel bead work |
| `brainstorming` | Structured brainstorming with bead output |
| `create-agent-skills` | Create new agents and skills |
| `agent-native-architecture` | Design agent-native system architectures |
| `beads-knowledge` | Document solved problems as knowledge entries |

### MCP Servers

- **Context7** -- Framework documentation lookup

### Hooks (3)

| Hook | Trigger | Purpose |
|------|---------|---------|
| auto-recall.sh | SessionStart | Inject relevant knowledge at session start |
| memory-capture.sh | PostToolUse (Bash) | Extract knowledge from bd comments |
| subagent-wrapup.sh | SubagentStop | Ensure subagents log learnings |

## Recommended Workflow

```
/beads-brainstorm "idea"        Explore what to build
        |
/beads-plan "feature"           Research + create epic with child beads
        |
/beads-deepen BD-001            Enhance plan with research
        |
/beads-plan-review BD-001       Get multi-agent feedback on plan
        |
/beads-triage BD-001            Prioritize child beads
        |
/beads-work BD-001.1            Implement a child bead
        |
/beads-checkpoint               Save progress, capture knowledge
        |
/beads-review BD-001.1          Multi-agent code review
        |
/beads-compound BD-001.1        Document what you learned
```

Or go fast:

```bash
/beads-plan "Add OAuth"                     # Plan it
/beads-resolve-parallel BD-001              # Implement all child beads in parallel
/beads-review BD-001                        # Review everything
/beads-checkpoint                           # Ship it
```

### Lightweight Usage (No Commands Needed)

```bash
bd create "Fix login bug" -d "Users can't log in with OAuth"
# Work normally...
bd comment add BD-001 "LEARNED: OAuth redirect URI must match exactly"
bd close BD-001
# Knowledge captured automatically, recalled next session
```

## Architecture

### Memory System

Knowledge stored in `.beads/memory/knowledge.jsonl`:

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

- **Auto-tagging**: Keywords detected and added as tags
- **Rotation**: After 1000 entries, oldest 500 archived
- **Search**: `.beads/memory/recall.sh "keyword"` or automatic at session start

### Plugin Structure

```
beads-compound-plugin/              # Marketplace root
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   └── beads-compound/             # Plugin root
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── agents/
│       │   ├── review/             # 14 review agents
│       │   ├── research/           # 5 research agents
│       │   ├── design/             # 3 design agents
│       │   ├── workflow/           # 4 workflow agents
│       │   └── docs/               # 1 docs agent
│       ├── commands/               # 11 workflow commands
│       ├── skills/                 # 5 skills
│       ├── hooks/                  # 3 hooks + hooks.json
│       ├── scripts/
│       └── .mcp.json
├── install.sh
├── uninstall.sh
├── CLAUDE.md
└── README.md
```

## Uninstall

```bash
./uninstall.sh /path/to/your-project
```

Removes plugin components but preserves `.beads/` data and accumulated knowledge.

## Differences from Related Projects

**vs. semantic-beads**: Simpler orchestration (no worktrees, no supervisor validation). Full agent library instead of custom supervisors.

**vs. compound-engineering**: Beads-based persistent memory instead of markdown. Auto-recall. All workflows create/update beads. Tagged knowledge for better retrieval.

## Importing Existing Plans

```bash
bash ~/beads-compound-plugin/plugins/beads-compound/scripts/import-plan.sh your-plan.md "Epic Title"
```

Creates an epic bead with child beads for each implementation step.

## License

MIT
