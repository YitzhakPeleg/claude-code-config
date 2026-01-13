---
description: Fix PR review issues from local review file and/or GitHub PR comments
allowed-tools: Bash, Read, Glob, Grep, Task, Write, Edit, AskUserQuestion
plan-mode-always: true
---

# Fix PR Review Issues

Fix review issues from both local review files and GitHub PR comments.

**Usage**: `/pr:fix <PROJECT_NAME> <PR_NUMBER>`

**Example**: `/pr:fix wilibot-backend-python 366`

## Arguments

Parse `$ARGUMENTS` to extract:

- **PROJECT_NAME**: First argument - the repository name (e.g., `wilibot-backend-python`)
- **PR_NUMBER**: Second argument - the PR number (e.g., `366`)

The full repository path will be: `wiliot/$PROJECT_NAME`

**Review file path**: `.pr-review.$PROJECT_NAME.$PR_NUMBER.md`

---

## PLAN MODE: Research and Planning Phase

### Step 1: Setup

```bash
# Get PR details
gh pr view $PR_NUMBER -R wiliot/$PROJECT_NAME --json number,title,headRefName,baseRefName

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

    # Work from the worktree
    cd "$WORKTREE_PATH"
    git pull origin $BRANCH
fi
```

**Important**: If using worktree (`$WORKTREE_PATH` is set), all file operations (read, edit, lint, commit, push) must be done from `$WORKTREE_PATH`.

### Step 2: Gather Issues from All Sources

#### Source 1: Local Review File

Check for local review file at `.pr-review.$PROJECT_NAME.$PR_NUMBER.md`:

```bash
ls -la .pr-review.$PROJECT_NAME.$PR_NUMBER.md 2>/dev/null
```

If it exists, parse issues from it. The file should contain structured review comments with:
- File paths and line numbers
- Severity levels (🔴 Critical, 🟡 Important, 🟢 Suggestion)
- Issue descriptions

#### Source 2: GitHub PR Comments

Fetch unresolved review comments from GitHub:

```bash
# Get review comments (original comments only, not replies)
gh api repos/wiliot/$PROJECT_NAME/pulls/$PR_NUMBER/comments \
  --jq '.[] | select(.in_reply_to_id == null) | {id, path, line, body, user: .user.login, created_at}'
```

Check which threads are already resolved:

```bash
# Get review threads and their resolution status
gh api graphql -f query='
query {
  repository(owner: "wiliot", name: "'$PROJECT_NAME'") {
    pullRequest(number: '$PR_NUMBER') {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 10) {
            nodes {
              id
              databaseId
              body
              author { login }
              path
              line
            }
          }
        }
      }
    }
  }
}'
```

Filter to only **unresolved** threads. Also exclude comments that already have replies from the PR author (likely already addressed).

### Step 3: Deduplicate and Merge Issues

Combine issues from both sources:
- Remove duplicates (same file + line + similar issue)
- Keep GitHub comment IDs for reply tracking
- Preserve severity classifications

### Step 4: Analyze Each Issue

For each unique issue:

1. **Read the file and line** mentioned
2. **Understand the issue** being raised
3. **Determine the appropriate fix** or response
4. **Classify severity** if not already set:
   - **Critical (🔴)**: Bugs, security issues, data loss risks
   - **Important (🟡)**: Missing types, error handling, performance
   - **Suggestion (🟢)**: Style, minor improvements (non-blocking)

### Step 5: Write the Fix Plan

Write a detailed plan to the plan file:

```markdown
# PR Fix Plan

**PR**: wiliot/$PROJECT_NAME#$PR_NUMBER
**Branch**: $BRANCH

## Sources

- Local review file: [Found/Not found]
- GitHub comments: [X unresolved comments]

## Issues to Fix

### 1. [File:Line] - [Brief Title]

**Source**: Local review / GitHub (comment ID: XXX)
**Severity**: 🔴 Critical / 🟡 Important / 🟢 Suggestion
**Reviewer**: [username]

**Issue**:
> [Quote the review comment]

**Current Code**:
```python
[Show the current code]
```

**Proposed Fix**:
```python
[Show the fixed code]
```

**Rationale**: [Why this fix addresses the issue]

---

### 2. [Next issue...]

...

## Issues to Skip (with explanation)

### [File:Line] - [Brief Title]

**Source**: [source]
**Reason**: [Why no change is needed]

---

## Execution Plan

1. Fix [file1.py:XX] - [description]
2. Fix [file2.py:XX] - [description]
3. Run lint and format
4. Commit changes
5. Reply to GitHub comments
6. Push to remote
```

### Step 6: Exit Plan Mode

After writing the plan, use ExitPlanMode to get user approval.

---

## EXECUTION MODE: After Approval

Once the user approves the plan, execute the fixes:

### For Each Fix

#### 1. Implement the Fix

1. Make the code changes as specified in the plan
2. If the fix differs from the plan, explain why
3. Maintain code style consistency

#### 2. Lint & Format

```bash
cd $PROJECT_NAME
make lint
make format
```

#### 3. Commit the Fix

```bash
git add -A
git commit -m "fix: [brief description]

Addresses review feedback"
```

### Reply to GitHub Comments

For each GitHub comment that was fixed:

```bash
gh api "repos/wiliot/$PROJECT_NAME/pulls/$PR_NUMBER/comments/$COMMENT_ID/replies" \
  -f body="Fixed: [explanation of what was changed]

(by Claude Code)"
```

For skipped comments:

```bash
gh api "repos/wiliot/$PROJECT_NAME/pulls/$PR_NUMBER/comments/$COMMENT_ID/replies" \
  -f body="No change needed: [explanation]

(by Claude Code)"
```

### Resolve Threads After Replying

After replying to a comment, resolve the thread:

```bash
# Get the thread ID from the GraphQL query earlier
gh api graphql -f query='
  mutation($threadId: ID!) {
    resolveReviewThread(input: {threadId: $threadId}) {
      thread { id isResolved }
    }
  }
' -f threadId="$THREAD_ID"
```

### Push Changes

```bash
git push origin $BRANCH
```

### Update Local Review File

If a local review file exists, mark fixed issues as completed or remove the file:

```bash
rm .pr-review.$PROJECT_NAME.$PR_NUMBER.md
```

### Cleanup Worktree

If we created a worktree, clean it up after pushing:

```bash
if [ -n "$WORKTREE_PATH" ]; then
    cd $PROJECT_NAME  # Return to main repo
    git worktree remove "$WORKTREE_PATH" 2>/dev/null || true
fi
```

### Display Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PR Fix Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PR: wiliot/$PROJECT_NAME#$PR_NUMBER

Sources:
- Local review: [X issues]
- GitHub comments: [Y issues]

Issues Fixed: Z
- [file:line] - [description]
- [file:line] - [description]

Issues Skipped: W
- [file:line] - [reason]

Commits Made: N
GitHub comments replied: ✅
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Important Notes

- **Plan mode is mandatory** - always show the plan and wait for approval
- Check BOTH local review file AND GitHub comments
- Deduplicate issues that appear in both sources
- Always reply to GitHub comments after fixing
- Run lint/format before committing
- Remove local review file after fixes are complete
- When using worktree, ensure all operations (read, edit, lint, commit) happen in `$WORKTREE_PATH`
- Always clean up worktrees when done to avoid cluttering the filesystem

## Do Not

- Skip Critical or Important issues without asking
- Make superficial fixes that don't address the real problem
- Forget to reply to GitHub comments
- Push without running lint and format
- Execute fixes without user approval
- Forget to clean up worktrees after completing fixes
