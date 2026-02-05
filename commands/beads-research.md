---
name: beads:research
description: Deep research using specialized agents, results logged to bead
---

# Beads Research

Conduct deep research on a topic using multiple specialized agents, with all findings logged to a bead.

## Usage

```
/beads:research BD-007 "How does Rails handle concurrent database updates?"
/beads:research "Best practices for JWT refresh token rotation"
```

## Workflow

### Step 1: Create or Identify Bead

If the user provided a bead ID:
- Use that bead for logging research

If the user provided a research question:
- Create a research bead:
  ```bash
  bd create "Research: {question}" -d "{question}" --type chore --labels research
  ```

### Step 2: Check Existing Knowledge

Before dispatching agents, search existing knowledge:

```bash
.beads/memory/recall.sh "{keywords from question}"
```

Present relevant entries. If existing knowledge answers the question, ask if they still want deep research.

### Step 3: Parallel Research Dispatch

Dispatch all relevant research agents in parallel:

```
Task(subagent_type="best-practices-researcher",
     prompt="BEAD_ID: {BEAD_ID}

Research best practices for: {question}

Search for:
- Industry standards
- Common pitfalls
- Recommended approaches
- Real-world examples

Log findings as:
bd comment add {BEAD_ID} \"FACT: {important facts}\"
bd comment add {BEAD_ID} \"PATTERN: {recommended patterns}\"
bd comment add {BEAD_ID} \"DECISION: {when to use what approach}\"")

Task(subagent_type="framework-docs-researcher",
     prompt="BEAD_ID: {BEAD_ID}

Research framework documentation for: {question}

Search official docs for:
- API documentation
- Configuration options
- Examples and guides
- Version-specific notes

Log findings using appropriate prefixes")

Task(subagent_type="git-history-analyzer",
     prompt="BEAD_ID: {BEAD_ID}

Analyze git history related to: {question}

Search for:
- Previous implementations
- Bug fixes and their solutions
- Evolution of related code
- Commit messages with rationale

Log findings using appropriate prefixes")

Task(subagent_type="repo-research-analyst",
     prompt="BEAD_ID: {BEAD_ID}

Analyze our codebase for: {question}

Search for:
- Existing patterns and conventions
- Similar implementations
- Relevant utilities and helpers
- Test examples

Log findings using appropriate prefixes")
```

### Step 4: Synthesize Research

After all agents complete:

1. Collect all comments: `bd show {BEAD_ID}`
2. Organize by type:
   - Facts (constraints, requirements, limitations)
   - Patterns (recommended approaches)
   - Decisions (when to use what)
   - Investigations (how things currently work)

### Step 5: Create Summary

Add a synthesis comment to the bead:

```bash
bd comment add {BEAD_ID} "INVESTIGATION: Research synthesis:

Key findings:
- {finding 1}
- {finding 2}
- {finding 3}

Recommendations:
- {recommendation 1}
- {recommendation 2}

See full research in comments above."
```

### Step 6: Present Results

Output:

```
Research completed: {BEAD_ID} - {question}

Key Facts:
{fact entries}

Recommended Patterns:
{pattern entries}

Decisions to Make:
{decision entries}

Full research: bd show {BEAD_ID}

This knowledge has been captured and will be recalled automatically when relevant.

Next steps:
- Implement based on findings: /beads:work {BEAD_ID}
- Create implementation beads: /beads:plan based on research
```

## Notes

- All research findings are auto-captured as knowledge
- Use this when you need comprehensive understanding before implementing
- Research beads can be referenced by implementation beads
- Knowledge will be recalled automatically in future related sessions
