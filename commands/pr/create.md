---
description: Create a pull request with proper ticket linking and structured description
allowed-tools: Bash, Read, Glob, Grep, Write, AskUserQuestion
---

# Create Pull Request Command

Create a well-structured pull request with ticket/issue linking and comprehensive description.

**Usage**: `/pr:create`

This command analyzes the current branch and commits to generate a PR with:
- Linked Jira ticket or GitHub issue (if detected)
- Structured description (Problem, Solution, Details)
- Auto-generated title from ticket or commits

---

## Step 1: Gather Context

### Get Current Branch and Commits

```bash
# Get current branch name
BRANCH=$(git branch --show-current)

# Get commits on this branch (compared to develop/main)
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "develop")
COMMITS=$(git log origin/$BASE_BRANCH..HEAD --oneline)

# Get changed files
CHANGED_FILES=$(git diff origin/$BASE_BRANCH --name-only)

# Get diff stats
DIFF_STATS=$(git diff origin/$BASE_BRANCH --stat)
```

### Detect Ticket/Issue Reference

Extract ticket reference from branch name or commit messages:

```bash
# Check branch name for ticket pattern (e.g., CLDS-1234-feature-name)
TICKET=$(echo "$BRANCH" | grep -oE '^[A-Z]+-[0-9]+' || echo "")

# If not in branch, check commit messages
if [ -z "$TICKET" ]; then
    TICKET=$(git log origin/$BASE_BRANCH..HEAD --format=%s | grep -oE '[A-Z]+-[0-9]+' | head -1 || echo "")
fi

# Check for GitHub issue reference
ISSUE_NUM=$(echo "$BRANCH" | grep -oE '#[0-9]+|issue-[0-9]+' | grep -oE '[0-9]+' || echo "")
```

### Prompt for Ticket Creation (Ad-hoc PRs)

**If no ticket/issue is detected**, prompt the user:

```text
⚠️  No Jira ticket or GitHub issue detected in branch name or commits.

Would you like to:
1. Create a Jira ticket for this PR (Wiliot repos)
2. Create a GitHub issue for this PR (Personal repos)
3. Proceed without a ticket (not recommended for non-trivial changes)
```

Use AskUserQuestion to get user preference. If they choose to create:

```bash
# Detect tracking backend
BACKEND=$(.specify/scripts/bash/detect-tracking-backend.sh)

if [[ "$BACKEND" == "jira" ]]; then
    # Prompt for ticket details
    TICKET=$(acli jira workitem create \
        --project "CLDS" \
        --type "Task" \
        --summary "<PR_TITLE>" \
        --description "<First commit message or user-provided description>" \
        --json | jq -r '.key')
    echo "Created Jira ticket: $TICKET"
elif [[ "$BACKEND" == "github" ]]; then
    ISSUE_NUM=$(gh issue create \
        --title "<PR_TITLE>" \
        --body "<First commit message or user-provided description>" \
        | grep -oE '[0-9]+$')
    echo "Created GitHub issue: #$ISSUE_NUM"
fi
```

### Fetch Ticket/Issue Details

**If Jira ticket found:**
```bash
if [ -n "$TICKET" ]; then
    TICKET_INFO=$(acli jira workitem view $TICKET --fields "summary,description,status" --json 2>/dev/null)
    TICKET_TITLE=$(echo "$TICKET_INFO" | jq -r '.fields.summary')
    TICKET_DESC=$(echo "$TICKET_INFO" | jq -r '.fields.description')
    TICKET_URL="https://wiliot.atlassian.net/browse/$TICKET"
fi
```

**If GitHub issue found:**
```bash
if [ -n "$ISSUE_NUM" ]; then
    REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
    ISSUE_INFO=$(gh issue view $ISSUE_NUM --json title,body,url)
    ISSUE_TITLE=$(echo "$ISSUE_INFO" | jq -r '.title')
    ISSUE_DESC=$(echo "$ISSUE_INFO" | jq -r '.body')
    ISSUE_URL=$(echo "$ISSUE_INFO" | jq -r '.url')
fi
```

---

## Step 2: Check for Spec Artifacts

Look for feature spec files that might provide additional context:

```bash
# Check if there's a spec file for this branch
SPEC_FILE=$(find . -path "*/specs/*${BRANCH}*/spec.md" -o -path "*/specs/*${TICKET}*/spec.md" 2>/dev/null | head -1)

if [ -n "$SPEC_FILE" ]; then
    # Extract problem/solution from spec if available
    SPEC_CONTENT=$(cat "$SPEC_FILE")
fi
```

---

## Step 3: Generate PR Content

### Title Generation

Priority order for PR title:
1. Ticket summary (if Jira ticket)
2. Issue title (if GitHub issue)
3. First commit message summary
4. Ask user

Format: `[TICKET-123] Brief description` or `feat: description`

### Description Template

Generate the PR description using this structure:

