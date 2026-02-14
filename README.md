# Beads Compound Claude Code Plugin

A Claude Code plugin providing beads-based persistent memory with multi-agent workflows.

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
| **beads-compound** | 0.5.0 | 28 agents, 25 commands, 15 skills, persistent memory |

## Quick Install

Prerequisites: [beads CLI](https://github.com/steveyegge/beads) (`bd`), `jq`

### Native Plugin System (not deployed yet)

```bash
# Add the marketplace
/plugin marketplace add https://github.com/roberto-mello/beads-compound-plugin

# Install the plugin
/plugin install beads-compound

# Restart Claude Code
```

Memory auto-bootstraps on first session in any beads-enabled project -- no extra setup needed.

### Manual Install

```bash
# Clone and review the source
git clone https://github.com/roberto-mello/beads-compound-plugin.git
cd beads-compound-plugin

# Global install (commands, agents, skills available everywhere)
./install.sh

# Per-project install for memory features (repeat per project)
./install.sh /path/to/your-project

# Restart Claude Code after each install
```

**What each install does:**
- **Global**: Commands, agents, skills -> `~/.claude` + auto-detection hook for beads projects
- **Per-Project**: Memory hooks, knowledge storage, auto-recall -> `.claude/hooks` and `.beads/memory/`
- **Smart duplication prevention**: Per-project install skips components already installed globally

**Tip:** Use `--yes` or `-y` to skip confirmation prompts (e.g. `./install.sh --yes`).

### Multi-Platform Support

beads-compound supports multiple AI coding tools beyond Claude Code:

#### OpenCode

OpenCode support includes the core memory system (auto-recall and knowledge capture). Commands, agents, and skills are Claude Code-specific and don't translate.

**Manual setup:**
```bash
# Copy plugin files to OpenCode plugins directory
mkdir -p .opencode/plugins/beads-compound
cp plugins/beads-compound/opencode/plugin.ts .opencode/plugins/beads-compound/
cp plugins/beads-compound/opencode/package.json .opencode/plugins/beads-compound/
cp -r plugins/beads-compound/hooks .opencode/plugins/beads-compound/

# Install Bun dependencies
cd .opencode/plugins/beads-compound
bun install
```

**What works:**
- Auto-recall: injects relevant knowledge at session start
- Memory capture: extracts knowledge from `bd comments add`
- Subagent wrapup: warns when subagents complete without logging knowledge

**AGENTS.md:** OpenCode reads `AGENTS.md` (not `CLAUDE.md`). For dual-tool projects, create a symlink: `ln -s CLAUDE.md AGENTS.md`

#### Gemini CLI

Gemini CLI uses the same stdin/stdout JSON protocol as Claude Code, so shell scripts work without modification.

**Install via extension:**
```bash
gemini extensions install https://github.com/roberto-mello/beads-compound-plugin
```

**What works:**
- SessionStart → auto-recall.sh
- AfterTool (bash) → memory-capture.sh
- AfterAgent → subagent-wrapup.sh

**Note:** Gemini CLI reads `GEMINI.md` by default (configurable via `context.fileName` setting).

#### Codex CLI / Antigravity

**Not yet supported.** Codex CLI hook system is planned but not shipped (PR #11067 closed). Antigravity has no lifecycle event system.

## What's Included

### Always-On Features

1. **Automatic Knowledge Capture** -- Any `bd comments add` with LEARNED/DECISION/FACT/PATTERN/INVESTIGATION gets extracted and stored in both SQLite FTS5 (`knowledge.db`) and JSONL (`knowledge.jsonl`)

2. **Automatic Knowledge Recall** -- Session start hook injects relevant knowledge based on your current beads, using FTS5 full-text search with BM25 ranking for significantly better results on conceptual and multi-word queries

3. **Subagent Knowledge Enforcement** -- Subagents are prompted to log learnings before completing

### Commands (25)

#### Beads Workflow Commands (7)

| Command | Description |
|---------|-------------|
| `/beads-brainstorm` | Explore ideas collaboratively before planning |
| `/beads-plan` | Research and plan using multiple agents, create epic + child beads |
| `/beads-work` | Work on a single bead with full lifecycle |
| `/beads-parallel` | Work on multiple beads in parallel via subagents |
| `/beads-review` | Multi-agent code review before closing bead |
| `/beads-checkpoint` | Save progress, capture knowledge, commit |
| `/beads-compound` | Document solved problems as persistent knowledge |

#### Planning & Triage Commands (3)

| Command | Description |
|---------|-------------|
| `/deepen-plan` | Enhance plan with parallel research agents |
| `/plan-review` | Multi-agent review of epic plan |
| `/triage` | Prioritize and categorize beads |

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

### Hooks (4 + shared library)

| Hook | Trigger | Purpose |
|------|---------|---------|
| auto-recall.sh | SessionStart | Inject relevant knowledge at session start (FTS5-first, grep fallback) |
| memory-capture.sh | PostToolUse (Bash) | Extract knowledge from bd comments (dual-write to SQLite + JSONL) |
| subagent-wrapup.sh | SubagentStop | Ensure subagents log learnings |
| check-memory.sh | SessionStart (global) | Auto-detect beads projects missing memory setup |
| knowledge-db.sh | (library) | Shared SQLite FTS5 functions sourced by other hooks |

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
/beads-parallel BD-001                      # Implement all child beads in parallel
/beads-review BD-001                        # Review everything
/beads-checkpoint                           # Ship it
```

Or go full auto:

```bash
/lfg "Add OAuth"                            # Full autonomous workflow
```

For ad-hoc sessions where you might have been working on something without a beads issue,
you can `/beads-checkpoint` to capture memories about the current context, and then
continue working.

### Lightweight Usage (No Commands Needed)

```bash
bd create "Fix login bug" -d "Users can't log in with OAuth"
# Work normally...
bd comments add BD-001 "LEARNED: OAuth redirect URI must match exactly"
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

Knowledge is stored in two formats:

- **SQLite FTS5** (`knowledge.db`) -- Primary search backend with full-text search and BM25 ranking
- **JSONL** (`knowledge.jsonl`) -- Portable export format, grep-compatible fallback

Both are written to simultaneously. If `sqlite3` is unavailable, only JSONL is written and grep-based search is used automatically.

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

- **FTS5 Search**: Uses porter stemming and BM25 ranking -- "webhook authentication" finds entries about HMAC signature verification even when those exact words don't appear together
- **Auto-tagging**: Keywords detected and added as tags
- **Git-tracked**: Knowledge files are committed to git for team sharing and portability
- **Conflict-free collaboration**: Multiple users can capture knowledge simultaneously without merge conflicts
- **Auto-sync**: First session after `git pull` automatically imports new knowledge into local search index
- **Rotation**: After 5000 entries, oldest 2500 archived (JSONL only)
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
│       ├── hooks/                  # 4 hooks + shared library + hooks.json
│       ├── scripts/
│       └── .mcp.json
├── install.sh
├── uninstall.sh
├── CLAUDE.md
└── README.md
```

## Migrating Existing Projects

If you already have a project using the plugin with an existing `knowledge.jsonl`, re-running the installer will upgrade it:

```bash
# Re-run the installer (safe to run on existing installs)
bash /path/to/beads-compound-plugin/install.sh /path/to/your-project
```

On the next Claude Code session start, the system will automatically:
1. Create `knowledge.db` with the FTS5 schema
2. Import all entries from your existing `knowledge.jsonl` and `knowledge.archive.jsonl`
3. Import any knowledge-prefixed comments from `beads.db`

After this one-time import, new entries are written to both formats. Your existing JSONL files remain intact and continue to be written to.

**Prerequisite**: `sqlite3` must be available (pre-installed on macOS and most Linux distributions). If missing, the system gracefully falls back to grep-based search with no errors.

## Uninstall

```bash
# Global uninstall
./uninstall.sh

# Project-specific uninstall
./uninstall.sh /path/to/your-project
```

Removes plugin components but preserves `.beads/` data and accumulated knowledge. Global uninstall also removes the `check-memory` hook and plugin source path.

## Changes from Compound Engineering

This plugin is a fork of [compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) (MIT license) with the following changes:

### Memory System

- Replaced markdown-based knowledge storage with beads-based persistent memory (`.beads/memory/knowledge.jsonl`)
- SQLite FTS5 full-text search with BM25 ranking for knowledge recall, improving precision by 18%, recall by 17%, and MRR by 24% over grep-based search across 25 benchmark queries
- Automatic knowledge capture from `bd comments add` with typed prefixes (LEARNED/DECISION/FACT/PATTERN/INVESTIGATION), dual-writing to SQLite (for fast searching with fuzzy matching) and JSONL (for committing to git)
- Automatic knowledge recall at session start based on open beads and git branch context
- Subagent knowledge enforcement via `SubagentStop` hook
- All workflows create and update beads instead of markdown files
- Automatic one-time backfill from existing JSONL and beads.db comments on first FTS5 run
- First session (like cloning a beads-compound enabled repo) triggers rebuilding the FTS5 index from the JSONL in git. Everything self-heals on first session.

### Performance Optimizations

- **Context budget optimization (94% reduction)**: Plugin now uses only 8,227 chars of Claude Code's 16,000 char description budget. This prevents components from being silently excluded from Claude's context.
  - Trimmed all 28 agent descriptions to under 250 chars, moving verbose examples into agent bodies wrapped in `<examples>` tags
  - Added `disable-model-invocation: true` to 17 manual utility commands (they remain available when explicitly invoked via `/command-name` but don't clutter Claude's auto-suggestion context)
  - Added `disable-model-invocation: true` to 7 manual utility skills (beads-knowledge, create-agent-skills, file-todos, skill-creator, git-worktree, rclone, gemini-imagegen)
  - Core beads workflow commands (`/beads-brainstorm`, `/beads-plan`, `/beads-work`, `/beads-parallel`, `/beads-review`, `/beads-compound`, `/deepen-plan`, `/plan-review`) remain fully auto-discoverable
- **Model tier assignments**: Each agent specifies a `model:` field (haiku/sonnet/opus) based on reasoning complexity, reducing costs 60-70% compared to running all agents on the default model. High-frequency agents like `learnings-researcher` run on Haiku; deep reasoning agents like `architecture-strategist` run on Opus.

### Structural Changes

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

[Every](https://every.to)'s [writing on compound engineering](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents) is well worth reading.

Task tracking is powered by Steve Yegge's [Beads](https://github.com/steveyegge/beads).

## License

MIT (same as compound-engineering-plugin)
