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

## Interactive Prompting

If no arguments are provided or arguments are incomplete, prompt the user:

1. **If `$ARGUMENTS` is empty**: Ask for both repository name and PR number
2. **If only PROJECT_NAME provided**: Ask if they want to review local changes or a specific PR

Use AskUserQuestion tool:

```text
Question: "Which repository would you like to review?"
Options:
- wilibot-backend-python
- platform-gen-ai
- gen-ai-proxy
- wiliot-mcp-python
- Other (specify)

Question: "Enter the PR number to review (or leave empty for local changes):"
```

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

### Step 2: Context Analysis (BEFORE reviewing code)

**This is critical.** Before looking at the diff in detail, analyze the broader context:

#### 2a. Repository Structure and Architecture

```bash
# Understand the project structure
ls -la $PROJECT_NAME/
cat $PROJECT_NAME/README.md 2>/dev/null || true
cat $PROJECT_NAME/pyproject.toml 2>/dev/null || true
cat $PROJECT_NAME/package.json 2>/dev/null || true
```

Identify:

- Key directories and their purposes
- Architectural patterns (e.g., layered architecture, microservices)
- Tech stack and dependencies

#### 2b. Related Files and Modules

For each changed file, identify:

- What module/package does it belong to?
- What other files import or depend on it?
- Are there tests for this file?

```bash
# Find files that import/reference the changed files
grep -r "from changed_module import" $PROJECT_NAME/src/
grep -r "import changed_module" $PROJECT_NAME/src/
```

#### 2c. Existing Code Patterns

Look at similar files in the codebase:

- How is error handling done elsewhere?
- What naming conventions are used?
- How are similar features implemented?

```bash
# Find similar files to understand patterns
find $PROJECT_NAME -name "*.py" -path "*/same_directory/*" | head -5
```

#### 2d. PR Description and Linked Issues

Parse the PR description thoroughly:

- What problem is this solving?
- What is the proposed solution?
- Any linked issues or tickets?

**Output the Context Summary** before proceeding:

```text
## Context Summary

- **What this PR accomplishes**: [1-2 sentence description]
- **Architecture fit**: [How it fits into the repo's architecture]
- **Relevant patterns**: [Key patterns/conventions that apply]
```

### Step 3: Analyze Changes

For each changed file:

1. **Read the full file** (not just diff) to understand context
2. **Apply the review checklist** (see below)
3. **Format findings** using the standard format

**Focus on high-value feedback. Skip minor style issues unless they impact readability.**

### Step 4: Save Review

Write to `.pr-review.$PROJECT_NAME.$PR_NUMBER.md` (see format below).

### Step 5: Display Plan and Ask for Approval

**CRITICAL: You MUST display the complete review to the user BEFORE asking for approval.**

Display the full review content that was saved to the file:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Review Plan
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Display the COMPLETE contents of .pr-review.$PROJECT_NAME.$PR_NUMBER.md here]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**NEVER ask for approval without first showing the plan.** The user must see exactly what will be submitted.

Then ask the user whether to:

- **Approve**: Submit comments to GitHub
- **Edit**: Let user modify the review file first
- **Cancel**: Don't submit anything

### Step 6: Submit to GitHub (if approved)

Submit PR-level comment and line-level comments via GitHub API.

**Important**: All comments submitted to GitHub must end with the signature:

```text
(by Claude Code)
```

Example for PR-level comment:

```bash
gh pr comment $PR_NUMBER -R wiliot/$PROJECT_NAME --body "[Review content]

(by Claude Code)"
```

Example for line-level comments:

```bash
gh api repos/wiliot/$PROJECT_NAME/pulls/$PR_NUMBER/comments \
  -f body="[Comment text]

(by Claude Code)" \
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

### Step 2: Context Analysis

Same as Mode 1 Step 2 - analyze repository structure, patterns, and conventions.

### Step 3: Get Changes vs Develop

```bash
# Get list of changed files compared to develop
git diff develop --name-only

# Get the diff
git diff develop
```

### Step 4: Analyze Changes

Same as Mode 1 - read full files, apply checklist, format findings.

### Step 5: Output Review

Display review directly (no file saved, no GitHub submission).

---

## MODE 3: Current Directory Review

### Step 1: Context Analysis

Same as Mode 1 Step 2 - analyze repository structure, patterns, and conventions.

### Step 2: Get Changes vs Develop

```bash
# Get list of changed files (staged + unstaged) compared to develop
git diff develop --name-only

