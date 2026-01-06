# PR Review-Fix Loop

Run an iterative review-fix loop on a PR until the code is approved or max iterations reached.

**Usage**: `/pr:review-loop <PROJECT_NAME> <PR_NUMBER>`

**Example**: `/pr:review-loop wilibot-backend-python 324`

## Arguments

Parse `$ARGUMENTS` to extract:

- **PROJECT_NAME**: First argument - the repository name (e.g., `wilibot-backend-python`)
- **PR_NUMBER**: Second argument - the PR number (e.g., `324`)

The full repository path will be: `wiliot/$PROJECT_NAME`

**Review file path**: `.pr-review.$PROJECT_NAME.$PR_NUMBER.md`

## Prerequisites

- PR already exists on GitHub
- You have push access to the PR branch
- `gh` CLI is authenticated

## Process

### Step 1: Initialize

Fetch PR information and checkout the latest version of the branch:

```bash
# Get PR details
gh pr view $PR_NUMBER -R wiliot/$PROJECT_NAME --json number,title,body,headRefName,baseRefName

# Get the PR branch name
cd $PROJECT_NAME
BRANCH=$(gh pr view $PR_NUMBER -R wiliot/$PROJECT_NAME --json headRefName -q '.headRefName')
CURRENT_BRANCH=$(git branch --show-current)

# Check if we're already on the PR branch
if [ "$CURRENT_BRANCH" = "$BRANCH" ]; then
    # Already on PR branch - just pull latest
    git pull origin $BRANCH
    WORKTREE_PATH=""
else
    # Not on PR branch - use git worktree to avoid disrupting current work
    WORKTREE_PATH="../.worktrees/$PROJECT_NAME-pr-$PR_NUMBER"

    # Clean up any stale worktree
    git worktree remove "$WORKTREE_PATH" 2>/dev/null || true

    # Fetch and create worktree
    git fetch origin $BRANCH
    git worktree add "$WORKTREE_PATH" $BRANCH

    # Work from the worktree for the rest of the loop
    cd "$WORKTREE_PATH"
    git pull origin $BRANCH
fi
```

Store the branch name and worktree path - you'll need them for pushing fixes and cleanup.

**Important**: If using worktree (`$WORKTREE_PATH` is set), all file operations (read, edit, lint, commit, push) must be done from `$WORKTREE_PATH`.

### Step 1b: Fetch Jira Ticket Context (if available)

Extract Jira ticket references from the branch name or PR description:

1. **Check branch name** (`headRefName`) for patterns like `CLDS-123`, `feature/CLDS-456-description`, `fix/INF-789`
2. **Check PR body** for ticket references (e.g., `CLDS-123`, `Fixes CLDS-456`)

**Extraction pattern**: Look for `[A-Z]+-\d+` (e.g., `CLDS-123`, `INF-456`)

If a ticket reference is found:

```bash
# Fetch ticket details
acli jira workitem view $TICKET_KEY --fields "summary,description,status,assignee,labels"
```

**Store for use throughout the loop**:
- Ticket key and summary
- Ticket description/acceptance criteria
- Current status

This context helps both the Reviewer and Programmer phases:
- **Reviewer**: Verify PR implements what the ticket describes
- **Programmer**: Understand the intent when making fixes

### Step 2: Review-Fix Loop

**Maximum iterations: 5**

For each iteration:

#### 2a. Get Current Diff

```bash
gh pr diff $PR_NUMBER -R wiliot/$PROJECT_NAME
```

Also examine the actual files changed to understand full context, not just the diff.

#### 2a-bis. Reset Reviewer Mindset (Iterations 2+)

**CRITICAL**: Before reviewing iteration 2+, mentally reset:

1. **Pretend this is a NEW conversation** - Forget what you found in previous iterations
2. **Re-read the critical-reviewer skill** - Apply the full "minimum 5 findings" rule fresh
3. **Do NOT read the review file first** - Conduct review independently, THEN compare
4. **Re-read Jira requirements** (if available) - Verify against original acceptance criteria, not just "fixes look good"

> ⚠️ **Anti-anchoring rule**: Finding fewer issues in iteration 2+ because "issues were fixed" is a **reviewer failure**. New issues can always exist. Apply the same rigor as iteration 1.

#### 2b. REVIEWER Phase

**Switch to Reviewer persona.** Load and apply the `critical-reviewer` skill from `.claude/skills/critical-reviewer/SKILL.md`.

**Apply critical review methodology:**