```markdown
## Problem

[What problem does this PR solve? Why was this change needed?]

- Context from ticket/issue description
- Or summarize from commits if no ticket

## Solution

[How does this PR solve the problem?]

- High-level approach
- Key changes made
- Architecture decisions (if any)

## Changes

[List of significant changes]

- File/component 1: what changed
- File/component 2: what changed

## Testing

[How was this tested?]

- [ ] Unit tests added/updated
- [ ] Integration tests
- [ ] Manual testing performed

## Links

- **Ticket**: [CLDS-1234](https://wiliot.atlassian.net/browse/CLDS-1234)
- **Spec**: [spec.md](./specs/CLDS-1234/spec.md) (if exists)

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

---

## Step 4: Create the PR

### Show Preview and Confirm

**CRITICAL: You MUST display the COMPLETE generated PR content to the user BEFORE asking for approval.**

Display the FULL generated PR content (not abbreviated):

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 PR Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: [CLDS-1234] Add user authentication

## Problem
[Display the COMPLETE problem description - not abbreviated]

## Solution
[Display the COMPLETE solution description - not abbreviated]

## Changes
[Display the COMPLETE list of changes - not abbreviated]

## Testing
[Display the COMPLETE testing section - not abbreviated]

## Links
[Display the COMPLETE links section - not abbreviated]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**NEVER use "..." or abbreviate content. Show everything that will be submitted.**

Then ask for confirmation using AskUserQuestion:

Options:
- `Y` or Enter: Create the PR
- `edit`: Let user modify title/description
- `n`: Cancel

### Execute PR Creation

```bash
gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base "$BASE_BRANCH"
```

### Link to Ticket and Transition to "In Review"

After PR creation, link to the ticket and transition status:

```bash
PR_URL=$(gh pr view --json url -q '.url')

# Detect tracking backend
BACKEND=$(.specify/scripts/bash/detect-tracking-backend.sh)

if [[ "$BACKEND" == "jira" ]] && [ -n "$TICKET" ]; then
    # Add comment with PR link
    acli jira workitem comment create \
        --key "$TICKET" \
        --body "PR created: $PR_URL"

    # Transition to "In Review"
    acli jira workitem transition --key "$TICKET" --status "In Review" --yes
    echo "Ticket $TICKET transitioned to 'In Review'"

elif [[ "$BACKEND" == "github" ]] && [ -n "$ISSUE_NUM" ]; then
    # Add label for in-review status
    gh issue edit "$ISSUE_NUM" --add-label "in-review" --remove-label "in-progress" 2>/dev/null || true
    echo "Issue #$ISSUE_NUM labeled as 'in-review'"
fi
```

### Enable Auto-merge

After PR creation, enable auto-merge with squash:

```bash
PR_NUMBER=$(gh pr view --json number -q '.number')
gh pr merge $PR_NUMBER --auto --squash
```

---

## Step 5: Output Summary

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PR Created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PR: https://github.com/owner/repo/pull/123
Title: [CLDS-1234] Add user authentication
Base: develop ← feature-branch

Linked:
- Jira: CLDS-1234 ✓ (Status: In Review)
- Spec: specs/CLDS-1234/spec.md ✓

Auto-merge: ✅ Enabled (squash)

Status Transitions:
- Ticket: → In Review ✓
- On merge: → Done (automatic)

Next steps:
- Review: /pr:review <PR_NUMBER>
- Or wait for CI and reviewers

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 6: Teams Message (Copy-Paste Ready)

Output a formatted message for posting to Teams:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Teams Message (copy-paste ready)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 **PR Ready for Review**

**Title**: [CLDS-1234] Add user authentication
**PR**: https://github.com/wiliot/REPO/pull/123
**Jira**: https://wiliot.atlassian.net/browse/CLDS-1234

Changes:
- Key change 1
- Key change 2

Auto-merge: ✅ Enabled

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Replace placeholders with actual values from the PR.

---

## PR Description Guidelines

### Problem Section
- Explain the "why" - what user problem or business need
- Reference ticket requirements if available
- Keep it concise but complete

### Solution Section
- Explain the "how" at a high level
- Mention key architectural decisions
- Don't repeat code - describe the approach

### Changes Section
- Group by component/area
- Focus on significant changes, not every file
- Highlight breaking changes or migrations

### Testing Section
- Be specific about what was tested
- Include manual testing steps if relevant
- Note any areas that need extra review

---

## Examples

### With Jira Ticket

```markdown
## Problem

Users cannot reset their passwords when they forget them, leading to support tickets.

Resolves [CLDS-1234](https://wiliot.atlassian.net/browse/CLDS-1234)

## Solution

Added a password reset flow with email verification:
- New `/auth/reset-password` endpoint
- Email service integration for sending reset links
- Token-based verification with 1-hour expiry

## Changes

- `src/auth/`: New password reset endpoints and service
- `src/email/`: Email template for reset link
- `database/`: Migration for reset tokens table

## Testing

- [x] Unit tests for reset flow
- [x] Integration test for email sending
- [x] Manual testing with real email

## Links

- **Ticket**: [CLDS-1234](https://wiliot.atlassian.net/browse/CLDS-1234)
```

### Without Ticket

```markdown
## Problem

The API response times have degraded due to N+1 query issues in the user listing endpoint.

## Solution

Optimized database queries using eager loading and batch fetching:
- Replaced individual queries with `selectinload`
- Added database indexes for common filters
- Implemented response caching for read-heavy endpoints

## Changes

- `src/api/users.py`: Query optimization
- `database/migrations/`: New indexes
- `src/cache/`: Redis caching layer

## Testing

- [x] Load testing shows 80% improvement
- [x] Unit tests updated
- [x] Staging deployment verified
```
