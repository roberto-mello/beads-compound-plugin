# Changelog

All notable changes to the beads-compound plugin are documented here.

## [0.6.0] - 2026-02-13

### Added
- **OpenCode support** via native TypeScript plugin (`plugins/beads-compound/opencode/plugin.ts`)
  - Auto-recall: inject relevant knowledge at session start
  - Memory capture: extract knowledge from `bd comments add`
  - Subagent wrapup: warn when subagents complete without logging knowledge
  - Uses Bun.spawn() for security (prevents shell injection)
  - Pre-fork filtering for performance (avoids subprocess overhead on non-matching bash commands)
- **Gemini CLI support** via extension manifest (`gemini-extension.json`)
  - SessionStart → auto-recall.sh
  - AfterTool (bash) → memory-capture.sh
  - AfterAgent → subagent-wrapup.sh
  - Uses same stdin/stdout JSON protocol as Claude Code
  - Install: `gemini extensions install https://github.com/roberto-mello/beads-compound-plugin`
- **AGENTS.md references** in 10 files (6 commands, 4 agents) where it aids user discovery
  - AGENTS.md is the emerging cross-tool standard (OpenCode, etc.)
  - Recommended: symlink CLAUDE.md → AGENTS.md for dual-tool projects

### Changed
- README Multi-Platform Support section with OpenCode, Gemini CLI, and Codex CLI status
- CLAUDE.md updated with multi-platform support summary and repository structure

## [0.5.0] - 2026-02-10

### Added
- Native plugin system support (`/plugin marketplace add` + `/plugin install`)
- Memory auto-bootstrap in SessionStart hook -- `.beads/memory/` is created automatically on first session in any beads-enabled project, no manual install.sh needed
- `provision-memory.sh` shared library for memory directory setup, used by auto-recall.sh, check-memory.sh, and install.sh

### Fixed
- plugin.json `repository` field changed from object to string per plugin manifest schema
- plugin.json removed unsupported `requirements` field
- marketplace.json `owner.url` changed to `owner.email` per marketplace schema
- SQL injection in `kb_search()` via unvalidated `TOP_N` LIMIT parameter
- Numeric validation for `--recent` parameter in recall.sh
- `git add` in bootstrap now stages specific files instead of entire `.beads/memory/` directory
- `.gitattributes` placement standardized to per-directory (inside `.beads/memory/`) across all installation paths

### Changed
- README Quick Install now presents native plugin system as Option A (recommended) and manual install.sh as Option B
- CLAUDE.md Plugin Installation section split into Native and Manual subsections
- Memory provisioning logic deduplicated from 3 files into single shared function

## [0.4.2] - 2026-02-10

### Added
- `/beads-parallel` command for working on multiple beads in parallel via subagents
- Memory recall hook (`recall.sh`) deployed to `.beads/memory/` during install

### Changed
- Renamed `/resolve-parallel` to `/beads-parallel` for naming consistency
- Updated install.sh and uninstall.sh to handle beads-parallel

## [0.4.1] - 2026-02-09

### Added
- SQLite FTS5 full-text search with BM25 ranking for knowledge recall
- `knowledge-db.sh` shared library for FTS5 operations (create, insert, search, sync)
- Dual-write to both SQLite and JSONL on every knowledge capture
- FTS5-first search in auto-recall.sh with grep fallback
- FTS5 search in recall.sh with grep fallback
- Recall benchmark harness for evaluating grep vs FTS5 search quality
- Git-trackable knowledge: `knowledge.jsonl` committed to git for team sharing
- `.gitattributes` union merge strategy for conflict-free multi-user collaboration
- `check-memory.sh` SessionStart hook for auto-detecting beads projects missing memory setup
- Global install warning when per-project memory hooks are not configured
- Automatic one-time backfill from existing JSONL and beads.db comments on first FTS5 run

### Fixed
- install.sh failing when skill directory already exists
- Only overwrite skills managed by this plugin on reinstall (preserve user customizations)
- Updated `bd comment add` to `bd comments add` to match current beads CLI syntax

### Changed
- Auto-recall search now uses FTS5 with porter stemming and BM25 ranking, falling back to grep
- Installation steps clarified: global first, then per-project
- Knowledge rotation threshold increased from 1000/500 to 5000/2500

## [0.4.0] - 2026-02-08

### Added
- Global installation support (`./install.sh` without target path installs to `~/.claude/`)
- `disable-model-invocation: true` on 17 utility commands and 7 manual skills to reduce context token usage by 94%
- Critical requirement preventing subagent file writes in auto-denied mode

### Changed
- Context budget reduced from ~130K chars to ~8,200 chars (94% reduction) by trimming agent descriptions and disabling auto-invocation on utility components
- Removed OpenCode workaround (upstream PR #160 merged)

## [0.3.0] - 2026-02-08

Initial public release. Fork of [compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) with beads-based persistent memory.

### Added
- 27 specialized agents (14 review, 5 research, 3 design, 4 workflow, 1 docs) with model tier assignments (Haiku/Sonnet/Opus)
- 11 workflow commands for brainstorming, planning, review, and testing
- 5 skills (git-worktree, brainstorming, create-agent-skills, agent-browser, frontend-design)
- 3 hooks: auto-recall (SessionStart), memory-capture (PostToolUse), subagent-wrapup (SubagentStop)
- Context7 MCP server for framework documentation
- Automatic knowledge capture from `bd comments add` with typed prefixes (LEARNED/DECISION/FACT/PATTERN/INVESTIGATION)
- Automatic knowledge recall at session start based on open beads and git branch context
- Marketplace structure with install.sh/uninstall.sh
- OpenCode/Codex installation via `@every-env/compound-plugin` converter
- Agent description optimization reducing startup token cost by 80%

### Changed from compound-engineering
- Replaced markdown-based knowledge storage with beads-based persistent memory
- All workflows create and update beads instead of markdown files
- Rewrote `learnings-researcher` to search `knowledge.jsonl` instead of markdown docs
- Adapted `code-simplicity-reviewer` to protect `.beads/memory/` files
- Renamed `compound-docs` skill to `beads-knowledge`

[0.5.0]: https://github.com/roberto-mello/beads-compound-plugin/compare/v0.4.2...v0.5.0
[0.4.2]: https://github.com/roberto-mello/beads-compound-plugin/compare/v0.4.0...v0.4.2
[0.4.1]: https://github.com/roberto-mello/beads-compound-plugin/compare/v0.4.0...v0.4.2
[0.4.0]: https://github.com/roberto-mello/beads-compound-plugin/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/roberto-mello/beads-compound-plugin/releases/tag/v0.3.0
