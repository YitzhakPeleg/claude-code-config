---
name: gh-cli
description: GitHub CLI (gh) for repository, PR, and issue operations. Use when creating PRs, reviewing code, managing issues, or interacting with GitHub from the command line.
---

# GitHub CLI (gh) - Reference

The GitHub CLI (`gh`) provides command-line access to GitHub. Authentication is handled via OAuth (`gh auth login`).

## Command Structure

```
gh <command> <subcommand> [flags]
```

**Commands**: `pr`, `issue`, `repo`, `api`, `release`, `workflow`, `auth`

**Cross-repo flag**: Use `-R owner/repo` to operate on a different repository.

---

## Authentication

### Check Auth Status

```bash
gh auth status
```

### Login

```bash
# Interactive OAuth login
gh auth login

# Login with token
gh auth login --with-token < token.txt
```

### Multi-Account Switching

For users with multiple GitHub accounts (company + personal):

```bash
# Switch to specific account
gh auth switch --user company-handle

# List authenticated accounts
gh auth status
```

---

## Repository Context Detection

Before PR/issue operations, detect the current repository context using the helper script:

### Using the Helper Script

```bash
# Source the script to get context variables
source .claude/scripts/gh-repo-context.sh

# Available variables after sourcing:
echo "Owner: $REPO_OWNER"          # e.g., "wiliot"
echo "Repo: $REPO_NAME"            # e.g., "wilibot-backend-python"
echo "Full: $REPO_FULL"            # e.g., "wiliot/wilibot-backend-python"
echo "Default branch: $DEFAULT_BRANCH"  # e.g., "develop"
```

### With Account Switching

```bash
# Set account handles, then source
COMPANY_HANDLE="wiliot" PERSONAL_HANDLE="myuser" source .claude/scripts/gh-repo-context.sh
# Automatically switches to correct account based on repo owner
```

### Manual Context Detection

```bash
# Get repo info as JSON
gh repo view --json owner,name,defaultBranchRef

# Extract specific values
REPO_OWNER=$(gh repo view --json owner -q '.owner.login')
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name')
```

---

## Pull Request Operations

### View PR

```bash
# Basic view
gh pr view 123

# View PR in different repo
gh pr view 123 -R owner/repo

# JSON output with specific fields
gh pr view 123 --json number,title,body,headRefName,baseRefName,additions,deletions,changedFiles

# Extract single field with --jq
gh pr view 123 --json headRefName -q '.headRefName'

# Open in browser
gh pr view 123 --web
```

**Flags**:
| Flag | Description |
|------|-------------|
| `-R`, `--repo` | Repository in `owner/repo` format |
| `--json` | Output specific fields as JSON |
| `-q`, `--jq` | Filter JSON output using jq syntax |
| `--web`, `-w` | Open in web browser |

**Common JSON fields**: `number`, `title`, `body`, `state`, `url`, `headRefName`, `baseRefName`, `additions`, `deletions`, `changedFiles`, `author`, `mergeable`, `reviewDecision`

---

### Create PR

```bash
# Basic PR creation
gh pr create --title "Add feature X" --body "Description here" --base develop

# Using heredoc for multi-line body
gh pr create --title "[CLDS-123] Add feature X" --body "$(cat <<'EOF'
## Problem
Users cannot reset passwords.

## Solution
Added password reset flow with email verification.

---
(by Claude Code)
EOF
)"

# Create draft PR
gh pr create --title "WIP: Feature X" --body "..." --draft

# Assign reviewers
gh pr create --title "..." --body "..." --reviewer user1,user2
```

**Flags**:
| Flag | Description |
|------|-------------|
| `--title`, `-t` | PR title - **required** |
| `--body`, `-b` | PR description |
| `--base`, `-B` | Base branch (default: repo default branch) |
| `--head`, `-H` | Head branch (default: current branch) |
| `--draft`, `-d` | Create as draft PR |
| `--reviewer`, `-r` | Comma-separated reviewers |
| `--assignee`, `-a` | Comma-separated assignees |
| `--label`, `-l` | Comma-separated labels |

**Output**: Returns the PR URL

---

### Checkout PR Branch

```bash
# Checkout PR branch locally
gh pr checkout 123

# Checkout from different repo
gh pr checkout 123 -R owner/repo
```

---

### Diff and Changed Files

```bash
# View full diff
gh pr diff 123

# List changed files only
gh pr diff 123 --name-only

# Diff from different repo
gh pr diff 123 -R owner/repo
```

---

### Comment on PR

#### PR-Level Comment

```bash
# Add comment to PR
gh pr comment 123 --body "Comment text here

(by Claude Code)"

# Comment on different repo
gh pr comment 123 -R owner/repo --body "..."
```

#### Line-Level Comment (via API)

```bash
# Get the latest commit SHA first
COMMIT_SHA=$(gh pr view 123 --json headRefOid -q '.headRefOid')

# Add line-level comment
gh api repos/owner/repo/pulls/123/comments \
  -f body="Issue: Missing null check here.

(by Claude Code)" \
  -f commit_id="$COMMIT_SHA" \
  -f path="src/file.py" \
  -F line=42
```