# If no changes vs develop, check for uncommitted changes
git status --porcelain
```

### Step 3: Analyze Changes

Same as Mode 1 - read full files, apply checklist, format findings.

### Step 4: Output Review

Display review directly (no file saved, no GitHub submission).

---

## Review Focus Areas

Prioritize feedback that adds value. **Skip minor style nitpicks.**

| Priority | Focus Area | What to Check |
|----------|------------|---------------|
| 1 | Error handling & edge cases | Specific exceptions, recovery paths, boundary conditions |
| 2 | Code maintainability & clarity | Readability, naming, complexity, single responsibility |
| 3 | Consistency with codebase patterns | Does it match how similar code is written? |
| 4 | Performance issues | N+1 queries, unbounded operations, memory leaks |
| 5 | Security concerns | Injection, secrets, auth, multi-tenancy scoping |
| 6 | Documentation gaps | Missing docs for public APIs or complex logic |

## Review Checklist

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

1. **Context analysis first** - understand the codebase before nitpicking
2. **Minimum 5 findings** before any approval
3. **Three-phase workflow**: Context → Review → Format
4. **Anti-rubber-stamp**: Never just "LGTM" - provide substantive feedback
5. **No positive comments**: Only actionable feedback, no praise

For trivial changes (<10 lines, typos, config), document why fewer than 5 findings.

---

## Review Output Format

### For GitHub PRs (saved to file)

```markdown
# PR Review: wiliot/$PROJECT_NAME#$PR_NUMBER

## Context Summary

- **What this PR accomplishes**: [Description of what the PR does]
- **Architecture fit**: [How it fits into the repo's architecture]
- **Relevant patterns**: [Patterns/conventions from the codebase]

## Jira Ticket Context (if available)

**Ticket**: <TICKET_KEY>
**Summary**: <ticket summary>
**Status**: <ticket status>

### Ticket Alignment Check

- [ ] PR implements what the ticket describes
- [ ] Acceptance criteria addressed
- [ ] Scope is appropriate

---

## Review Comments

File: path/to/file.py
Line: 42
Severity: CRITICAL
Comment: Missing timeout on API call. This could hang indefinitely if the external service is slow. Add `timeout=30` parameter to the requests call.

File: path/to/file.py
Line: 89
Severity: IMPORTANT
Comment: No type hint on return value. Add `-> dict[str, Any]` to improve IDE support and catch type errors at development time.

File: path/to/file.py
Line: 67
Severity: SUGGESTION
Comment: Variable name `x` is not descriptive. Consider renaming to `user_count` based on the context of how it's used.

---

## Verdict

**Status**: [APPROVED | CHANGES_REQUIRED]
**Blocking Issues**: X critical, Y important
**Rationale**: [Why approved or what must change]
```

### For Local Reviews (displayed directly)

```markdown
# Code Review

## Context Summary

- **What these changes accomplish**: [Description]
- **Architecture fit**: [How changes fit the codebase]
- **Relevant patterns**: [Patterns that should be followed]

## Review Comments

File: path/to/file.py
Line: 42
Severity: CRITICAL
Comment: [Issue description and suggested fix]

File: path/to/file.py
Line: 15
Severity: IMPORTANT
Comment: [Issue description and suggested fix]

File: path/to/file.py
Line: 100
Severity: SUGGESTION
Comment: [Issue description and suggested fix]

## Verdict

**Status**: [APPROVED | CHANGES_REQUIRED]
**Blocking Issues**: X critical, Y important
```

---

## Severity Levels

- **CRITICAL**: Bugs, security issues, data loss risks - must fix before merge
- **IMPORTANT**: Types, error handling, performance - should fix before merge
- **SUGGESTION**: Minor improvements - nice to have but don't block merge

## Cleanup (for GitHub PR reviews using worktree)

After the review is complete (submitted or cancelled), clean up the worktree:

```bash
if [ -n "$WORKTREE_PATH" ]; then
    cd $PROJECT_NAME  # Return to main repo
    git worktree remove "$WORKTREE_PATH" 2>/dev/null || true
fi
```

## Important Notes

- **Context first**: Understand the codebase before reviewing
- **Be genuinely critical**: The goal is to catch real issues
- **Read full file context**: Not just the diff
- **Check patterns**: Look at existing code to ensure consistency
- **No positive comments**: Only actionable feedback
- **Skip nitpicks**: Focus on issues that actually matter
- When using worktree, read files from `$WORKTREE_PATH`
