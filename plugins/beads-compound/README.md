# beads-compound

A Claude Code plugin that combines beads-based persistent memory with compound-engineering's multi-agent workflows.

## Overview

- **27 specialized agents** for code review, research, design, and workflow automation
- **11 workflow commands** for brainstorming, planning, research, review, and more
- **5 skills** for worktrees, brainstorming, agent creation, and documentation
- **Automatic knowledge capture** from `bd comment add` with knowledge prefixes
- **Automatic knowledge recall** at session start based on current beads
- **Context7 MCP server** for framework documentation

## Installation

This plugin is installed via the marketplace root installer:

```bash
cd /path/to/beads-compound-plugin
./install.sh /path/to/your-project
```

See the [marketplace README](../../README.md) for full details.

## Commands

| Command | Description |
|---------|-------------|
| `/beads-brainstorm` | Explore ideas collaboratively before planning |
| `/beads-plan` | Research and plan using multiple agents |
| `/beads-deepen` | Enhance plan with parallel research agents |
| `/beads-plan-review` | Multi-agent review of epic plan |
| `/beads-triage` | Prioritize and categorize child beads |
| `/beads-work` | Work on a bead with context and auto-recall |
| `/beads-review` | Multi-agent code review before closing |
| `/beads-research` | Deep research using 5 specialized agents |
| `/beads-checkpoint` | Save progress, capture knowledge, commit |
| `/beads-compound` | Document solved problems as knowledge |
| `/beads-resolve-parallel` | Resolve multiple beads in parallel |

## Agents

### Review (14)
- `agent-native-reviewer` -- Review for agent-native architecture patterns
- `architecture-strategist` -- Architectural concerns and design patterns
- `code-simplicity-reviewer` -- Unnecessary complexity and over-engineering
- `data-integrity-guardian` -- Data consistency and integrity
- `data-migration-expert` -- Database migration review
- `deployment-verification-agent` -- Deployment readiness
- `dhh-rails-reviewer` -- Rails conventions (DHH style)
- `julik-frontend-races-reviewer` -- Frontend race conditions
- `kieran-python-reviewer` -- Python best practices
- `kieran-rails-reviewer` -- Rails best practices
- `kieran-typescript-reviewer` -- TypeScript best practices
- `pattern-recognition-specialist` -- Code patterns and anti-patterns
- `performance-oracle` -- Performance considerations
- `security-sentinel` -- Security vulnerabilities

### Research (5)
- `best-practices-researcher` -- Industry best practices
- `framework-docs-researcher` -- Framework documentation
- `git-history-analyzer` -- Git history patterns
- `learnings-researcher` -- Knowledge base search (knowledge.jsonl)
- `repo-research-analyst` -- Repository structure and patterns

### Design (3)
- `design-implementation-reviewer` -- Design-to-code accuracy
- `design-iterator` -- Design refinement
- `figma-design-sync` -- Figma design synchronization

### Workflow (4)
- `bug-reproduction-validator` -- Bug reproduction verification
- `lint` -- Linting and formatting
- `pr-comment-resolver` -- PR comment resolution
- `spec-flow-analyzer` -- SpecFlow analysis

### Docs (1)
- `ankane-readme-writer` -- README generation (ankane style)

## Skills

| Skill | Description |
|-------|-------------|
| `git-worktree` | Manage git worktrees for parallel bead work |
| `brainstorming` | Structured brainstorming with bead output |
| `create-agent-skills` | Create new agents and skills |
| `agent-native-architecture` | Design agent-native system architectures |
| `beads-knowledge` | Document solved problems as knowledge entries |

## Memory System

Knowledge prefixes recognized by the memory capture hook:

- `LEARNED:` -- Something you learned while working
- `DECISION:` -- A decision and its rationale
- `FACT:` -- An objective fact about the codebase
- `PATTERN:` -- A reusable pattern discovered
- `INVESTIGATION:` -- Research findings

Usage:
```bash
bd comment add BD-001 "LEARNED: OAuth redirect URI must match exactly"
```

Knowledge is stored in `.beads/memory/knowledge.jsonl` and automatically recalled at the start of each session.

## License

MIT
