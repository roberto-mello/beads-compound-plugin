---
name: beads:triage
description: Triage and prioritize child beads for an epic
argument-hint: "[epic bead ID]"
---

# Beads Triage

Triage and categorize child beads for an epic. Go through each child bead one by one and decide whether to keep, modify, or dismiss it.

**IMPORTANT: DO NOT CODE ANYTHING DURING TRIAGE!**

This command is for:
- Triaging code review findings (from `/beads-review`)
- Processing research results (from `/beads-research`)
- Reviewing planned work items (from `/beads-plan`)
- Prioritizing any set of child beads

## Epic Bead

<epic_id> #$ARGUMENTS </epic_id>

**If the epic ID above is empty:**
1. List recent epic beads: `bd list --type epic --json | jq -r '.[] | "\(.id): \(.title)"'`
2. Ask the user which epic to triage

## Workflow

### Step 1: Load Child Beads

```bash
bd list --parent {EPIC_ID} --status open --json
```

Sort by priority (highest first), then by creation date.

### Step 2: Present Each Bead for Triage

For each child bead, present in this format using **AskUserQuestion tool**:

```
---
Progress: X/Y completed

Bead {BEAD_ID}: {title}

Priority: {current priority level}
Type: {bug/task/feature/improvement}
Tags: {tags}

Description:
{bead description summary - first 200 chars}

Dependencies: {list any blocking beads}
---
```

**Options:**
1. **Keep** - Approve as-is, set priority
2. **Modify** - Change priority, description, or tags
3. **Dismiss** - Close as wontfix
4. **Defer** - Keep open but lower priority

### Step 3: Handle User Decision

**When user says "Keep":**
- Confirm current priority or ask for new priority (1-5)
- Update bead if priority changed: `bd update {BEAD_ID} --priority {N}`
- Log: "Approved: {BEAD_ID} - Priority {N}"

**When user says "Modify":**
- Ask what to change (priority, description, tags)
- Update the bead: `bd update {BEAD_ID} --priority {N} --tags "{tags}"`
- Present revised version
- Ask again: keep/modify/dismiss/defer

**When user says "Dismiss":**
- Close the bead: `bd close {BEAD_ID} --resolution wontfix`
- Log reason if provided
- Move to next item

**When user says "Defer":**
- Lower priority: `bd update {BEAD_ID} --priority 5`
- Add comment: `bd comment add {BEAD_ID} "DECISION: Deferred during triage - {reason}"`
- Move to next item

### Step 4: Continue Until All Processed

- Process all items one by one
- Track progress (X/Y completed)
- Don't wait between items - keep moving

### Step 5: Final Summary

After all items processed:

```
## Triage Complete

**Epic:** {EPIC_ID} - {title}
**Total Items:** {X}
**Kept (approved):** {Y}
**Modified:** {Z}
**Dismissed:** {W}
**Deferred:** {V}

### Approved Beads (Ready for Work):
- {BD-XXX}: {title} (Priority {N})
- {BD-XXX}: {title} (Priority {N})

### Dismissed:
- {BD-XXX}: {title} - {reason}

### Deferred:
- {BD-XXX}: {title} - {reason}

### Next Steps:
1. Start work: /beads-work {first_ready_bead}
2. Resolve in parallel: /beads-resolve-parallel {EPIC_ID}
3. View ready beads: bd ready
```

## Important

- DO NOT code anything during triage
- Focus on prioritization and categorization
- Keep the pace - don't overthink individual items
- Dismiss items that aren't worth the effort
- Apply YAGNI - when in doubt, defer or dismiss
