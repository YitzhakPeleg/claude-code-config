---
description: End-to-end feature development workflow - from idea to implementation
allowed-tools: Bash, Read, Glob, Grep, Task, Write, Edit, AskUserQuestion, Skill
---

# Feature Development Command

Complete feature development workflow from any source to implemented code.

**Usage**: `/feature <source>`

**Sources supported**:
- Text description: `/feature add user authentication with JWT tokens`
- Jira ticket: `/feature CLDS-1234`
- GitHub issue: `/feature https://github.com/owner/repo/issues/123`

**Options**:
- `--quick`: Skip confirmation checkpoints

## Arguments

The source is provided in `$ARGUMENTS`. Parse it to determine the source type:

### Source Type Detection

```
if $ARGUMENTS is empty:
    → Ask user for description
else if $ARGUMENTS matches /^[A-Z]+-\d+$/ (e.g., CLDS-1234, INF-567):
    → Jira ticket
else if $ARGUMENTS matches GitHub issue URL pattern:
    → GitHub issue
else:
    → Text description
```

### Fetching External Sources

**Jira Ticket**:
```bash
TICKET_KEY="$ARGUMENTS"
acli jira workitem view $TICKET_KEY --fields "summary,description,status,assignee,labels"
```

Extract from ticket:
- Summary → Feature title
- Description → Requirements/acceptance criteria
- Labels → Tags for categorization

**GitHub Issue**:
```bash
# Parse URL: https://github.com/owner/repo/issues/123
gh issue view 123 -R owner/repo --json title,body,labels,assignee
```

Extract from issue:
- Title → Feature title
- Body → Requirements/acceptance criteria
- Labels → Tags for categorization

### Pre-populating Spec

When source is a ticket/issue, pre-populate the spec with:

```markdown
# Feature: [Title from ticket]

**Source**: [CLDS-1234](https://jira.example.com/browse/CLDS-1234) | [Issue #123](https://github.com/...)

## Overview
[Description from ticket]

## Requirements
[Parsed from ticket description/acceptance criteria]

## Out of Scope
[To be determined during clarify phase]
```

If `$ARGUMENTS` is empty, ask the user:
```
What feature would you like to build?

You can provide:
- A description: "add user authentication with JWT"
- A Jira ticket: CLDS-1234
- A GitHub issue URL: https://github.com/owner/repo/issues/123
```

---

## Workflow Overview

```
/feature "add user auth"
    │
    ├─► Phase 0: Setup (Jira ticket + branch)
    │
    ├─► Phase 1: Specify (create spec.md)
    │
    ├─► Phase 2: Clarify (fill gaps in spec)
    │
    ├─► Phase 3: Plan (technical design)
    │
    ├─► Phase 4: Tasks (actionable checklist)
    │
    ├─► Phase 5: Analyze (consistency check)
    │
    ├─► Phase 6: Implement (write code)
    │
    └─► Phase 7: Finalize (commit, PR, auto-merge)
```

---

## Execution

### Phase 0: Setup (Jira Ticket + Branch)

Before any development begins, ensure we have a Jira ticket and feature branch.

**If source is a Jira ticket (e.g., CLDS-1234)**:

- Use the provided ticket key
- Fetch ticket details for context

**If source is a text description**:

- Create a new Jira ticket:

```bash
acli jira workitem create --project "CLDS" --type "Task" \
  --summary "<Feature summary from description>" \
  --description "<Full feature description>"
```

- Extract the ticket key from the response (e.g., CLDS-16964)

**Create the feature branch**:

```bash
# Detect the project directory and navigate to it
cd <project-directory>

# Create branch based on Jira ticket (NO slashes in branch name)
git checkout -b <TICKET_KEY>-<slug-from-summary>
# Example: CLDS-16964-disable-mlflow-tracing
```

**IMPORTANT**: Branch names must NOT contain `/` characters. Use only the ticket key and slug separated by hyphens.

**Checkpoint**: Show the user:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Phase 0: Setup Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Jira: <TICKET_KEY> - <TICKET_SUMMARY>
Branch: <TICKET_KEY>-<slug>
Project: <PROJECT_NAME>

Continue to specification phase? (Y/n)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Phase 1: Specify

Run the specify workflow to create the initial specification:

```
/feature:specify $ARGUMENTS
```

This will:
1. Detect the project
2. Ask for branch name (or auto-generate)
3. Create `specs/<branch>/spec.md`

**Checkpoint**: Show the user:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Phase 1: Specification Created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: <PROJECT_NAME>
Branch: <BRANCH_NAME>
Spec: <SPEC_FILE_PATH>

[Summary of key requirements from spec]

Continue to clarification phase? (Y/n)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Phase 2: Clarify

Run the clarify workflow to identify and fill gaps:

```
/feature:clarify
```

This will:
1. Analyze the spec for ambiguities
2. Ask up to 5 clarifying questions
3. Update the spec with answers

**Checkpoint**: Show the user:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Phase 2: Specification Clarified
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Questions answered: X
Spec updated: ✓

