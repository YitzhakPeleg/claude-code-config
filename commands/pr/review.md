---
description: Review code - either a GitHub PR, a project's changes, or current changes
allowed-tools: Bash, Read, Glob, Grep, Task, Write, AskUserQuestion
plan-mode-always: true
---

# PR / Code Review Command

Review code changes. Supports three modes based on arguments provided.

**Usage**:
- `/pr:review <PROJECT_NAME> <PR_NUMBER>` - Review a specific GitHub PR
- `/pr:review <PROJECT_NAME>` - Review uncommitted changes in a project (as if creating PR to develop)
- `/pr:review` - Review uncommitted changes in current directory (as if creating PR to develop)

**Examples**:
- `/pr:review wilibot-backend-python 352` - Review PR #352
- `/pr:review wilibot-backend-python` - Review local changes in wilibot-backend-python
- `/pr:review` - Review local changes in current working directory

## Arguments

Parse `$ARGUMENTS` to determine the mode:

### Mode 1: GitHub PR Review (`<PROJECT_NAME> <PR_NUMBER>`)
- **PROJECT_NAME**: Repository name (e.g., `wilibot-backend-python`)
- **PR_NUMBER**: PR number (e.g., `352`)
- Full repository path: `wiliot/$PROJECT_NAME`

### Mode 2: Project Local Review (`<PROJECT_NAME>`)
- **PROJECT_NAME**: Project folder name to review
- Reviews uncommitted changes compared to `develop` branch

### Mode 3: Current Directory Review (no arguments)
- Reviews uncommitted changes in current working directory
- Compares against `develop` branch

**Review file path**: `.pr-review.$PROJECT_NAME.$PR_NUMBER.md` (for GitHub PRs)

---

## MODE 1: GitHub PR Review

### Step 1: Fetch PR Information and Checkout Branch

```bash
# Get PR details
gh pr view $PR_NUMBER -R wiliot/$PROJECT_NAME --json number,title,body,headRefName,baseRefName,additions,deletions,changedFiles

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

    # Pull latest in worktree
    cd "$WORKTREE_PATH"
    git pull origin $BRANCH
fi
```

**Note**: If using worktree, all file reads during review should use `$WORKTREE_PATH` as the base path. Store `$WORKTREE_PATH` for cleanup later.

```bash
# Get the diff (against base branch)
gh pr diff $PR_NUMBER -R wiliot/$PROJECT_NAME

# Get list of changed files
gh pr diff $PR_NUMBER -R wiliot/$PROJECT_NAME --name-only
```

### Step 1b: Fetch Jira Ticket Context (if available)

Extract Jira ticket references from the branch name or PR description:

1. **Check branch name** for patterns like `CLDS-123`, `feature/CLDS-456-description`, `fix/INF-789`
2. **Check PR body/description** for ticket references (e.g., `CLDS-123`, `Fixes CLDS-456`)

**Extraction pattern**: Look for `[A-Z]+-\d+` (e.g., `CLDS-123`, `INF-456`)

If a ticket reference is found:

```bash
# Fetch ticket details
acli jira workitem view $TICKET_KEY --fields "summary,description,status,assignee,labels"
```

**Include in review context**:
- Ticket summary (what the work is supposed to accomplish)
- Ticket description (acceptance criteria, requirements)
- Current status

This context helps reviewers verify:
- Does the PR actually implement what the ticket describes?
- Are all acceptance criteria addressed?
- Is the scope appropriate for the ticket?

### Step 2: Analyze Changes

For each changed file:
1. **Read the full file** (not just diff) to understand context
2. **Apply the review checklist** (see below)
3. **Categorize findings** by severity

### Step 3: Save Review

Write to `.pr-review.$PROJECT_NAME.$PR_NUMBER.md` (see format below).

### Step 4: Ask for Approval

Ask user whether to:
- **Approve**: Submit comments to GitHub
- **Edit**: Let user modify the review file first
- **Cancel**: Don't submit anything

### Step 5: Submit to GitHub (if approved)

Submit PR-level comment and line-level comments via GitHub API.

**Important**: All comments submitted to GitHub must end with the signature:

```text
_(comment by Claude Code)_
```

Example for PR-level comment:

```bash
gh pr comment $PR_NUMBER -R wiliot/$PROJECT_NAME --body "[Review content]

_(comment by Claude Code)_"
```

Example for line-level comments:

```bash
gh api repos/wiliot/$PROJECT_NAME/pulls/$PR_NUMBER/comments \
  -f body="[Comment text]

_(comment by Claude Code)_" \
  -f commit_id="$COMMIT_SHA" \
  -f path="$FILE_PATH" \
  -F line=$LINE_NUMBER
```

---

## MODE 2: Project Local Review

### Step 1: Navigate to Project

```bash
cd $PROJECT_NAME
```

### Step 2: Get Changes vs Develop

```bash
# Get list of changed files compared to develop
git diff develop --name-only

# Get the diff
git diff develop
```

### Step 3: Analyze Changes

Same as Mode 1 - read full files, apply checklist, categorize findings.

### Step 4: Output Review

Display review directly (no file saved, no GitHub submission).

---

## MODE 3: Current Directory Review

### Step 1: Get Changes vs Develop

