# Beads Compound Engineering Plugin

A Claude Code / OpenCode / Gemini plugin providing beads-based persistent memory with multi-agent workflows.

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
| **beads-compound** | 0.6.0 | 28 agents, 25 commands, 15 skills, persistent memory |

## Quick Install

Prerequisites: [beads CLI](https://github.com/steveyegge/beads) (`bd`), `jq`

### Native Plugin System (not yet live)

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

**Install:**
```bash
# Global install (to ~/.config/opencode)
./install.sh --opencode

# Or project-specific install
./install.sh --opencode /path/to/your-project
```

The installer copies the TypeScript plugin to `~/.config/opencode/plugins/beads-compound/` (global) or `.opencode/plugins/beads-compound/` (project-specific) and installs dependencies with Bun.

#### Gemini CLI

**Install:**
```bash
# Global install (to ~/.config/gemini)
./install.sh --gemini

# Or project-specific install
./install.sh --gemini /path/to/your-project
```

The installer copies hooks to `~/.config/gemini/hooks/` (global) or `.gemini/hooks/` (project-specific).

#### Codex CLI / Antigravity

**Not yet supported.** Codex CLI hook system is planned but not shipped (PR #11067 closed). Antigravity has no lifecycle event system.

## What's Included

### Always-On Features

1. **Automatic Knowledge Capture** -- Any `bd comments add` with LEARNED/DECISION/FACT/PATTERN/INVESTIGATION gets extracted and stored in both SQLite FTS5 (`knowledge.db`) and JSONL (`knowledge.jsonl`)

2. **Automatic Knowledge Recall** -- Session start hook injects relevant knowledge based on your current beads, using FTS5 full-text search with BM25 ranking for significantly better results on conceptual and multi-word queries

3. **Subagent Knowledge Enforcement** -- Subagents are prompted to log learnings before completing

### Commands (25)

Commands are organized by use case to help you choose the right tool for the job.

#### Planning & Discovery (4 commands)

Explore ideas and create structured plans before writing code.

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/beads-brainstorm` | Explore ideas collaboratively | When requirements are unclear or you need to explore approaches |
| `/beads-plan` | Research and create epic with child beads | Start every feature - creates structured plan with research |
| `/beads-deepen` | Enhance plan with parallel research agents | For complex features - adds depth and best practices |
| `/beads-plan-review` | Multi-agent review of epic plan | Before implementation - catch issues early |

#### Executing Work (3 commands)

Implement features and fix bugs using beads for tracking.

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/beads-work` | Work on a single bead with full lifecycle | Standard workflow - one bead at a time |
| `/beads-parallel` | Work on multiple beads in parallel via subagents | Speed up delivery - multiple independent beads |
| `/beads-triage` | Prioritize and categorize beads | After planning or review - organize work queue |

#### Reviewing & Quality (2 commands)

Ensure code quality and capture knowledge before shipping.

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/beads-review` | Multi-agent code review | Before closing beads - comprehensive quality check |
| `/beads-import` | Import markdown plans into beads | When you have external plans to convert |

#### Saving Progress (2 commands)

Capture knowledge and save session state.

| Command | Description | When to Use |
|---------|-------------|-------------|
| `/beads-checkpoint` | Save progress, create/update beads, commit | Mid-session - checkpoint your work |
| `/beads-compound` | Deep problem documentation with parallel analysis | After solving hard problems - share learnings |

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

## Workflow Examples

Choose a workflow based on your needs. Each workflow shows a complete path from idea to shipped code.

### Quick Start Workflow

Fast iteration for simple features or bugs.

```
/beads-brainstorm "add user notifications"
        ↓
/beads-plan "add user notifications"       # Creates BD-001 with child beads
        ↓
/beads-work BD-001.1                       # Implement first child bead
        ↓
/beads-review BD-001.1                     # Multi-agent code review
        ↓
/beads-checkpoint                          # Commit and capture knowledge
```

**Use when:** Feature is straightforward, requirements are clear, low complexity.

### Deep Planning Workflow

Thorough planning for complex features with research and review.

```
/beads-brainstorm "oauth authentication"
        ↓
/beads-plan "oauth authentication"         # Creates BD-002 with initial plan
        ↓
/beads-deepen BD-002                       # Enhances with best practices research
        ↓
/beads-plan-review BD-002                  # Multi-agent plan review
        ↓
/beads-triage BD-002                       # Prioritize child beads
        ↓
/beads-work BD-002.1                       # Start implementation
        ↓
/beads-checkpoint                          # Save progress
        ↓
/beads-review BD-002.1                     # Review implementation
        ↓
/beads-compound BD-002.1                   # Document learnings
```

**Use when:** Complex features, security-critical, architectural changes, unfamiliar territory.

### Parallel Work Workflow

Maximum speed by working on multiple beads simultaneously.

```
/beads-plan "api refactor"                 # Creates BD-003 with child beads
        ↓
/beads-parallel BD-003                     # Work on all child beads in parallel
        ↓
/beads-review BD-003                       # Review all changes
        ↓
/beads-checkpoint                          # Ship it
```

**Use when:** Multiple independent tasks, tight deadlines, clear requirements.

### Import & Refine Workflow

Starting from existing markdown plans or external documentation.

```
/beads-import plan.md                      # Creates BD-004 from markdown
        ↓
/beads-deepen BD-004                       # Add research and best practices
        ↓
/beads-work BD-004.1                       # Start implementation
        ↓
/beads-checkpoint                          # Save progress
```

**Use when:** You have external plans, migrating from other tools, inheriting documentation.

### Full Autonomous Workflow

Let the agent handle everything end-to-end.

```bash
/lfg "Add OAuth authentication"            # Full autonomous workflow
```

**Use when:** You trust the agent fully, clear requirements, well-understood problem domain.

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
  - Core beads workflow commands (`/beads-brainstorm`, `/beads-plan`, `/beads-work`, `/beads-parallel`, `/beads-review`, `/beads-compound`, `/beads-deepen`, `/beads-plan-review`) remain fully auto-discoverable
- **Model tier assignments**: Each agent specifies a `model:` field (haiku/sonnet/opus) based on reasoning complexity, reducing costs 60-70% compared to running all agents on the default model. High-frequency agents like `learnings-researcher` run on Haiku; deep reasoning agents like `architecture-strategist` run on Opus.

### Structural Changes

- Rewrote `learnings-researcher` to search `knowledge.jsonl` instead of markdown docs
- Adapted `code-simplicity-reviewer` to protect `.beads/memory/` files
- Renamed `compound-docs` skill to `beads-knowledge`
- Added `beads-` prefix to all commands to avoid conflicts

## Troubleshooting

### Memory Features Not Working

If automatic knowledge capture or recall isn't working, check your setup:

#### Claude Code

```bash
# Check if hooks are installed
ls -la .claude/hooks/

# Check hook configuration
cat .claude/settings.json | jq '.hooks'

# Check memory directory
ls -la .beads/memory/

# Test knowledge capture manually
bd comments add <BEAD_ID> "LEARNED: Testing memory capture"
tail -1 .beads/memory/knowledge.jsonl

# Test recall manually
bash .beads/memory/recall.sh
```

**Expected hooks in settings.json:**
- `SessionStart`: `auto-recall.sh`
- `PostToolUse` (Bash matcher): `memory-capture.sh`
- `SubagentStop`: `subagent-wrapup.sh`

#### OpenCode

```bash
# Check if hooks are installed (project-specific)
ls -la .opencode/hooks/

# Or global install
ls -la ~/.config/opencode/plugins/beads-compound/hooks/

# Check hook configuration
cat .opencode/settings.json | jq '.hooks'

# Check memory directory
ls -la .beads/memory/

# Test knowledge capture manually
bd comments add <BEAD_ID> "LEARNED: Testing memory capture"
tail -1 .beads/memory/knowledge.jsonl

# Test memory-capture hook directly
echo '{"tool_name":"Bash","tool_input":{"command":"bd comments add test-123 \"LEARNED: Test entry\""}}' | bash .opencode/hooks/memory-capture.sh
```

#### Gemini CLI

```bash
# Check if hooks are installed (project-specific)
ls -la .gemini/hooks/

# Or global install
ls -la ~/.config/gemini/hooks/

# Check hook configuration in gemini-extension.json
cat gemini-extension.json | jq '.hooks'

# Check memory directory
ls -la .beads/memory/

# Test knowledge capture manually
bd comments add <BEAD_ID> "LEARNED: Testing memory capture"
tail -1 .beads/memory/knowledge.jsonl
```

### Common Issues

**No knowledge entries being saved:**
- Ensure you're using `bd comments add <BEAD_ID> "LEARNED: ..."` format (not `bd comment`)
- Check that the hook is configured in settings.json with correct matcher (e.g., `"Bash"` for PostToolUse)
- Verify `.beads/memory/` directory exists
- Test the hook manually using the platform-specific commands above

**Knowledge recall not showing context:**
- Check that `auto-recall.sh` is in SessionStart hooks
- Verify you have open or in_progress beads: `bd list --status=open`
- Run manual recall to test: `bash .beads/memory/recall.sh`
- Check if `knowledge.jsonl` has entries: `wc -l .beads/memory/knowledge.jsonl`

**SQLite search not working:**
- Verify `sqlite3` is installed: `which sqlite3`
- Check database exists: `ls -la .beads/memory/knowledge.db`
- System automatically falls back to grep if SQLite unavailable

**Duplicate entries in knowledge.jsonl:**
- This was fixed in v0.6.0+. Update to latest version.
- To clean up existing duplicates:
  ```bash
  cd .beads/memory
  cp knowledge.jsonl knowledge.jsonl.backup
  jq -s 'group_by(.key) | map(max_by(.ts)) | .[] | @json' knowledge.jsonl > knowledge.jsonl.tmp
  mv knowledge.jsonl.tmp knowledge.jsonl
  ```

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