**Line comment fields**:
| Field | Description |
|-------|-------------|
| `body` | Comment text |
| `commit_id` | SHA of the commit to comment on |
| `path` | File path relative to repo root |
| `line` | Line number (use `-F` for integers) |
| `side` | `LEFT` or `RIGHT` for diff side |

---

### Reply to Review Comment

```bash
# Reply to an existing comment
gh api repos/owner/repo/pulls/123/comments/COMMENT_ID/replies \
  -f body="Fixed: Added null check.

(by Claude Code)"
```

---

### Merge PR

```bash
# Merge with squash (recommended)
gh pr merge 123 --squash

# Enable auto-merge (merges when checks pass)
gh pr merge 123 --auto --squash

# Merge with specific commit message
gh pr merge 123 --squash --subject "feat: Add feature X" --body "Details..."

# Delete branch after merge
gh pr merge 123 --squash --delete-branch
```

**Flags**:
| Flag | Description |
|------|-------------|
| `--squash`, `-s` | Squash commits into one |
| `--merge`, `-m` | Create merge commit |
| `--rebase`, `-r` | Rebase and merge |
| `--auto` | Enable auto-merge when checks pass |
| `--delete-branch`, `-d` | Delete branch after merge |
| `--subject` | Commit subject for squash/merge |
| `--body` | Commit body for squash/merge |

---

### List PRs

```bash
# List open PRs
gh pr list

# List with filters
gh pr list --state open --author @me
gh pr list --state all --label "bug"
gh pr list --search "review:required"

# JSON output
gh pr list --json number,title,author --limit 20
```

**Flags**:
| Flag | Description |
|------|-------------|
| `--state` | `open`, `closed`, `merged`, `all` |
| `--author` | Filter by author (`@me` for self) |
| `--assignee` | Filter by assignee |
| `--label` | Filter by label |
| `--search` | GitHub search syntax |
| `--limit`, `-L` | Max results (default: 30) |

---

### PR Status

```bash
# Show status of your PRs
gh pr status
```

---

## Issue Operations

### Create Issue

```bash
# Basic issue creation
gh issue create --title "Bug: Login fails" --body "Steps to reproduce..."

# Capture issue number
ISSUE_NUM=$(gh issue create \
    --title "Feature: Password reset" \
    --body "Description here" \
    | grep -oE '[0-9]+$')
echo "Created issue #$ISSUE_NUM"
```

**Flags**:
| Flag | Description |
|------|-------------|
| `--title`, `-t` | Issue title - **required** |
| `--body`, `-b` | Issue description |
| `--assignee`, `-a` | Comma-separated assignees |
| `--label`, `-l` | Comma-separated labels |
| `--project`, `-p` | Add to project |
| `--milestone`, `-m` | Add to milestone |

---

### View Issue

```bash
# View issue
gh issue view 456

# JSON output
gh issue view 456 --json title,body,url,state,labels

# Open in browser
gh issue view 456 --web
```

---

### List Issues

```bash
# List open issues
gh issue list

# List with filters
gh issue list --assignee @me --state open
gh issue list --label "bug,urgent"
gh issue list --search "is:open label:bug"

# JSON output for scripting
gh issue list --json number,title,labels --limit 50
```

---

### Edit Issue

```bash
# Add labels
gh issue edit 456 --add-label "in-review"

# Remove labels
gh issue edit 456 --remove-label "in-progress"

# Change title
gh issue edit 456 --title "New title"

# Add assignee
gh issue edit 456 --add-assignee "username"
```

---

### Comment on Issue

```bash
gh issue comment 456 --body "Update: PR created.

(by Claude Code)"
```

---

## Repository Operations

### View Repository Info

```bash
# Get repo info
gh repo view

# JSON output
gh repo view --json nameWithOwner,defaultBranchRef

# Get specific field
gh repo view --json nameWithOwner -q '.nameWithOwner'
```

---

### Clone Repository

```bash
# Clone repo
gh repo clone owner/repo

# Clone to specific directory
gh repo clone owner/repo ./my-directory
```

---

## API Operations (Advanced)

### REST API Calls

```bash
# GET request
gh api repos/owner/repo/pulls/123

# GET with jq filter
gh api repos/owner/repo/pulls/123/comments \
  --jq '.[] | select(.in_reply_to_id == null) | {id, path, line, body}'

# POST request (use -f for strings, -F for non-strings)
gh api repos/owner/repo/issues \
  -f title="New issue" \
  -f body="Description" \
  -F labels='["bug","urgent"]'

# PATCH request
gh api repos/owner/repo/issues/123 \
  -X PATCH \
  -f state="closed"

# DELETE request
gh api repos/owner/repo/issues/comments/456 -X DELETE
```

---

### GraphQL Queries