```bash
# Get list of changed files (staged + unstaged) compared to develop
git diff develop --name-only

# If no changes vs develop, check for uncommitted changes
git status --porcelain
```

### Step 2: Analyze Changes

Same as Mode 1 - read full files, apply checklist, categorize findings.

### Step 3: Output Review

Display review directly (no file saved, no GitHub submission).

---

## Review Checklist

Apply these checks to all review modes:

### Ticket Alignment (if Jira ticket found)
- [ ] Does the PR implement what the ticket describes?
- [ ] Are acceptance criteria/requirements addressed?
- [ ] Is the scope appropriate (not over/under-engineered for the ticket)?
- [ ] Does the PR description accurately summarize the changes?

### Architecture
- [ ] Does the change solve the intended problem?
- [ ] Is the approach appropriate?
- [ ] Are there simpler alternatives?
- [ ] Does it fit with existing patterns?

### Security
- [ ] Hardcoded tokens/secrets
- [ ] SQL injection vulnerabilities
- [ ] Input validation
- [ ] Path traversal risks
- [ ] Multi-tenancy scoping (`owner_id` filtering)
- [ ] Sensitive data in logs
- [ ] Auth gaps

### Code Quality
- [ ] Readability - clear names
- [ ] Python 3.12 best practices
- [ ] Type hints on public APIs
- [ ] Function length (<50 lines)
- [ ] Nesting depth (<3 levels)

### Async Correctness
- [ ] Race conditions
- [ ] Blocking calls in async context
- [ ] Proper await usage
- [ ] Resource cleanup

### Error Handling
- [ ] Specific exception types
- [ ] Error logging with context
- [ ] Resource cleanup on errors

### Testing
- [ ] New functions tested?
- [ ] Edge cases covered?
- [ ] @pytest.mark.asyncio on async tests?

---

## Critical Review Methodology

**Load the `critical-reviewer` skill** from `.claude/skills/critical-reviewer/SKILL.md`.

Apply these requirements to every review:

1. **Minimum 5 findings** before any approval
2. **Two-pass workflow**: Enumerate all issues first, then prioritize
3. **Anti-rubber-stamp**: Never just "LGTM" - provide substantive feedback

For trivial changes (<10 lines, typos, config), document why fewer than 5 findings.

### Review Prompts

Use these internally when conducting reviews:

**Standard**:
> Review as a senior engineer who must find at least 5 issues before approving.
> Be harsh. Check: performance, edge cases, security, code smells, error handling, naming, test gaps.

**Deep Dive** (for complex changes):
> Conduct a forensic code review. Assume bugs exist and find them.
> Find at least 10 issues before forming any approval opinion.

---

## Review Output Format

### For GitHub PRs (saved to file)

```markdown
# PR Review: wiliot/$PROJECT_NAME#$PR_NUMBER

## Summary

**Title**: <PR title>
**Branch**: <branch> → <base>
**Files Changed**: X files (+Y/-Z lines)
**Jira Ticket**: <TICKET_KEY> (if found) - [link to ticket]

## 📋 Jira Ticket Context (if available)

**Ticket**: <TICKET_KEY>
**Summary**: <ticket summary>
**Status**: <ticket status>
**Description/Requirements**:
> <ticket description or acceptance criteria>

### Ticket Alignment Check
- [ ] PR implements what the ticket describes
- [ ] Acceptance criteria addressed
- [ ] Scope is appropriate (not over/under-engineered)

## 🎯 PR-Level Comments

### Architecture Assessment
[Overall approach assessment]

### General Observations
- [Pattern 1]
- [Pattern 2]

---

## 📍 Line-Level Comments

### Critical 🔴

| File | Line | Issue |
|------|------|-------|
| `file.py` | 42 | [Description] |

### Important 🟡

| File | Line | Issue |
|------|------|-------|

### Suggestions 🟢

| File | Line | Issue |
|------|------|-------|

---

## ✅ Verdict

**Status**: [APPROVED | CHANGES_REQUIRED]
**Blocking Issues**: X critical, Y important
```

### For Local Reviews (displayed directly)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Code Review: $PROJECT_NAME
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Files Changed: X files

## Critical Issues 🔴
- `file.py:42` - [Description]

## Important Issues 🟡
- `file.py:15` - [Description]

## Suggestions 🟢
- `file.py:100` - [Description]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Verdict: [APPROVED | CHANGES_REQUIRED]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Severity Levels

- 🔴 **Critical**: Bugs, security issues, data loss risks - must fix
- 🟡 **Important**: Types, error handling, performance - should fix
- 🟢 **Suggestion**: Style, minor improvements - nice to have

## Cleanup (for GitHub PR reviews using worktree)

After the review is complete (submitted or cancelled), clean up the worktree:

```bash
if [ -n "$WORKTREE_PATH" ]; then
    cd $PROJECT_NAME  # Return to main repo
    git worktree remove "$WORKTREE_PATH" 2>/dev/null || true
fi
```

## Important Notes

- Be genuinely critical - the goal is to catch real issues
- Read full file context, not just the diff
- Check pyproject.toml for Python version and dependencies
- Look for patterns in existing code to ensure consistency
- For local reviews: focus on top 10 most impactful issues
- When using worktree, read files from `$WORKTREE_PATH` (e.g., `$WORKTREE_PATH/src/file.py`)
