---
name: beads:plan
description: Research and plan a feature using multiple agents, create beads for implementation
---

# Beads Plan

Research and plan a feature using compound-engineering's research agents, then create beads for the implementation steps.

## Usage

```
/beads:plan "Add two-factor authentication"
/beads:plan BD-005  # Plan from existing epic bead
```

## Workflow

### Step 1: Create or Validate Epic Bead

If the user provided a bead ID:
- Validate it exists: `bd show {BEAD_ID} --json`
- If it's not an epic, ask if they want to convert it

If the user provided a feature description:
- Create an epic bead:
  ```bash
  bd create "{title}" -d "{description}" --type epic
  ```

### Step 2: Search Existing Knowledge

Before researching, check if we already know things about this topic:

```bash
.beads/memory/recall.sh "{search terms from title}"
```

Present relevant knowledge to the user and ask if they want to proceed with research or if the existing knowledge is sufficient.

### Step 3: Parallel Research

Dispatch multiple research agents in parallel to gather comprehensive information:

```
Task(subagent_type="best-practices-researcher",
     prompt="BEAD_ID: {EPIC_ID}

Research best practices for: {feature description}

Log findings as:
bd comment add {EPIC_ID} \"INVESTIGATION: {findings}\"
bd comment add {EPIC_ID} \"FACT: {important constraints}\"
bd comment add {EPIC_ID} \"PATTERN: {recommended patterns}\"")

Task(subagent_type="framework-docs-researcher",
     prompt="BEAD_ID: {EPIC_ID}

Research framework documentation for: {feature description}

Log findings using appropriate prefixes (INVESTIGATION/FACT/PATTERN)")

Task(subagent_type="repo-research-analyst",
     prompt="BEAD_ID: {EPIC_ID}

Analyze our codebase for existing patterns related to: {feature description}

Log findings using appropriate prefixes")
```

### Step 4: Synthesize Findings into Detailed Plan

After all research agents complete:

1. Review all comments on the epic bead: `bd show {EPIC_ID}`
2. Synthesize findings into a coherent plan
3. Identify implementation steps with clear boundaries
4. **For each step, define:**
   - Concrete deliverables
   - Testing approach (unit tests, integration tests, manual validation)
   - Acceptance criteria (what "done" looks like)
   - Dependencies between steps
   - Any constraints or gotchas from research

### Step 5: Create Child Beads with Comprehensive Descriptions

For each implementation step identified in the plan, create a child bead with a **thorough, complete description** that includes:

1. **What needs to be done** - Clear implementation requirements
2. **Why** - Context from research (constraints, patterns, best practices)
3. **Testing criteria** - How to verify the implementation works
4. **Validation criteria** - Acceptance criteria for completion
5. **Dependencies** - What must be done first

**Description format:**

```
## What

[Clear description of what needs to be implemented]

## Context

[Relevant findings from research - constraints, patterns, decisions]

## Testing

- [ ] [Specific test case 1]
- [ ] [Specific test case 2]
- [ ] [Edge case tests]
- [ ] [Integration tests if needed]

## Validation

- [ ] [Acceptance criterion 1]
- [ ] [Acceptance criterion 2]
- [ ] [Performance/security requirements if applicable]

## Dependencies

[List any child beads that must be completed first]
```

**Create the bead:**

```bash
bd create "{step title}" -d "{comprehensive description from above}" --parent {EPIC_ID}
# Or with dependencies:
bd create "{step title}" -d "{comprehensive description}" --parent {EPIC_ID} --deps {PREVIOUS_STEP_ID}
```

**Add research context as comments:**

```bash
bd comment add {CHILD_ID} "INVESTIGATION: {key research findings specific to this step}"
bd comment add {CHILD_ID} "PATTERN: {recommended patterns for this step}"
```

### Step 6: Present Plan

Output a summary:

```
Epic: {EPIC_ID} - {title}

Research completed:
- {agent 1}: {key findings}
- {agent 2}: {key findings}
- {agent 3}: {key findings}

Implementation steps:
1. {CHILD_ID_1}: {title}
2. {CHILD_ID_2}: {title}
3. {CHILD_ID_3}: {title}

View full research: bd show {EPIC_ID}
Start work: /beads:work {CHILD_ID_1}
```

## Quality Requirements

**Each child bead description MUST include:**
- ✅ Clear implementation requirements (What)
- ✅ Context from research (Why)
- ✅ Specific testing criteria with test cases
- ✅ Concrete validation/acceptance criteria
- ✅ Dependencies clearly stated

**Don't create vague beads like:**
- ❌ "Add authentication" with no testing criteria
- ❌ "Fix the bug" with no validation approach
- ❌ "Refactor code" with no acceptance criteria

**Do create thorough beads like:**
- ✅ "Implement OAuth2 login flow" with specific test scenarios (valid tokens, expired tokens, invalid redirect URIs), validation criteria (works with Google/GitHub, handles errors gracefully), and constraints from research (OWASP guidelines, token rotation requirements)

## Notes

- All research findings are logged to the epic bead with appropriate prefixes
- Knowledge is auto-captured and will be available in future sessions
- Child beads can be worked on independently with `/beads:work`
- Use `bd ready` to see which child beads are ready to work on
- Each child bead should be reviewable and closeable based solely on its description's testing/validation criteria
