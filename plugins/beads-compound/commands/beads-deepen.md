---
name: beads:deepen
description: Enhance child beads with parallel research agents for depth, best practices, and implementation details
argument-hint: "[epic bead ID]"
---

# Deepen Plan - Power Enhancement Mode

## Introduction

**Note: The current year is 2026.** Use this when searching for recent documentation and best practices.

This command takes an existing epic bead (from `/beads-plan`) and enhances each child bead with parallel research agents. Each child bead gets dedicated research to find:
- Best practices and industry patterns
- Performance optimizations
- UI/UX improvements (if applicable)
- Quality enhancements and edge cases
- Real-world implementation examples

The result is deeply grounded, production-ready bead descriptions with concrete implementation details.

## Epic Bead

<epic_id> #$ARGUMENTS </epic_id>

**If the epic ID above is empty:**
1. List recent epic beads: `bd list --type epic --json | jq -r '.[] | "\(.id): \(.title)"'`
2. Ask the user: "Which epic would you like to deepen? Please provide the bead ID."

Do not proceed until you have a valid epic bead ID.

## Main Tasks

### 1. Parse and Analyze Epic Structure

<thinking>
First, read the epic bead and all its children to identify what can be enhanced with research.
</thinking>

**Read the epic and children:**
```bash
bd show {EPIC_ID} --json
bd list --parent {EPIC_ID} --json
```

**For each child bead, extract:**
- [ ] Title and description
- [ ] What section (implementation requirements)
- [ ] Context section (existing research)
- [ ] Testing/Validation criteria
- [ ] Technologies/frameworks mentioned
- [ ] Domain areas (data models, APIs, UI, security, performance, etc.)

**Create a section manifest:**
```
Child 1: {ID} - {Title} - [Areas to research]
Child 2: {ID} - {Title} - [Areas to research]
...
```

### 2. Discover and Apply Available Skills

<thinking>
Dynamically discover all available skills and match them to child bead topics.
</thinking>

**Step 1: Discover ALL available skills**

```bash
# Project-local skills
ls .claude/skills/ 2>/dev/null

# User's global skills
ls ~/.claude/skills/ 2>/dev/null
```

**Step 2: For each skill, read its SKILL.md to understand what it does**

**Step 3: Match skills to child bead content**

For each skill discovered:
- Read its SKILL.md description
- Check if any child bead topics match the skill's domain
- If there's a match, spawn a sub-agent to apply that skill's knowledge

**Step 4: Spawn a sub-agent for EVERY matched skill**

For each matched skill:
```
Task general-purpose: "You have the [skill-name] skill available at [skill-path].

YOUR JOB: Use this skill on this bead's content.

1. Read the skill: cat [skill-path]/SKILL.md
2. Follow the skill's instructions exactly
3. Apply the skill to this content:

[child bead description]

4. Return the skill's full output"
```

**Spawn ALL skill sub-agents in PARALLEL.**

### 3. Search Knowledge Base for Relevant Learnings

**Search for learnings relevant to each child bead:**

```bash
# For each child bead, search knowledge
.beads/memory/recall.sh "{keywords from child bead title}"
.beads/memory/recall.sh "{technology keywords}"
```

**For each relevant knowledge entry, check if it applies:**
- Tags overlap with child bead technologies
- Same domain area
- Similar patterns or concerns

### 4. Launch Per-Child Research Agents

<thinking>
For each child bead, spawn dedicated sub-agents to research improvements.
</thinking>

**For each child bead, launch parallel research:**

```
Task Explore: "Research best practices, patterns, and real-world examples for: [child bead topic].
Find:
- Industry standards and conventions
- Performance considerations
- Common pitfalls and how to avoid them
- Documentation and tutorials
Return concrete, actionable recommendations."
```

**Use WebSearch for current best practices:**

Search for recent (2024-2026) articles, blog posts, and documentation on topics in each child bead.

### 5. Run Review Agents Against Plan Content

Run review agents against the overall plan to catch architectural issues:

```
Task architecture-strategist: "Review this plan for architectural concerns: {epic description + child bead summaries}"
Task code-simplicity-reviewer: "Review this plan for unnecessary complexity: {epic description + child bead summaries}"
Task security-sentinel: "Review this plan for security concerns: {epic description + child bead summaries}"
Task performance-oracle: "Review this plan for performance considerations: {epic description + child bead summaries}"
```

### 6. Synthesize and Enhance

**Collect outputs from ALL sources:**

1. **Skill-based sub-agents** - Patterns, code examples, recommendations
2. **Knowledge base entries** - Relevant past learnings
3. **Research agents** - Best practices, documentation, examples
4. **Review agents** - Architecture, security, performance feedback
5. **Web searches** - Current best practices and articles

**For each agent's findings, extract:**
- [ ] Concrete recommendations (actionable items)
- [ ] Code patterns and examples
- [ ] Anti-patterns to avoid
- [ ] Performance considerations
- [ ] Security considerations
- [ ] Edge cases discovered
- [ ] Documentation links

### 7. Update Child Bead Descriptions

For each child bead, enhance the description with research findings:

```bash
bd update {CHILD_ID} -d "{enhanced description}"
```

**Enhancement format:**

```
## What

[Original content preserved]

## Context

[Original context + new research findings]

### Research Insights

**Best Practices:**
- [Concrete recommendation 1]
- [Concrete recommendation 2]

**Performance Considerations:**
- [Optimization opportunity]
- [Benchmark or metric to target]

**Edge Cases:**
- [Edge case 1 and how to handle]
- [Edge case 2 and how to handle]

## Testing

[Original tests + new test cases from research]

## Validation

[Original criteria + enhanced criteria from review agents]

## References

- [Documentation URL 1]
- [Documentation URL 2]
```

**Log research findings as knowledge:**

```bash
bd comment add {CHILD_ID} "INVESTIGATION: {key research insight}"
bd comment add {CHILD_ID} "PATTERN: {best practice discovered}"
```

### 8. Enhancement Summary

After updating all child beads, present a summary:

```
Plan deepened for epic {EPIC_ID}: {title}

Child beads enhanced: {count}
Research agents used: {list}
Skills applied: {list}
Knowledge entries found: {count}

Key improvements:
1. {Major improvement 1}
2. {Major improvement 2}
3. {Major improvement 3}

New considerations discovered:
- {Important finding 1}
- {Important finding 2}
```

## Post-Enhancement Options

After deepening, use the **AskUserQuestion tool** to present options:

**Question:** "Plan deepened for epic `{EPIC_ID}`. What would you like to do next?"

**Options:**
1. **Run `/beads-plan-review`** - Get feedback from reviewers on enhanced plan
2. **Start `/beads-work`** - Begin implementing the first child bead
3. **Deepen further** - Run another round of research on specific child beads
4. **View changes** - Show what was added to each child bead

## Quality Checks

Before finalizing:
- [ ] All original content preserved in each child bead
- [ ] Research insights clearly marked
- [ ] Code examples are syntactically correct
- [ ] No contradictions between child beads
- [ ] Enhancement summary accurately reflects changes

NEVER CODE! Just research and enhance the plan.
