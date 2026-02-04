#!/bin/bash
# gh-repo-context.sh - Detect repository context and optionally switch accounts
#
# Usage:
#   source .claude/scripts/gh-repo-context.sh
#   # Then use: $REPO_OWNER, $REPO_NAME, $DEFAULT_BRANCH
#
# With account switching:
#   COMPANY_HANDLE="wiliot" PERSONAL_HANDLE="myuser" source .claude/scripts/gh-repo-context.sh
#
# Output variables:
#   REPO_OWNER      - Repository owner (org or user)
#   REPO_NAME       - Repository name
#   DEFAULT_BRANCH  - Default branch (main, develop, etc.)
#   REPO_FULL       - Full repo path (owner/name)

set -euo pipefail

# Get repository info
REPO_JSON=$(gh repo view --json owner,name,defaultBranchRef --jq '{owner: .owner.login, name: .name, branch: .defaultBranchRef.name}' 2>/dev/null) || {
    echo "ERROR: Not in a git repository or gh not authenticated" >&2
    exit 1
}

# Export context variables
export REPO_OWNER=$(echo "$REPO_JSON" | jq -r '.owner')
export REPO_NAME=$(echo "$REPO_JSON" | jq -r '.name')
export DEFAULT_BRANCH=$(echo "$REPO_JSON" | jq -r '.branch')
export REPO_FULL="${REPO_OWNER}/${REPO_NAME}"

# Account switching (optional)
# Set COMPANY_HANDLE and PERSONAL_HANDLE env vars to enable
if [[ -n "${COMPANY_HANDLE:-}" ]] && [[ -n "${PERSONAL_HANDLE:-}" ]]; then
    if [[ "$REPO_OWNER" == "$COMPANY_HANDLE" ]]; then
        gh auth switch --user "$COMPANY_HANDLE" 2>/dev/null || true
        echo "AUTH: Switched to company account ($COMPANY_HANDLE)" >&2
    else
        gh auth switch --user "$PERSONAL_HANDLE" 2>/dev/null || true
        echo "AUTH: Switched to personal account ($PERSONAL_HANDLE)" >&2
    fi
fi

# Output for non-sourced usage (when run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "REPO_OWNER=$REPO_OWNER"
    echo "REPO_NAME=$REPO_NAME"
    echo "REPO_FULL=$REPO_FULL"
    echo "DEFAULT_BRANCH=$DEFAULT_BRANCH"
fi
