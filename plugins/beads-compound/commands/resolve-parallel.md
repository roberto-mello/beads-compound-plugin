---
name: resolve-parallel
description: Resolve multiple beads using parallel processing
argument-hint: "[epic bead ID or list of bead IDs]"
---

Resolve multiple beads using parallel processing.

## Input

<bead_input> #$ARGUMENTS </bead_input>

**If input is an epic bead ID:**
```bash
bd list --parent {EPIC_ID} --status=open --json
```

**If input is empty:**
```bash
# Get all open beads ready for work
bd list --status=open --json
```

## Workflow

### 1. Analyze

Gather all beads to resolve:

```bash
# For each bead, read full details
bd show {BEAD_ID}
```

If any bead recommends deleting, removing, or gitignoring files in `.beads/memory/`, skip it and mark it as `wont_fix`. These are beads-compound pipeline artifacts that are intentional and permanent.

```bash
bd close {BEAD_ID} --reason "wont_fix: .beads/memory/ files are pipeline artifacts"
```

### 2. Plan

Create a task list (using TaskCreate) of all unresolved items grouped by type. Make sure to look at dependencies that might occur and prioritize the ones needed by others. For example, if you need to change a name, you must wait to do the others.

Output a mermaid flow diagram showing how we can do this:
- Can we do everything in parallel?
- Do we need to do one first that leads to others in parallel?
- Put the beads in the mermaid diagram flow-wise so the agent knows how to proceed in order.

Check for bead dependencies:
```bash
bd show {BEAD_ID} --json | jq '.dependencies'
```

### 3. Implement (PARALLEL)

Spawn a pr-comment-resolver agent for each bead in parallel.

So if there are 3 beads, it will spawn 3 pr-comment-resolver agents in parallel. Like this:

1. Task pr-comment-resolver("Resolve bead {BD-001}: {title}. Description: {description}. BEAD_ID: {BD-001}")
2. Task pr-comment-resolver("Resolve bead {BD-002}: {title}. Description: {description}. BEAD_ID: {BD-002}")
3. Task pr-comment-resolver("Resolve bead {BD-003}: {title}. Description: {description}. BEAD_ID: {BD-003}")

Always run all in parallel subagents/Tasks for each bead.

**Include BEAD_ID in each agent prompt** so the subagent-wrapup hook can capture knowledge.

### 4. Verify and Close

After agents complete:

For each resolved bead:
```bash
# Verify the fix
# (agent should have logged knowledge via bd comment add)

# Close the bead
bd close {BEAD_ID}
```

### 5. Commit & Push

- Commit all changes
- Push to remote

### 6. Summary

```markdown
## Parallel Resolution Complete

**Beads resolved:** [count]
**Beads skipped:** [count]

### Resolved:
- {BD-XXX}: {title} - Closed
- {BD-YYY}: {title} - Closed

### Skipped:
- {BD-ZZZ}: {title} - Reason: {reason}

### Knowledge captured:
- [count] LEARNED entries
- [count] PATTERN entries
- [count] other entries
```
