# Release Notes: beads-compound v0.6.1

**Release Date:** February 15, 2026

This is a maintenance release focused on installation reliability, cross-platform compatibility, and fixing critical bugs in the memory system.

## Highlights

### 🔧 Fixed Critical Memory System Bug
- **Duplicate knowledge entries** causing JSONL/SQLite desynchronization are now prevented
- memory-capture.sh now validates keys before appending to knowledge.jsonl
- Ensures dual-write consistency between JSONL and SQLite FTS5 database

### 🌍 Global Installation is Now Fully Portable
- Global installations (`./install.sh` without target) are now **completely self-contained**
- All 7 hook scripts bundled to `~/.claude/hooks/` - no dependency on plugin source repo
- Works seamlessly with dotfiles via symlinks - clone on any machine and it just works
- check-memory.sh now discovers hooks from 3 locations (global, marketplace, legacy)

### 🛠️ Installation Reliability Improvements
- **OpenCode**: Fixed installer to use correct `.opencode/plugins/` directory per OpenCode docs
- **Build artifacts**: Created `opencode-src/` and `gemini-src/` source directories to prevent installer failures
- **Path portability**: Changed from hardcoded absolute paths to `~/.claude/hooks/` with tilde expansion
- **Cross-platform**: Fixed shell commands to work on both macOS (BSD) and Linux (GNU) systems

### ✅ CI/CD Reliability
- GitHub Actions now generates conversion outputs before running tests
- Updated test expectations to match actual file permissions (644)
- Template syntax tests now correctly validate conversion while allowing `$ARGUMENTS` in code blocks

## What's Fixed

| Issue | Impact | Fix |
|-------|--------|-----|
| Duplicate knowledge entries | JSONL had 64 lines, SQLite had 63 rows | Added duplicate detection before JSONL append |
| Global install requires plugin source | Breaks when cloning dotfiles to new machine | Bundle all hook scripts to ~/.claude/hooks/ |
| OpenCode installer uses wrong path | Plugin not loaded by OpenCode | Use .opencode/plugins/ per OpenCode docs |
| Installer fails on re-runs | `cp: cannot stat opencode/plugin.ts` | Created opencode-src/ and gemini-src/ source dirs |
| CI tests fail on build artifacts | Tests expected gitignored directories | Added conversion steps before tests |
| Skill files read-only on re-runs | EACCES error when re-running conversion | Changed from 0o444 to 0o644 permissions |
| Hardcoded paths break dotfiles | /Users/rbm/.claude/hooks in settings.json | Use ~/.claude/hooks/ with tilde expansion |
| find command fails on Linux | -depth 1 treated as path argument | Use -maxdepth/-mindepth for POSIX compliance |

## Installation

### Native Plugin System (Recommended)
```bash
# In Claude Code
/plugin marketplace add https://github.com/roberto-mello/beads-compound-plugin
/plugin install beads-compound
```

### Manual Install
```bash
# Global install (to ~/.claude)
git clone https://github.com/roberto-mello/beads-compound-plugin.git
cd beads-compound-plugin
./install.sh

# Project install
./install.sh /path/to/your/project
```

### Upgrading from 0.6.0

If you installed globally to `~/.claude/`:
```bash
cd /path/to/beads-compound-plugin
git pull
./install.sh  # Re-run global installer
```

Your existing `.beads/memory/` data is preserved - the upgrade only updates hook scripts and plugin files.

## Full Changelog

See [CHANGELOG.md](CHANGELOG.md#061---2026-02-15) for complete details.

## Platform Support

✅ **Claude Code** - Full support (commands, agents, skills, hooks, MCP)
✅ **OpenCode** - Memory system only (auto-recall, knowledge capture, subagent wrapup)
✅ **Gemini CLI** - Memory system only (auto-recall, knowledge capture, subagent wrapup)

## Contributors

Thanks to all users who reported issues and tested fixes during the 0.6.1 development cycle.

---

**Questions or Issues?** Open an issue at https://github.com/roberto-mello/beads-compound-plugin/issues
