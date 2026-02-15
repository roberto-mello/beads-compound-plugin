# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code plugin marketplace that provides beads-based persistent memory with compound-engineering's multi-agent workflows. The primary plugin is `beads-compound`, located at `plugins/beads-compound/`.

The plugin provides:
- 28 specialized agents (14 review, 5 research, 3 design, 5 workflow, 1 docs)
- 26 commands for brainstorming, planning, review, testing, and more
- 15 skills (git-worktree, brainstorming, create-agent-skills, agent-browser, dhh-rails-style, etc.)
- 3 hooks for automatic knowledge capture, recall, and subagent wrapup
- 1 MCP server (Context7 for framework documentation)
- Automatic knowledge capture from beads comments (LEARNED/DECISION/FACT/PATTERN/INVESTIGATION)
- Automatic knowledge recall at session start based on current beads

## Multi-Platform Support

beads-compound supports OpenCode and Gemini CLI in addition to Claude Code:

**OpenCode:** Core memory system (auto-recall, knowledge capture, subagent wrapup) via native TypeScript plugin at `plugins/beads-compound/opencode/plugin.ts`. Commands/agents/skills are Claude Code-specific. OpenCode reads `AGENTS.md`.

**Gemini CLI:** Full hook compatibility via `gemini-extension.json` manifest. Uses same stdin/stdout JSON protocol as Claude Code. Install: `gemini extensions install https://github.com/roberto-mello/beads-compound-plugin`

See README.md for detailed setup instructions.

## Repository Structure

```
beads-compound-plugin/              # Marketplace root
├── .claude-plugin/
│   └── marketplace.json            # Marketplace catalog
├── plugins/
│   └── beads-compound/             # Plugin root
│       ├── .claude-plugin/
│       │   └── plugin.json         # Plugin manifest (v0.6.0)
│       ├── agents/
│       │   ├── review/             # 14 review agents
│       │   ├── research/           # 5 research agents
│       │   ├── design/             # 3 design agents
│       │   ├── workflow/           # 5 workflow agents
│       │   └── docs/               # 1 docs agent
│       ├── commands/               # 26 commands
│       ├── skills/                 # 15 skills with supporting files
│       ├── hooks/
│       │   ├── hooks.json          # Plugin hook registration
│       │   ├── auto-recall.sh
│       │   ├── memory-capture.sh
│       │   ├── subagent-wrapup.sh
│       │   └── recall.sh
│       ├── opencode/
│       │   ├── plugin.ts           # OpenCode TypeScript plugin
│       │   └── package.json
│       ├── gemini/
│       │   └── settings.json       # Gemini CLI hook configuration
│       ├── gemini-extension.json   # Gemini extension manifest
│       ├── scripts/
│       │   └── import-plan.sh
│       └── .mcp.json               # Context7 MCP server
├── install.sh                      # Installer (at marketplace root)
├── uninstall.sh                    # Uninstaller (at marketplace root)
├── CLAUDE.md
└── README.md
```

## Plugin Installation

### Native Plugin System (Recommended)

```bash
# In Claude Code
/plugin marketplace add https://github.com/roberto-mello/beads-compound-plugin
/plugin install beads-compound
```

Memory auto-bootstraps on first session in any beads-enabled project.

### Manual Install

```bash
# From marketplace root
./install.sh /path/to/target-project

# Or from target project
bash /path/to/beads-compound-plugin/install.sh
```

**IMPORTANT**: The installer will fail if you try to install into the plugin directory itself. Always install into a separate target project.

The installer copies from `plugins/beads-compound/` into the target's `.claude/` directory:
- `hooks/` -> `.claude/hooks/`
- `commands/` -> `.claude/commands/`
- `agents/` -> `.claude/agents/`
- `skills/` -> `.claude/skills/`
- `.mcp.json` -> `.mcp.json` (merged if exists)
- Configures `settings.json` with hook definitions

### Uninstall

```bash
./uninstall.sh /path/to/target-project
```

## Development Commands

**Test the installer:**
```bash
mkdir -p /tmp/test-project && cd /tmp/test-project
git init && bd init
bash ~/Documents/projects/beads-compound-plugin/install.sh

# Verify
ls -la .claude/hooks/
ls -la .claude/commands/
ls -la .claude/agents/review/
ls -la .claude/skills/
cat .claude/settings.json | jq .
```

**Test uninstaller:**
```bash
bash ~/Documents/projects/beads-compound-plugin/uninstall.sh /tmp/test-project
```