#### Get Review Threads (with resolution status)

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
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
}' -f owner="owner" -f repo="repo" -F pr=123
```

#### Resolve Review Thread

```bash
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread {
      id
      isResolved
    }
  }
}' -f threadId="PRRT_kwDOxxxxxxx"
```

#### Get PR with Full Details

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      number
      title
      body
      state
      mergeable
      reviewDecision
      author { login }
      headRefName
      baseRefName
      commits(last: 1) {
        nodes {
          commit { oid }
        }
      }
    }
  }
}' -f owner="owner" -f repo="repo" -F pr=123
```

**GraphQL Notes**:
- Use `-f` for string variables
- Use `-F` for integer/boolean variables
- Thread IDs start with `PRRT_` (PR Review Thread)
- Comment database IDs are integers, GraphQL IDs are strings

---

## Common Patterns

### PR Workflow with Jira Integration

```bash
#!/bin/bash
# Full PR workflow with ticket linking

# 1. Extract ticket from branch name
BRANCH=$(git branch --show-current)
TICKET=$(echo "$BRANCH" | grep -oE '^[A-Z]+-[0-9]+' || echo "")

# 2. Get base branch
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "develop")

# 3. Create PR
PR_URL=$(gh pr create \
  --title "[$TICKET] Feature description" \
  --body "Resolves $TICKET" \
  --base "$BASE_BRANCH")

# 4. Get PR number
PR_NUMBER=$(gh pr view --json number -q '.number')

# 5. Enable auto-merge
gh pr merge $PR_NUMBER --auto --squash

# 6. Link to Jira (if acli available)
if command -v acli &> /dev/null && [ -n "$TICKET" ]; then
  acli jira workitem comment create --key "$TICKET" --body "PR created: $PR_URL"
  acli jira workitem transition --key "$TICKET" --status "In Review" --yes
fi

echo "PR created: $PR_URL"
```

### Capture IDs for Scripting

```bash
# Capture PR number
PR_NUMBER=$(gh pr view --json number -q '.number')

# Capture PR URL
PR_URL=$(gh pr view --json url -q '.url')

# Capture head commit SHA
COMMIT_SHA=$(gh pr view 123 --json headRefOid -q '.headRefOid')

# Capture issue number from creation
ISSUE_NUM=$(gh issue create --title "..." --body "..." | grep -oE '[0-9]+$')

# List PR numbers
gh pr list --json number -q '.[].number'
```

### Filter Unresolved Review Comments

```bash
# Get only unresolved threads
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 1) {
            nodes { body path line }
          }
        }
      }
    }
  }
}' -f owner="owner" -f repo="repo" -F pr=123 \
  --jq '.data.repository.pullRequest.reviewThreads.nodes | map(select(.isResolved == false))'
```

### Bulk Operations Script

```bash
#!/bin/bash
# Close all stale PRs older than 90 days

gh pr list --state open --json number,createdAt --limit 100 | \
  jq -r '.[] | select(.createdAt < (now - 90*24*60*60 | todate)) | .number' | \
  while read pr; do
    echo "Closing PR #$pr"
    gh pr close $pr --comment "Closing due to inactivity.

(by Claude Code)"
  done
```

---

## Output Formats

| Flag | Format | Use Case |
|------|--------|----------|
| (none) | Table | Human-readable display |
| `--json` | JSON | Parsing with jq, automation |
| `--jq` / `-q` | Filtered JSON | Extract specific fields inline |
| `--web` | Browser | Open item in browser |

**JSON + jq examples**:
```bash
# Get single value
gh pr view 123 --json number -q '.number'

# Get nested value
gh pr view 123 --json author -q '.author.login'

# Filter array
gh pr list --json number,title -q '.[] | select(.title | contains("bug"))'

# Transform output
gh pr list --json number,title -q '.[] | "\(.number): \(.title)"'
```

---

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| "not authenticated" | No auth or expired | Run `gh auth login` |
| "Could not resolve to a Repository" | Wrong owner/repo | Check `-R owner/repo` format |
| "pull request not found" | Wrong PR number or no access | Verify PR exists and you have access |
| "GraphQL: Could not resolve to a PullRequest" | Wrong PR number in GraphQL | Check variable types (`-F` for int) |
| "HTTP 422: Validation Failed" | Invalid field value | Check required fields and formats |
| "HTTP 403: Resource not accessible" | Insufficient permissions | Check repo access and token scopes |

---

## Notes

- **Authentication**: `gh auth login` uses OAuth. Tokens are stored securely.
- **Check auth status**: `gh auth status`
- **Cross-repo operations**: Always use `-R owner/repo` for repos you're not in
- **Signature**: All automated comments should end with `(by Claude Code)`
- **JSON fields**: Use `gh <command> --help` to see available JSON fields
- **Rate limits**: GitHub API has rate limits. Use `--limit` to control batch sizes
- **Pagination**: Large result sets may be paginated. Use `--limit` or GraphQL for control
- **Draft PRs**: Use `--draft` for work-in-progress to prevent accidental merges