- **Minimum 5 findings** per iteration before considering approval (**regardless of iteration number**)
- **Two-pass workflow**: Enumerate all issues first, then prioritize
- **No rubber-stamping**: Provide substantive feedback, never just "LGTM"
- **IMPORTANT**: Apply the SAME rigor as if this were iteration 1 in a fresh conversation

Conduct a thorough review **as if you've never seen this code before**:

- Apply the full checklist from the skill
- Be genuinely critical - finding nothing wrong is a failure of review
- Consider the PR description and Jira ticket for context on intent

Write the review to `.pr-review.$PROJECT_NAME.$PR_NUMBER.md`:

```markdown
## Iteration N - Review

**Verdict**: [🔴 CHANGES_REQUIRED | ✅ APPROVED]

### Jira Ticket Context (if found, include in first iteration only)

**Ticket**: $TICKET_KEY - [ticket summary]
**Requirements**: [brief summary of acceptance criteria]

### Ticket Alignment Check

- [ ] PR implements what the ticket describes
- [ ] Acceptance criteria addressed
- [ ] Scope is appropriate

### Critical Issues 🔴

| File | Line | Issue |
|------|------|-------|
| `file.py` | XX | [description] |

### Important Issues 🟡

| File | Line | Issue |
|------|------|-------|
| `file.py` | XX | [description] |

### Suggestions 🟢

| File | Line | Issue |
|------|------|-------|

### Positive Notes

- [what's good about this code]
```

#### 2c. Check Verdict

**If APPROVED:**

- Add final note: `## Final Status: ✅ APPROVED`
- Display summary of iterations and key improvements made
- **STOP the loop**

**If CHANGES_REQUIRED:**

- Continue to Programmer phase

#### 2d. PROGRAMMER Phase

**Switch to Programmer persona.** You are now a senior developer fixing review feedback.

For each 🔴 Critical and 🟡 Important issue:

1. Understand the issue fully
2. Implement the fix properly (not just superficially)
3. Run lint and format
4. Mark the item as fixed in the review file

After all fixes:

```bash
make lint
make format
git add -A
git commit -m "fix: address review feedback - iteration N

- [summary of fixes]"
git push
```

Update the review file:

```markdown
### Fixes Applied (Iteration N)

- [x] `file.py:XX` - [what was fixed]
- [x] `file.py:XX` - [what was fixed]
```

#### 2e. Return to Step 2a

**IMPORTANT**: Before returning to review:

- Clear your mental slate - pretend this is a NEW conversation
- DO NOT let previous findings anchor your review
- The code may have introduced NEW issues while fixing old ones
- Apply the full "minimum 5 findings" rule again

Get fresh diff and review again.

---

## Termination Conditions

1. **APPROVED**: Reviewer finds no Critical or Important issues
2. **Max Iterations**: After 5 iterations, stop and report status
3. **Manual Stop**: User interrupts

## Cleanup

After the loop completes (whether APPROVED or max iterations reached):

```bash
# Remove the review file if approved
rm -f .pr-review.$PROJECT_NAME.$PR_NUMBER.md

# Clean up worktree if we created one
if [ -n "$WORKTREE_PATH" ]; then
    cd $PROJECT_NAME  # Return to main repo
    git worktree remove "$WORKTREE_PATH" 2>/dev/null || true
fi
```

If not approved after max iterations, keep the review file for reference but still clean up the worktree.

## Output Format

Display progress clearly:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 PR Review Loop: wiliot/$PROJECT_NAME#$PR_NUMBER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Jira Ticket: CLDS-123 - [ticket summary]
   Status: In Progress

━━━ Iteration 1/5 ━━━

🔍 REVIEWER
[review output including ticket alignment check]

👨‍💻 PROGRAMMER
[fixes applied]
[commit: abc123]

━━━ Iteration 2/5 ━━━
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ APPROVED after 3 iterations
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Important Notes

- Be genuinely critical in Reviewer mode - the goal is to catch real issues
- In Programmer mode, make proper fixes, not band-aids
- If a fix is complex, explain what you changed and why
- The review file can be used by `/pr:fix` if the loop is interrupted
- When using worktree, ensure all operations (read, edit, lint, commit) happen in `$WORKTREE_PATH`
- Always clean up worktrees when done to avoid cluttering the filesystem
- **Anti-anchoring**: Each iteration MUST be reviewed with "fresh eyes" as if it were a new conversation. Approving because "iteration 1 issues were fixed" without finding new issues is a review failure.
