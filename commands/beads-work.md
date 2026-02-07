---
name: beads:work
description: Work on a bead with agent assistance for investigation and context
---

# Beads Work

Start working on a bead with automatic knowledge recall and optional agent assistance.

## Usage

```
/beads:work BD-007
/beads:work  # Uses next ready bead from bd ready
```

## Workflow

### Step 1: Identify Bead

If the user provided a bead ID:
- Use that bead

If not provided:
- Find the next ready bead: `bd ready --json | jq -r '.[0].id'`
- If no ready beads, list open beads and ask which to work on

### Step 2: Recall Relevant Knowledge

Search for knowledge related to this bead:

```bash
# Extract keywords from bead title and description
BEAD_INFO=$(bd show {BEAD_ID} --json)
TITLE=$(echo "$BEAD_INFO" | jq -r '.[0].title')
DESCRIPTION=$(echo "$BEAD_INFO" | jq -r '.[0].description')

# Search memory
.beads/memory/recall.sh "{keywords from title}"
```

Present any relevant LEARNED/DECISION/FACT/PATTERN entries to provide context.

### Step 3: Check Dependencies

```bash
bd dep list {BEAD_ID} --json
```

If there are unresolved blockers, list them and ask if the user wants to work on those first.

### Step 4: Update Status

```bash
bd update {BEAD_ID} --status in_progress
```

### Step 5: Offer Investigation Assistance

Ask the user if they need help investigating:

```
Ready to work on: {BEAD_ID} - {title}

Relevant knowledge recalled:
{knowledge entries}

Would you like me to:
1. Just start working (you investigate)
2. Investigate first using research agents
3. Check git history for related changes
```

If user chooses investigation:

```
Task(subagent_type="repo-research-analyst",
     prompt="BEAD_ID: {BEAD_ID}

Investigate: {bead title and description}

Search codebase for:
- Related files and patterns
- Previous similar changes
- Existing implementations

Log findings as:
bd comment add {BEAD_ID} \"INVESTIGATION: {findings}\"")
```

### Step 6: Ready to Work

After investigation (if requested) or if skipping investigation:

```
Investigation complete. Findings logged to {BEAD_ID}.

Ready to implement. When done:
- Log learnings: bd comment add {BEAD_ID} "LEARNED: ..."
- Review changes: /beads:review {BEAD_ID}
- Close when complete: bd close {BEAD_ID}

Starting work on {BEAD_ID}...
```

### Step 7: Suggest Parallel Work

After starting work on the bead, check for other unblocked tasks and suggest working on them in parallel:

```bash
# Get all ready (unblocked) beads
READY_BEADS=$(bd ready --json | jq -r '.[] | select(.id != "{BEAD_ID}") | "\(.id) - \(.title)"')

# If there are additional ready beads, suggest parallel work
if [ -n "$READY_BEADS" ]; then
  cat << EOF

Other unblocked tasks ready for parallel work:
$READY_BEADS

Start working on all unblocked tasks in parallel?
  /beads-work $(bd ready --json | jq -r '.[].id' | tr '\n' ' ')

(Press <tab> then <enter> to begin parallel work)
EOF
fi
```

This allows the user to easily kick off work on all ready beads simultaneously by accepting the pre-filled command.

## Notes

- Knowledge is automatically recalled before starting
- Investigation findings are logged to the bead
- Status is updated to in_progress automatically
- Use `/beads:review` before closing to catch issues
