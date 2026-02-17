# beads-compound v0.6.2 Release Notes

## Highlights

This release focuses on safer parallel work, better mid-session knowledge access, and a major DSPy.rb skill update.

### `/beads-recall` — Mid-Session Knowledge Lookup

A new lightweight command that lets you search the knowledge base at any point during a session — not just at startup. Auto-recall runs when a session begins, but if you switch tasks or need to check something specific, `/beads-recall` gives you instant access without a restart.

Six search modes:
- **Keywords**: `/beads-recall auth token expiry` — search by topic
- **Bead ID**: `/beads-recall BD-042` — pull knowledge tied to a specific bead
- **Recent**: `/beads-recall --recent 20` — see the 20 most recent entries
- **Stats**: `/beads-recall --stats` — knowledge base statistics
- **Topic**: `/beads-recall --topic security` — filter by tag
- **Type**: `/beads-recall --type decision` — filter by knowledge type

### File-Scope Conflict Prevention for Parallel Work

When multiple agents work in parallel, the biggest risk is two agents modifying the same file simultaneously. This release adds systematic prevention:

**`beads-plan`** now requires each child bead to declare a `## Files` section listing which files it will touch. The planner must add dependencies (`bd dep add`) when two beads share files, ensuring overlapping work runs sequentially.

**`beads-parallel`** adds a conflict detection phase before launching subagents:
1. Analyzes file scopes across all beads in the current wave
2. Detects overlaps and forces sequential ordering
3. Passes file ownership to each subagent prompt so agents know their boundaries
4. Runs a post-wave check for ownership violations
5. Carries knowledge forward between waves via inter-wave recall

This prevents the "two agents stomping each other's edits" problem that emerged when using `beads-parallel` on larger refactors.

### DSPy.rb Skill — Full v0.34.3 Rewrite

Merged from compound-engineering-plugin by @vicentereig. The DSPy.rb skill has been completely rewritten for the v0.34.3 API, which introduced significant changes to how modules, signatures, and tools are structured.

Key API changes covered:
- Module invocation: `.call()` replaces `.forward()`
- Result access: `result.field` replaces positional returns
- Type-safe enums: `T::Enum` integration
- Tool system: `Tools::Base` for structured tool definitions

New reference files added:
- **`toolsets.md`** — tool composition patterns and multi-tool agents
- **`observability.md`** — tracing, logging, and debugging LLM calls

New features documented: events system, lifecycle callbacks, fiber-local LM context, GEPA optimization, evaluation framework, BAML/TOON schema formats, storage system, score API, and RubyLLM unified adapter.

### Interactive OpenCode Model Selection

OpenCode installation now lets you choose which Claude model to use for each performance tier. Previously the tier-to-model mapping was hardcoded. Now:

- Installation prompts for model preferences (skip with `--yes` for defaults)
- Queries available models via `opencode models` to show what's installed
- Saves selections to `scripts/shared/model-config.json` for subsequent installs
- Run `./scripts/select-opencode-models.sh` to update selections at any time
- See `docs/MODEL_SELECTION.md` for full documentation

Default mappings remain: haiku → `claude-haiku-4-5-20251001`, sonnet → `claude-sonnet-4-5-20250929`, opus → `claude-opus-4-6`.

## Upgrade

```bash
# Manual install
bash ~/path/to/beads-compound-plugin/install.sh

# Or pull the latest and reinstall
git pull && ./install.sh /path/to/your-project
```

No migration steps required. The new `/beads-recall` command is available immediately after install. File-scope conflict prevention in `beads-plan`/`beads-parallel` is additive — existing beads without a `## Files` section are treated as having no declared scope.
