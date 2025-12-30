# Code Review Workflow with GitHub CLI

## Overview
This document describes the process for conducting code reviews on GitHub PRs using the `gh` CLI tool.

## Prerequisites
- GitHub CLI (`gh`) authenticated: `gh auth login`
- Access to the repository

## Step-by-Step Process

### 1. Checkout the PR
```bash
cd /workspace/<repository-name>
gh pr checkout <PR_NUMBER>
```

### 2. Get PR Information
```bash
# View PR details and description
gh pr view <PR_NUMBER>

# View the full diff
gh pr diff <PR_NUMBER>
```

### 3. Analyze the Changes

**First, read the PR overview/description** to understand:
- What is the goal of this PR?
- What problem does it solve?
- What is the intended design/approach?

**Then review the code logic** for:
- Does the implementation match the PR description?
- Are there logic errors or edge cases not handled?
- Will the code actually work as intended?
- Are there potential runtime errors?

**Review for issues:**
- **Critical issues**: Bugs, security issues, infinite loops, breaking changes, logic errors
- **High priority issues**: Missing tests, undocumented behavior changes, architectural concerns
- **Nice to have**: Code style, refactoring suggestions (skip these in reviews)

### 4. Submit Inline Comments

**Key Principles:**
- ✅ Comment ONLY on lines that need changes
- ✅ Be concise - short, actionable comments
- ✅ Focus on critical and high-priority issues only
- ✅ Start each comment with bold "**Claude comment:**"
- ❌ Don't add summary comments or general feedback
- ❌ Don't comment on "nice to have" improvements
- ❌ Don't over-explain - developers know their code

**Process:**

1. Create a JSON file with inline comments:
```json
{
  "body": "",
  "event": "COMMENT",
  "comments": [
    {
      "path": "path/to/file.py",
      "line": 54,
      "body": "**Claude comment:** Remove debug print, use logger.debug() instead"
    },
    {
      "path": "path/to/another_file.py",
      "line": 246,
      "body": "**Claude comment:** Add circular delegation protection to prevent infinite loops"
    }
  ]
}
```

2. Submit the review:
```bash
gh api repos/<org>/<repo>/pulls/<PR_NUMBER>/reviews \
  --method POST \
  --input /path/to/review_comments.json
```

## Example

```bash
# 1. Checkout PR
cd /workspace/wilibot-backend-python
gh pr checkout 217

# 2. Review the changes
gh pr view 217
gh pr diff 217

# 3. Create review comments file
cat > /tmp/review_comments.json <<'EOF'
{
  "body": "",
  "event": "COMMENT",
  "comments": [
    {
      "path": "src/example.py",
      "line": 42,
      "body": "**Claude comment:** Fix memory leak here"
    }
  ]
}
EOF

# 4. Submit review
gh api repos/wiliot/wilibot-backend-python/pulls/217/reviews \
  --method POST \
  --input /tmp/review_comments.json
```

## Review Comment Guidelines

### ✅ Good Comments (Use These)
- "**Claude comment:** Remove debug print, use logger.debug() instead"
- "**Claude comment:** Add circular delegation protection to prevent infinite loops"
- "**Claude comment:** Document breaking change in return type"
- "**Claude comment:** Fix potential null pointer exception"
- "**Claude comment:** This logic doesn't handle the case when state.intent is None"
- "**Claude comment:** According to PR description, this should delegate to platform_ops first, but code shows network_troubleshooting"
- "**Claude comment:** Missing validation for empty agent list before iteration"

### ❌ Bad Comments (Avoid These)
- "Consider refactoring this for better readability" (nice to have)
- "Great job on this implementation! 🎉" (unnecessary praise)
- Long explanations about architecture (be concise)
- Style suggestions like variable naming (unless critical)

## Event Types
- `COMMENT` - General review comments (use this most often)
- `APPROVE` - Approve the PR
- `REQUEST_CHANGES` - Block merge until changes are made (use sparingly)

## Tips
- Keep comments short and actionable
- Only comment on things that MUST change
- Trust the developer - they know their code
- Focus on bugs, security, and breaking changes
- Skip style and "nice to have" improvements
- Always prefix with "**Claude comment:**" to identify automated reviews
