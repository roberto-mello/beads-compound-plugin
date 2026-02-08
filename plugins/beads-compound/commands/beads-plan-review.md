---
name: beads:plan-review
description: Have multiple specialized agents review an epic plan in parallel
argument-hint: "[epic bead ID]"
---

# Plan Review

Have multiple specialized agents review an epic bead plan in parallel and provide consolidated feedback.

## Epic Bead

<epic_id> #$ARGUMENTS </epic_id>

**If the epic ID above is empty:**
1. List recent epic beads: `bd list --type epic --json | jq -r '.[] | "\(.id): \(.title)"'`
2. Ask the user which epic to review

## Workflow

### 1. Read Plan Content

```bash
# Get epic details
bd show {EPIC_ID} --json

# Get all child beads
bd list --parent {EPIC_ID} --json
```

Assemble the full plan content from the epic description and all child bead descriptions.

### 2. Dispatch Review Agents in Parallel

Fire review agents against the plan content:

```
Task architecture-strategist: "Review this plan for architectural concerns:

Epic: {EPIC_ID} - {title}
Description: {epic description}

Child beads:
{child bead titles and descriptions}

Focus on: component boundaries, coupling, scalability, maintainability"

Task code-simplicity-reviewer: "Review this plan for unnecessary complexity:

Epic: {EPIC_ID} - {title}
{full plan content}

Focus on: over-engineering, premature abstractions, simpler alternatives"

Task security-sentinel: "Review this plan for security concerns:

Epic: {EPIC_ID} - {title}
{full plan content}

Focus on: attack surfaces, data protection, authentication, authorization"

Task performance-oracle: "Review this plan for performance considerations:

Epic: {EPIC_ID} - {title}
{full plan content}

Focus on: bottlenecks, scaling concerns, resource usage, caching opportunities"
```

### 3. Synthesize Feedback

After all agents complete:

1. Collect all feedback
2. Categorize: architecture, simplicity, security, performance
3. Prioritize by impact
4. Remove duplicates

### 4. Present Consolidated Review

```
## Plan Review: {EPIC_ID} - {title}

### Architecture
- {feedback point 1}
- {feedback point 2}

### Simplicity
- {feedback point 1}

### Security
- {feedback point 1}

### Performance
- {feedback point 1}

### Recommended Changes
1. {highest priority change}
2. {second priority change}
3. {third priority change}
```

### 5. Offer Next Steps

Use **AskUserQuestion tool**:

**Question:** "Plan review complete. What would you like to do?"

**Options:**
1. **Apply feedback** - Update child bead descriptions based on review
2. **Deepen plan** - Run `/beads-deepen` for more research
3. **Start work** - Proceed to `/beads-work` as-is
4. **Dismiss findings** - Proceed without changes
