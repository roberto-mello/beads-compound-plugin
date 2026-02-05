---
name: beads:review
description: Multi-agent code review before closing a bead
---

# Beads Review

Run comprehensive multi-agent code review on changes for a bead.

## Usage

```
/beads:review BD-007
/beads:review  # Uses current in-progress bead
```

## Workflow

### Step 1: Identify Bead

If the user provided a bead ID:
- Use that bead

If not provided:
- Find the current in-progress bead: `bd list --status in_progress --json | jq -r '.[0].id'`
- If multiple are in progress, ask which one to review

### Step 2: Get Changed Files

Determine which files were changed for this bead:

```bash
# Get the branch for this bead (if it exists)
BRANCH="bd-{BEAD_ID}"

if git rev-parse --verify "$BRANCH" 2>/dev/null; then
  # Compare branch to main
  git diff main..."$BRANCH" --name-only
else
  # Use recent commits (heuristic)
  git diff HEAD~3...HEAD --name-only
fi
```

### Step 3: Recall Relevant Knowledge

Search for knowledge related to this bead. Extract key domain terms from the bead title and description:

```bash
# Extract 2-4 key technical terms from the bead
# Example: For "Fix phone number logging in auth flow"
# Use: "phone logging authentication" NOT the full sentence

.beads/memory/recall.sh "{2-4 key terms}"

# Also search by technology if relevant
.beads/memory/recall.sh "{tech-stack-keyword}"  # e.g., "rails", "postgres", "react"

# Show recent learnings for context
.beads/memory/recall.sh --recent 10
```

Present any relevant knowledge (LEARNED/DECISION/FACT/PATTERN) that reviewers should consider.

### Step 4: Dispatch Review Agents in Parallel

Based on the files changed and languages involved, dispatch appropriate reviewers. Each reviewer should create beads for any issues found.

```
# Language-specific reviewers
Task(subagent_type="kieran-rails-reviewer",
     prompt="BEAD_ID: {BEAD_ID}

Review Rails code changes for: {bead title}

Files changed:
{file list}

For each issue you find, create a bead with:

bd create \"Fix: {brief issue title}\" \\
  -d \"## Issue
{Detailed description of the problem}

## Severity
{Critical/High/Medium/Low} - {Why this severity level}

## Location
{Specific file:line references}

## Why This Matters
{Impact and consequences}

## Validation Criteria
- [ ] {Specific test that must pass}
- [ ] {Behavior to verify}
- [ ] {Edge cases to check}

## Testing Steps
1. {How to reproduce/test}
2. {Expected outcome}\" \\
  --type {bug|task|improvement} \\
  --priority {1-5} \\
  --tags \"review,rails,{BEAD_ID}\"

Use types:
- bug: Logic errors, security issues, data corruption risks
- task: Required refactors, missing error handling, debt
- improvement: Performance, code quality, maintainability

Use priority levels:
- 1 (Critical): Blocks closing original bead - data loss, security holes, crashes
- 2 (High): Should fix before closing - significant bugs, missing error handling
- 3 (Medium): Can defer - tech debt, minor bugs
- 4-5 (Low): Nice to have - code quality, performance optimizations

After creating all beads, report:
- List of bead IDs created
- Brief summary of each")

Task(subagent_type="kieran-typescript-reviewer", ...)
Task(subagent_type="kieran-python-reviewer", ...)

# Cross-cutting reviewers (always run)
Task(subagent_type="security-sentinel",
     prompt="BEAD_ID: {BEAD_ID}

Security audit for: {bead title}

Files changed:
{file list}

Check for: SQL injection, XSS, CSRF, auth bypasses, secret leaks

For each security issue found, create a bead:

bd create \"Security: {brief issue title}\" \\
  -d \"## Vulnerability
{Exact description of security issue}

## Severity
{Critical/High/Medium/Low} - {Why this severity level}

## Location
{file:line references}

## Attack Vector
{How this could be exploited}

## Fix Requirements
{Specific changes needed}

## Validation Criteria
- [ ] {Security test that must pass}
- [ ] {Exploit scenario now blocked}
- [ ] {Edge cases secured}

## Testing Steps
1. {How to verify the fix}
2. {Proof exploit is blocked}\" \\
  --type bug \\
  --priority {1-5} \\
  --tags \"security,review,{BEAD_ID}\"

Use priority for security issues:
- 1 (Critical): Auth bypass, SQL injection, XSS, secret leaks, remote code execution
- 2 (High): CSRF, insecure deserialization, missing input validation
- 3 (Medium): Information disclosure, weak crypto, missing rate limits
- 4-5 (Low): Security hardening, defense in depth improvements

After creating all beads, report:
- List of bead IDs created
- Brief summary of each security issue")

Task(subagent_type="performance-oracle", ...)
Task(subagent_type="code-simplicity-reviewer", ...)
Task(subagent_type="architecture-strategist", ...)
```

### Step 5: Collect Created Beads

After all reviewers complete:

1. Each reviewer reports the bead IDs they created
2. Collect all created beads: `bd list --tags "review,{BEAD_ID}" --json`
3. Categorize by severity:
   - **Critical** (priority 1): Must fix before closing the original bead
   - **High** (priority 2): Should fix before closing
   - **Medium** (priority 3): Can defer to follow-up work
   - **Low** (priority 4-5): Nice to have improvements

### Step 6: Link Critical Issues

For all critical and high priority beads found:

```bash
# Make critical issues block the original bead
bd dep relate {CRITICAL_BEAD_ID} {ORIGINAL_BEAD_ID}
```

This ensures the original bead cannot be closed until critical issues are resolved.

### Step 7: Present Review Summary

Output:

```
Review completed for: {BEAD_ID} - {title}

CRITICAL ISSUES (must fix before closing): {count}
{list with bead IDs, titles}

High Priority Issues: {count}
{list with bead IDs, titles}

Medium Priority Tasks: {count}
{list with bead IDs, titles}

Improvements: {count}
{list with bead IDs, titles}

All findings are now beads. View them with:
bd list --tags "review,{BEAD_ID}"

Critical issues now block {BEAD_ID}. View dependencies:
bd show {BEAD_ID}

Next steps:
- Fix critical issues: {bead IDs} (BLOCKING)
- Address high priority: {bead IDs}
- When all critical issues resolved: bd close {BEAD_ID}
```

## Reviewer Guidelines

**What reviewers SHOULD do:**
- Create beads for each distinct issue found
- Assign accurate severity levels (Critical/High/Medium/Low)
- Use priority 1 for issues that MUST block closing the original bead
- Write thorough descriptions with validation criteria
- Include specific file:line references
- Provide clear testing steps
- Report all bead IDs created, categorized by severity

**What reviewers should NOT do:**
- Create markdown files with findings
- Write review summaries to disk
- Log findings only as comments
- Create catch-all "review findings" documents
- Return findings without creating beads
- Underestimate severity (when in doubt, escalate to Critical)

## Notes

- Each reviewer creates beads for issues found (not markdown files or comments)
- Each bead has a thorough description with severity level, validation criteria, and testing steps
- Critical issues (priority 1) automatically block the original bead via dependencies
- High priority issues (priority 2) should be addressed before closing
- Beads are tagged with `review,{BEAD_ID}` for easy filtering
- Use `/beads:work {ISSUE_BEAD_ID}` to fix issues found
- The original bead cannot be closed until all blocking dependencies are resolved
- Use `bd show {BEAD_ID}` to see which critical issues are blocking closure
