---
name: beads:resolve-parallel
description: Resolve multiple beads in parallel using specialized agents
argument-hint: "[epic bead ID or space-separated bead IDs]"
---

# Resolve Beads in Parallel

Resolve multiple beads simultaneously using parallel subagents.

## Input

<input> #$ARGUMENTS </input>

## Workflow

### 1. Analyze

Get all unresolved beads to work on:

**If an epic bead ID was provided:**
```bash
bd list --parent {EPIC_ID} --status open --json
```

**If specific bead IDs were provided:**
```bash
bd show {BEAD_ID_1} --json
bd show {BEAD_ID_2} --json
# etc.
```

**If nothing provided:**
```bash
bd ready --json
```

Skip any beads that would require deleting or modifying files in `.beads/memory/` - these are protected pipeline artifacts.

### 2. Plan

Analyze dependencies between beads and create an execution plan:

- Check for dependency chains: `bd dep list {BEAD_ID} --json`
- Group independent beads for parallel execution
- Identify beads that must run sequentially (due to dependencies)

Output a summary showing the execution order:

```
Parallel Group 1 (no dependencies):
  - {BD-XXX}: {title}
  - {BD-XXX}: {title}

Sequential (depends on Group 1):
  - {BD-XXX}: {title} (blocked by {BD-YYY})

Parallel Group 2 (after sequential):
  - {BD-XXX}: {title}
```

### 3. Implement (PARALLEL)

Spawn a pr-comment-resolver agent for each bead in the first parallel group:

```
Task pr-comment-resolver("Resolve this bead:

Bead ID: {BEAD_ID}
Title: {title}
Description: {full description}

Read the bead description carefully. It contains:
- What needs to be done
- Context and constraints
- Testing criteria
- Validation criteria

Implement the fix/feature, run tests, and verify it meets the validation criteria.

When done, log what you learned:
bd comment add {BEAD_ID} \"LEARNED: {key insight}\"")
```

Always run all in parallel subagents/Tasks for each bead in the group.

After Group 1 completes, move to sequential beads, then Group 2, etc.

### 4. Verify & Close

After each agent completes:

- Verify tests pass
- Check that validation criteria from bead description are met
- Close the bead: `bd close {BEAD_ID}`
- Log knowledge: `bd comment add {BEAD_ID} "LEARNED: {what was done}"`

### 5. Summary

```
Parallel resolution complete!

Resolved: {count} beads
  - {BD-XXX}: {title} - closed
  - {BD-XXX}: {title} - closed

Still open: {count} beads
  - {BD-XXX}: {title} - {reason}

Knowledge captured: {count} entries

Next steps:
- Review changes: /beads-review {EPIC_ID}
- Commit: /beads-checkpoint
```
