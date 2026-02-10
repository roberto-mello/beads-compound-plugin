---
name: triage
description: Triage and categorize beads for prioritization
argument-hint: [epic bead ID or list of bead IDs]
disable-model-invocation: true
---

Present all findings, decisions, or issues one by one for triage. The goal is to go through each bead and decide whether to keep, modify, dismiss, or defer it.

**IMPORTANT: DO NOT CODE ANYTHING DURING TRIAGE!**

This command is for:

- Triaging code review findings (from `/beads-review`)
- Processing security audit results
- Reviewing performance analysis
- Handling any categorized findings that need tracking

## Input

<bead_input> #$ARGUMENTS </bead_input>

**If input is an epic bead ID:**
```bash
bd list --parent {EPIC_ID} --json
```

**If input is empty:**
```bash
# Show all open beads
bd list --status=open --json
```

Read each bead's full details:
```bash
bd show {BEAD_ID}
```

## Workflow

### Step 1: Present Each Bead

For each bead, present in this format:

```
---
Bead #X: {BEAD_ID} - [Brief Title]

Severity: P1 (CRITICAL) / P2 (IMPORTANT) / P3 (NICE-TO-HAVE)

Category: [Security/Performance/Architecture/Bug/Feature/etc.]

Description:
[Detailed explanation from bead description]

Location: [file_path:line_number if applicable]

Problem Scenario:
[Step by step what's wrong or could happen]

Proposed Solution:
[How to fix it]

Estimated Effort: [Small (< 2 hours) / Medium (2-8 hours) / Large (> 8 hours)]

---
What would you like to do with this bead?
1. Keep - approve for work
2. Modify - change priority, description, or details
3. Dismiss - close/remove this bead
4. Defer - keep but lower priority
```

### Step 2: Handle User Decision

**When user says "Keep":**
1. Update bead status to ready: `bd update {BEAD_ID} --status=open`
2. Confirm: "Approved: `{BEAD_ID}` - {title} -> Ready to work on"

**When user says "Modify":**
- Ask what to modify (priority, description, details)
- Update the bead: `bd update {BEAD_ID} --priority {N} -d "{new description}"`
- Present revised version
- Ask again: Keep/Modify/Dismiss/Defer

**When user says "Dismiss":**
- Close the bead: `bd close {BEAD_ID} --reason "Dismissed during triage"`
- Log: `bd comments add {BEAD_ID} "DECISION: Dismissed during triage - {reason}"`
- Skip to next item

**When user says "Defer":**
- Lower priority: `bd update {BEAD_ID} --priority 5`
- Add tag: `bd update {BEAD_ID} --tags "deferred"`
- Log: `bd comments add {BEAD_ID} "DECISION: Deferred during triage - {reason}"`

### Step 3: Progress Tracking

Every time you present a bead, include:
- **Progress:** X/Y completed (e.g., "3/10 completed")

### Step 4: Final Summary

After all items processed:

```markdown
## Triage Complete

**Total Items:** [X]
**Kept (ready for work):** [Y]
**Modified:** [Z]
**Dismissed:** [A]
**Deferred:** [B]

### Approved Beads (Ready for Work):
- {BD-XXX}: {title} - Priority {N}
- {BD-YYY}: {title} - Priority {N}

### Dismissed Beads:
- {BD-ZZZ}: {title} - Reason: {reason}

### Deferred Beads:
- {BD-AAA}: {title} - Reason: {reason}

### Next Steps:

1. Start work on approved items:
   ```bash
   /resolve-parallel    # Work on multiple beads efficiently
   ```
2. Or pick individual items:
   ```bash
   /beads-work {BD-XXX}
   ```
```

## Post-Triage Options

When done, present these options:

```markdown
What would you like to do next?

1. Run /resolve-parallel to resolve the approved beads
2. Run /beads-work on a specific bead
3. Nothing for now
```

## Important Notes

- DO NOT implement fixes or write code during triage
- Triage is for decisions only
- Implementation happens in `/resolve-parallel` or `/beads-work`
