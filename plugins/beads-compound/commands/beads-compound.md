---
name: beads-compound
description: Document a recently solved problem to compound your team's knowledge
argument-hint: "[optional: brief context about the fix or bead ID]"
---

# /beads-compound

Coordinate multiple subagents working in parallel to document a recently solved problem.

## Purpose

Captures problem solutions while context is fresh, creating structured knowledge entries in `.beads/memory/knowledge.jsonl` for searchability and future reference. Uses parallel subagents for maximum efficiency.

**Why "compound"?** Each documented solution compounds your team's knowledge. The first time you solve a problem takes research. Document it, and the next occurrence takes minutes. Knowledge compounds.

## Usage

```bash
/beads-compound                    # Document the most recent fix
/beads-compound BD-007             # Document solution for specific bead
/beads-compound [brief context]    # Provide additional context hint
```

## Execution Strategy: Parallel Subagents

This command launches multiple specialized subagents IN PARALLEL to maximize efficiency:

### 1. **Context Analyzer** (Parallel)
   - Extracts conversation history
   - Identifies problem type, component, symptoms
   - If a bead ID is provided, reads bead details: `bd show {BEAD_ID}`
   - Returns: knowledge entry skeleton (type, tags, content outline)

### 2. **Solution Extractor** (Parallel)
   - Analyzes all investigation steps
   - Identifies root cause
   - Extracts working solution with code examples
   - Returns: Solution content block

### 3. **Related Knowledge Finder** (Parallel)
   - Searches `.beads/memory/knowledge.jsonl` for related entries
   - Identifies cross-references and links
   - Finds related beads
   - Returns: Links and relationships

### 4. **Prevention Strategist** (Parallel)
   - Develops prevention strategies
   - Creates best practices guidance
   - Generates test cases if applicable
   - Returns: Prevention/testing content

### 5. **Category Classifier** (Parallel)
   - Determines optimal knowledge type (learned/decision/fact/pattern/investigation)
   - Suggests tags based on content
   - Returns: Type and tag recommendations

### 6. **Knowledge Writer** (Parallel)
   - Assembles complete knowledge entries
   - Validates JSONL format
   - Writes entries using `bd comment add` for auto-capture
   - Creates the entries

### 7. **Optional: Specialized Agent Invocation** (Post-Documentation)
   Based on problem type detected, automatically invoke applicable agents:
   - **performance_issue** -> `performance-oracle`
   - **security_issue** -> `security-sentinel`
   - **database_issue** -> `data-integrity-guardian`
   - Any code-heavy issue -> `code-simplicity-reviewer`

## What It Captures

- **Problem symptom**: Exact error messages, observable behavior
- **Investigation steps tried**: What didn't work and why
- **Root cause analysis**: Technical explanation
- **Working solution**: Step-by-step fix with code examples
- **Prevention strategies**: How to avoid in future
- **Cross-references**: Links to related beads and knowledge

## Knowledge Entry Format

All knowledge is logged via `bd comment add` which triggers the memory-capture hook:

```bash
# Root cause analysis
bd comment add {BEAD_ID} "INVESTIGATION: {root cause explanation with technical details}"

# Key learnings
bd comment add {BEAD_ID} "LEARNED: {what worked, including code patterns}"

# Important facts/constraints
bd comment add {BEAD_ID} "FACT: {constraint, gotcha, or important detail}"

# Patterns to follow
bd comment add {BEAD_ID} "PATTERN: {coding pattern or convention that solved the problem}"

# Decisions made
bd comment add {BEAD_ID} "DECISION: {what was chosen and why, with alternatives considered}"
```

Each entry is auto-tagged based on content keywords and stored in `knowledge.jsonl`.

## Preconditions

- Problem has been solved (not in-progress)
- Solution has been verified working
- Non-trivial problem (not simple typo or obvious error)

## Success Output

```
Knowledge documentation complete!

Primary Subagent Results:
  - Context Analyzer: Identified {problem_type} in {component}
  - Solution Extractor: Extracted {N} code fixes
  - Related Knowledge Finder: Found {N} related entries
  - Prevention Strategist: Generated test cases
  - Category Classifier: Type: {type}, Tags: [{tags}]
  - Knowledge Writer: Created {N} knowledge entries

Specialized Agent Reviews (Auto-Triggered):
  - {agent}: {finding}

Knowledge entries created:
  - LEARNED: {summary 1}
  - PATTERN: {summary 2}
  - INVESTIGATION: {summary 3}

Linked to bead: {BEAD_ID}

This knowledge will be searchable for future reference when similar
issues occur.

What's next?
1. Continue workflow (recommended)
2. View knowledge entries: .beads/memory/recall.sh "{keyword}"
3. Other
```

## The Compounding Philosophy

This creates a compounding knowledge system:

1. First time you solve "N+1 query in brief generation" -> Research (30 min)
2. Document the solution -> knowledge.jsonl entries (5 min)
3. Next time similar issue occurs -> Auto-recalled (instant)
4. Knowledge compounds -> Team gets smarter

**Each unit of engineering work should make subsequent units of work easier - not harder.**

## Related Commands

- `/beads-plan` - Planning workflow (references documented knowledge)
- `/beads-checkpoint` - Quick knowledge capture during work
- `/deepen-plan` - Enhance plans with parallel research