Continue to planning phase? (Y/n)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If user wants to skip clarification (e.g., exploratory spike), warn:
```
⚠️  Skipping clarification increases rework risk.
    Proceeding to planning...
```

---

### Phase 3: Plan

Run the plan workflow to create technical design:

```
/feature:plan
```

This will:
1. Analyze existing codebase patterns
2. Create `specs/<branch>/plan.md`
3. Define architecture and file changes

**Checkpoint**: Show the user:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Phase 3: Implementation Plan Created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Plan: <PLAN_FILE_PATH>

Key decisions:
- [Architecture decision 1]
- [Architecture decision 2]

Files to modify: X
Files to create: Y

Continue to task generation? (Y/n)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Phase 4: Tasks

Run the tasks workflow to generate actionable checklist:

```
/feature:tasks
```

This will:
1. Break down plan into ordered tasks
2. Create `specs/<branch>/tasks.md`
3. Mark dependencies and priorities

**Checkpoint**: Show the user:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Phase 4: Task List Generated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Tasks: <TASKS_FILE_PATH>

Total tasks: X
- Critical path: Y tasks
- Testing: Z tasks

Continue to consistency analysis? (Y/n)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Phase 5: Analyze

Run the analyze workflow to verify consistency:

```
/feature:analyze
```

This will:
1. Cross-check spec ↔ plan ↔ tasks
2. Identify gaps or conflicts
3. Check constitution compliance

**Checkpoint**: Show the user:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Phase 5: Consistency Analysis Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Issues found: X
- Critical: 0
- Warnings: X

[List any issues]

Continue to implementation? (Y/n)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If critical issues found, stop and ask user to resolve before continuing.

---

### Phase 6: Implement

Run the implement workflow to execute tasks:

```
/feature:implement
```

This will:
1. Work through tasks in order
2. Write code following the plan
3. Mark tasks complete
4. Run linting and formatting

**Checkpoint**: Show the user:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Phase 6: Implementation Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Files modified: X
Files created: Y
Tests added: Z

Continue to finalization? (Y/n)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Phase 7: Finalize (Commit, PR, Auto-merge)

After implementation is complete, finalize with commit, PR, and auto-merge.

**Step 7.1: Lint and Format**

```bash
cd <project-directory>
make format   # Auto-format code
make lint     # Run linting checks
```

If linting fails, fix the issues before proceeding.

**Step 7.2: Commit Changes**

```bash
git add .
git commit -m "$(cat <<'EOF'
<TICKET_KEY>: <Short description>

<Detailed description of changes>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

**Step 7.3: Push to Remote**

```bash
git push -u origin <BRANCH_NAME>
```

**Step 7.4: Create Pull Request**

```bash
gh pr create --title "<TICKET_KEY>: <Summary>" --body "$(cat <<'EOF'
## Summary

- <Bullet point 1>
- <Bullet point 2>

## Test plan

- [ ] <Test item 1>
- [ ] <Test item 2>

## Related

- Jira: [<TICKET_KEY>](https://wiliot.atlassian.net/browse/<TICKET_KEY>)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**Step 7.5: Enable Auto-merge**

```bash
gh pr merge <PR_NUMBER> --auto --squash
```

**Final Output**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Feature Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: $ARGUMENTS
Jira: <TICKET_KEY>
Branch: <BRANCH_NAME>
PR: <PR_URL>

Artifacts:

- Spec: <SPEC_FILE_PATH>
- Plan: <PLAN_FILE_PATH>
- Tasks: <TASKS_FILE_PATH>

Changes:

- Files modified: X
- Files created: Y
- Tests added: Z

Status: Auto-merge enabled ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Options

Users can customize the workflow by responding to checkpoints:

| Response | Action |
|----------|--------|
| `Y` or Enter | Continue to next phase |
| `n` | Stop workflow, keep artifacts |
| `skip` | Skip current phase, continue to next |
| `edit` | Pause to manually edit current artifact |

---

## Resuming

If the workflow is interrupted, it can be resumed by running `/feature` again. The command will:

1. Check for existing artifacts in `specs/` directory
2. Detect current branch name
3. Ask user where to resume:
   ```
   Found existing feature artifacts for: <BRANCH_NAME>

   Existing:
   ✓ spec.md
   ✓ plan.md
   ✗ tasks.md

   Resume from task generation? (Y/n)
   ```

---

## Quick Mode

For experienced users who want less interaction:

```
/feature --quick "add user auth"
```

Quick mode:
- Skips confirmation checkpoints
- Only stops on critical issues
- Shows final summary at end

---

## Sub-Commands

Individual phases can still be run separately:

| Command | Phase |
|---------|-------|
| `/feature:specify` | Create specification |
| `/feature:clarify` | Fill spec gaps |
| `/feature:plan` | Technical design |
| `/feature:tasks` | Generate task list |
| `/feature:analyze` | Consistency check |
| `/feature:implement` | Execute tasks |
| `/feature:finalize` | Commit, PR, auto-merge |
| `/feature:constitution` | Manage project principles |

Use these when you need to re-run a specific phase or work incrementally.