**Test hook format:**
```bash
cat .claude/settings.json | jq '.hooks'
# Should use string matchers, not object matchers:
# Correct: {"matcher": "Bash", "hooks": [...]}
# Wrong:   {"matcher": {"tools": ["BashTool"]}, "hooks": [...]}
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
   - Detects `bd comment add` or `bd comments add` with knowledge prefixes
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

Tool names in matchers: `Bash`, `Edit`, `Write`, `Read`, `Task`, `Grep`, `Glob`
- Do NOT use "Tool" suffix
- Do NOT use object format like `{"tools": ["BashTool"]}`

### Commands (26)

Commands are in `plugins/beads-compound/commands/`:

**Beads Workflow (8):**

| Command | File | Description |
|---------|------|-------------|
| `/beads-brainstorm` | beads-brainstorm.md | Explore ideas collaboratively |
| `/beads-plan` | beads-plan.md | Research and plan with multiple agents |
| `/beads-work` | beads-work.md | Work on a single bead with full lifecycle |
| `/beads-parallel` | beads-parallel.md | Work on multiple beads in parallel via subagents |
| `/beads-review` | beads-review.md | Multi-agent code review |
| `/beads-checkpoint` | beads-checkpoint.md | Save progress and capture knowledge |
| `/beads-compound` | beads-compound.md | Document solved problems |
| `/beads-recall` | beads-recall.md | Search knowledge base mid-session |

**Planning & Triage (3):**

| Command | File | Description |
|---------|------|-------------|
| `/beads-deepen` | beads-deepen.md | Enhance plan with parallel research |
| `/beads-plan-review` | beads-plan-review.md | Multi-agent plan review |
| `/beads-triage` | beads-triage.md | Prioritize and categorize beads |

**Utility (15):**

| Command | File | Description |
|---------|------|-------------|
| `/lfg` | lfg.md | Full autonomous engineering workflow |
| `/changelog` | changelog.md | Create engaging changelogs |
| `/create-agent-skill` | create-agent-skill.md | Create or edit skills |
| `/generate-command` | generate-command.md | Create new slash commands |
| `/heal-skill` | heal-skill.md | Fix incorrect SKILL.md files |
| `/deploy-docs` | deploy-docs.md | Validate docs for deployment |
| `/release-docs` | release-docs.md | Build and update documentation |
| `/feature-video` | feature-video.md | Record video walkthrough for PR |
| `/agent-native-audit` | agent-native-audit.md | Agent-native architecture review |
| `/test-browser` | test-browser.md | Browser tests on affected pages |
| `/xcode-test` | xcode-test.md | iOS simulator testing |
| `/report-bug` | report-bug.md | Report a plugin bug |
| `/reproduce-bug` | reproduce-bug.md | Reproduce and investigate bugs |
| `/resolve-pr-parallel` | resolve-pr-parallel.md | Resolve PR comments in parallel |
| `/resolve-todo-parallel` | resolve-todo-parallel.md | Resolve TODOs in parallel |

### Agents (28)

Agents are in `plugins/beads-compound/agents/`:

**Review (14)**: agent-native-reviewer, architecture-strategist, code-simplicity-reviewer, data-integrity-guardian, data-migration-expert, deployment-verification-agent, dhh-rails-reviewer, julik-frontend-races-reviewer, kieran-python-reviewer, kieran-rails-reviewer, kieran-typescript-reviewer, pattern-recognition-specialist, performance-oracle, security-sentinel

**Research (5)**: best-practices-researcher, framework-docs-researcher, git-history-analyzer, learnings-researcher, repo-research-analyst

**Design (3)**: design-implementation-reviewer, design-iterator, figma-design-sync

**Workflow (5)**: bug-reproduction-validator, every-style-editor, lint, pr-comment-resolver, spec-flow-analyzer

**Docs (1)**: ankane-readme-writer

### Skills (15)

Skills are in `plugins/beads-compound/skills/`:

- **git-worktree**: Manage git worktrees for parallel bead work
- **brainstorming**: Structured brainstorming with bead output
- **create-agent-skills**: Create new agents and skills
- **agent-native-architecture**: Design agent-native system architectures
- **beads-knowledge**: Document solved problems as knowledge entries
- **agent-browser**: Browser automation for testing and screenshots
- **andrew-kane-gem-writer**: Write Ruby gems following Andrew Kane's style
- **dhh-rails-style**: Rails development following DHH's conventions
- **dspy-ruby**: DSPy integration for Ruby applications
- **every-style-editor**: Every's house style guide for content editing
- **file-todos**: Find and manage TODO comments in code
- **frontend-design**: Frontend design patterns and best practices
- **gemini-imagegen**: Generate images using Google's Gemini
- **rclone**: Cloud storage file management with rclone
- **skill-creator**: Create new skills from templates

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

## Key Implementation Details

### Platform-Specific Conversion Scripts

OpenCode and Gemini CLI require conversion from Claude Code format:

**Conversion process:**
- `scripts/convert-opencode.ts` - Converts to OpenCode format
- `scripts/convert-gemini.ts` - Converts to Gemini CLI format
- Run automatically during platform-specific installation
- Requires Bun runtime (`bun run convert-opencode.ts`)

**Generated file permissions:**
- Skills use `0o644` (writable) not `0o444` (read-only)
- Allows conversion script to overwrite on subsequent runs
- Prevents `EACCES` errors when re-running conversion

**Common gotchas:**
- First run creates files successfully
- Read-only permissions would cause subsequent runs to fail
- Error caught by try/catch, producing misleading "no SKILL.md found" warnings
- Solution: Use standard writable permissions for generated files

### Cross-Platform Shell Commands

**find command compatibility:**
```bash
# WRONG - fails on GNU find (Linux)
find path -depth 1 -type d

# CORRECT - works on BSD (macOS) and GNU (Linux)
find path -mindepth 1 -maxdepth 1 -type d
```

- `-depth` is a flag (no argument) for depth-first traversal on GNU find
- `-depth 1` on GNU find interprets `1` as path argument → error
- `-maxdepth 1` limits directory descent to 1 level
- `-mindepth 1` excludes parent directory from results
- Both BSD find (macOS) and GNU find (Linux) support `-mindepth`/`-maxdepth`

**Used in:**
- `installers/install-opencode.sh` (skill counting)
- `installers/install-gemini.sh` (skill counting)

### Memory Capture Detection

The `memory-capture.sh` hook detects this pattern in Bash commands:

```bash
bd comment add {BEAD_ID} "LEARNED: ..."
bd comment add {BEAD_ID} "DECISION: ..."
bd comment add {BEAD_ID} "FACT: ..."
bd comment add {BEAD_ID} "PATTERN: ..."
bd comment add {BEAD_ID} "INVESTIGATION: ..."
```

The regex matches both `bd comment add` (singular) and `bd comments add` (plural).

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

## Agent Instructions

This project uses **bd** (beads) for issue tracking.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

### Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
- NEVER add Co-Authored-By lines to commit messages
- Never use emoji in print messages unless explicitly requested
