# Beads Compound Plugin Marketplace

A Claude Code plugin marketplace providing beads-based persistent memory with multi-agent workflows.

Built on [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) by the team at [Every](https://every.to) -- Kieran Klaassen, Dan Shipper, Julik Tarkhanov, and contributors. Their plugin pioneered the idea that each unit of engineering work should make subsequent units easier, not harder. This project extends that philosophy with beads-based persistent memory and several performance optimizations.

## Philosophy

**Each unit of engineering work should make subsequent units easier, not harder.**

This plugin achieves this through:

- **Task Tracking**: Uses Steve Yegge's [Beads](https://github.com/steveyegge/beads) for persistent, structured memory for agents, replacing messy markdown plans with a dependency-aware graph, allowing agents to handle long-horizon tasks without losing context.
- **Persistent Memory**: Uses Beads comments as basis to automatically capture and recall knowledge, allowing agents to learn with each iteration.
- **Multi-Agent Workflows**: 28 specialized agents for research, review, design, and planning
- **Lightweight by Default**: Most work runs normally with automatic knowledge capture
- **Opt-In Orchestration**: Heavy workflows only when you need them

## Available Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| **beads-compound** | 0.3.0 | 28 agents, 25 commands, 15 skills, persistent memory |

## Quick Install

Prerequisites: `jq` (required for all installs), [beads CLI](https://github.com/steveyegge/beads) (`bd` - only for project-specific installs)

```bash
# Clone the marketplace
git clone https://github.com/roberto-mello/beads-compound-plugin.git
cd beads-compound-plugin

# Global install (recommended - commands, agents, skills available everywhere)
./install.sh

# Or project-specific install (includes beads memory integration)
./install.sh /path/to/your-project

# Restart Claude Code
```

**Global vs Project-Specific:**
- **Global** (`./install.sh`): Installs to `~/.claude` - commands, agents, and skills available in all sessions
- **Project-Specific** (`./install.sh /path/to/project`): Additionally includes beads memory hooks and auto-recall system

### OpenCode Installation

For OpenCode users, download the pre-converted plugin from releases:

```bash
# Download and extract the latest release
curl -L https://github.com/roberto-mello/beads-compound-plugin/releases/latest/download/beads-compound-opencode.tar.gz | tar xz
cd beads-compound-opencode

# Run installer (safely merges into existing config)
./install-opencode.sh
```

The installer:
- Backs up your existing `opencode.json` before merging
- Adds 28 agents, 24 skills, 25 commands without overwriting your config
- Installs hooks plugin with memory system

**Why not use the converter directly?** The official `@every-env/compound-plugin` converter has a bug with matcher-less hooks (SessionStart, SubagentStop). We've submitted a [fix](https://github.com/EveryInc/compound-engineering-plugin/pull/160). Once merged, you can convert directly from source:

```bash
bunx @every-env/compound-plugin install ./plugins/beads-compound --to opencode
```

### Codex Conversion

For Codex compatibility:

```bash
bunx @every-env/compound-plugin install ./plugins/beads-compound --to codex
```

## What's Included

### Always-On Features

1. **Automatic Knowledge Capture** -- Any `bd comment add` with LEARNED/DECISION/FACT/PATTERN/INVESTIGATION gets extracted and stored in searchable `.beads/memory/knowledge.jsonl`

2. **Automatic Knowledge Recall** -- Session start hook injects relevant knowledge based on your current beads

3. **Subagent Knowledge Enforcement** -- Subagents are prompted to log learnings before completing

### Commands (25)

#### Beads Workflow Commands (6)

| Command | Description |
|---------|-------------|
| `/beads-brainstorm` | Explore ideas collaboratively before planning |
| `/beads-plan` | Research and plan using multiple agents, create epic + child beads |
| `/beads-work` | Work on a bead with context, auto-recall, and agent assistance |
| `/beads-review` | Multi-agent code review before closing bead |
| `/beads-checkpoint` | Save progress, capture knowledge, commit |
| `/beads-compound` | Document solved problems as persistent knowledge |

#### Planning & Triage Commands (4)

| Command | Description |
|---------|-------------|
| `/deepen-plan` | Enhance plan with parallel research agents |
| `/plan-review` | Multi-agent review of epic plan |
| `/triage` | Prioritize and categorize beads |
| `/resolve-parallel` | Resolve multiple beads in parallel |

#### Utility Commands (15)

| Command | Description |
|---------|-------------|
| `/lfg` | Full autonomous engineering workflow |
| `/changelog` | Create engaging changelogs for recent merges |
| `/create-agent-skill` | Create or edit Claude Code skills |
| `/generate-command` | Create a new custom slash command |
| `/heal-skill` | Fix incorrect SKILL.md files |
| `/deploy-docs` | Validate and prepare documentation for deployment |
| `/release-docs` | Build and update documentation |
| `/feature-video` | Record a video walkthrough for a PR |
| `/agent-native-audit` | Comprehensive agent-native architecture review |
| `/test-browser` | Run browser tests on affected pages |
| `/xcode-test` | Build and test iOS apps on simulator |
| `/report-bug` | Report a bug in the plugin |
| `/reproduce-bug` | Reproduce and investigate a bug |
| `/resolve-pr-parallel` | Resolve all PR comments in parallel |
| `/resolve-todo-parallel` | Resolve all pending TODOs in parallel |

### Agents (28) -- Cost-Optimized by Model Tier

All agents include model tier assignments for optimal cost/performance balance:

**Haiku Tier (5 agents)** -- Structured tasks, fast and cheap:
- learnings-researcher, repo-research-analyst, framework-docs-researcher, ankane-readme-writer, lint

**Sonnet Tier (14 agents)** -- Moderate judgment, balanced cost:
- code-simplicity-reviewer, kieran-rails-reviewer, kieran-python-reviewer, kieran-typescript-reviewer, dhh-rails-reviewer, security-sentinel, pattern-recognition-specialist, deployment-verification-agent, best-practices-researcher, git-history-analyzer, design-implementation-reviewer, design-iterator, figma-design-sync, bug-reproduction-validator, pr-comment-resolver, every-style-editor

**Opus Tier (9 agents)** -- Deep reasoning, premium quality:
- architecture-strategist, performance-oracle, data-integrity-guardian, data-migration-expert, agent-native-reviewer, julik-frontend-races-reviewer, spec-flow-analyzer

The most frequently invoked agents (learnings-researcher, repo-research-analyst) run on Haiku for maximum efficiency. Review workflows intelligently mix tiers based on complexity.

### Skills (15)

| Skill | Description |
|-------|-------------|
| `git-worktree` | Manage git worktrees for parallel bead work |
| `brainstorming` | Structured brainstorming with bead output |
| `create-agent-skills` | Create new agents and skills |
| `agent-native-architecture` | Design agent-native system architectures |
| `beads-knowledge` | Document solved problems as knowledge entries |
| `agent-browser` | Browser automation for testing and screenshots |
| `andrew-kane-gem-writer` | Write Ruby gems following Andrew Kane's style |
| `dhh-rails-style` | Rails development following DHH's conventions |
| `dspy-ruby` | DSPy integration for Ruby applications |
| `every-style-editor` | Every's house style guide for content editing |
| `file-todos` | Find and manage TODO comments in code |
| `frontend-design` | Frontend design patterns and best practices |
| `gemini-imagegen` | Generate images using Google's Gemini |
| `rclone` | Cloud storage file management with rclone |
| `skill-creator` | Create new skills from templates |

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
/deepen-plan BD-001             Enhance plan with research
        |
/plan-review BD-001             Get multi-agent feedback on plan
        |
/triage BD-001                  Prioritize child beads
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
/resolve-parallel BD-001                    # Implement all child beads in parallel
/beads-review BD-001                        # Review everything
/beads-checkpoint                           # Ship it
```

Or go full auto:

```bash
/lfg "Add OAuth"                            # Full autonomous workflow
```

### Lightweight Usage (No Commands Needed)

```bash
bd create "Fix login bug" -d "Users can't log in with OAuth"
# Work normally...
bd comment add BD-001 "LEARNED: OAuth redirect URI must match exactly"
bd close BD-001
# Knowledge captured automatically, recalled next session
```

## Cost Optimization

The plugin's 28 agents are assigned to three model tiers based on reasoning complexity:

| Tier | Agents | Use Case | Cost Impact |
|------|--------|----------|-------------|
| **Haiku** | 5 | Structured information retrieval, template-based output | Lowest cost, fastest response |
| **Sonnet** | 14 | Moderate judgment with established patterns | Balanced cost/quality |
| **Opus** | 9 | Deep architectural reasoning, nuanced security analysis | Premium quality for critical decisions |

**Key optimizations:**
- Most frequently invoked agents (`learnings-researcher`, `repo-research-analyst`) use Haiku
- Review workflows like `/beads-review` fire 13+ agents, mostly Sonnet tier
- Opus reserved for architectural/security decisions requiring deep reasoning
- Commands automatically dispatch agents at their assigned tier via frontmatter `model:` field

This tiering reduces costs by 60-70% compared to running all agents on Opus while maintaining quality where it matters.

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
│       │   ├── workflow/           # 5 workflow agents
│       │   └── docs/               # 1 docs agent
│       ├── commands/               # 25 commands
│       ├── skills/                 # 15 skills
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

## Changes from Compound Engineering

This plugin is a fork of [compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) (MIT license) with the following changes:

### Memory System

- Replaced markdown-based knowledge storage with beads-based persistent memory (`.beads/memory/knowledge.jsonl`)
- Added automatic knowledge capture from `bd comment add` with typed prefixes (LEARNED/DECISION/FACT/PATTERN/INVESTIGATION)
- Added automatic knowledge recall at session start based on open beads and git branch context
- Added subagent knowledge enforcement via `SubagentStop` hook
- All workflows create and update beads instead of markdown files

### Performance Optimizations

- **Context budget optimization (94% reduction)**: Plugin now uses only 8,227 chars of Claude Code's 16,000 char description budget (51.4%), down from 136,639 chars (854% over budget). This prevents components from being silently excluded from Claude's context. Achieved through:
  - Trimmed all 28 agent descriptions to under 250 chars, moving verbose examples into agent bodies wrapped in `<examples>` tags
  - Added `disable-model-invocation: true` to 17 manual utility commands (they remain available when explicitly invoked via `/command-name` but don't clutter Claude's auto-suggestion context)
  - Added `disable-model-invocation: true` to 7 manual utility skills (beads-knowledge, create-agent-skills, file-todos, skill-creator, git-worktree, rclone, gemini-imagegen)
  - Core beads workflow commands (`/beads-brainstorm`, `/beads-plan`, `/beads-work`, `/beads-review`, `/beads-compound`, `/deepen-plan`, `/plan-review`, `/resolve-parallel`) remain fully auto-discoverable
- **Model tier assignments**: Each agent specifies a `model:` field (haiku/sonnet/opus) based on reasoning complexity, reducing costs 60-70% compared to running all agents on the default model. High-frequency agents like `learnings-researcher` run on Haiku; deep reasoning agents like `architecture-strategist` run on Opus.

### Structural Changes

- Restructured as a marketplace plugin with `install.sh`/`uninstall.sh` at root
- Rewrote `learnings-researcher` to search `knowledge.jsonl` instead of markdown docs
- Adapted `code-simplicity-reviewer` to protect `.beads/memory/` files
- Renamed `compound-docs` skill to `beads-knowledge`
- Added `beads-` prefix to all commands to avoid conflicts

## Importing Existing Plans

```bash
bash ~/beads-compound-plugin/plugins/beads-compound/scripts/import-plan.sh your-plan.md "Epic Title"
```

Creates an epic bead with child beads for each implementation step.

## Acknowledgments

This project builds on the excellent work of the [Every](https://every.to) team and their [compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin). The multi-agent workflow architecture, agent designs, and the core philosophy of compounding engineering knowledge were created by Kieran Klaassen, Dan Shipper, Julik Tarkhanov, and the Every engineering team. Their [writing on compound engineering](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents) is well worth reading.

Task tracking is powered by Steve Yegge's [Beads](https://github.com/steveyegge/beads).

## License

MIT (same as compound-engineering-plugin)
