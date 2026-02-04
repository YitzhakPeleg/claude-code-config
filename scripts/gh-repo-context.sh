#!/bin/bash
# gh-repo-context.sh - Detect repository context and optionally switch accounts
#
# Usage:
#   source scripts/gh-repo-context.sh
#   # Then use: $REPO_OWNER, $REPO_NAME, $DEFAULT_BRANCH
#
# With account switching:
#   COMPANY_HANDLE="wiliot" PERSONAL_HANDLE="myuser" source scripts/gh-repo-context.sh
#
# Output variables:
#   REPO_OWNER      - Repository owner (org or user)
#   REPO_NAME       - Repository name
#   DEFAULT_BRANCH  - Default branch (main, develop, etc.)
#   REPO_FULL       - Full repo path (owner/name)

set -euo pipefail

# Check for required dependencies
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed" >&2
    exit 1
fi

# Get repository info
REPO_JSON=$(gh repo view --json owner,name,defaultBranchRef 2>/dev/null) || {
    echo "ERROR: Not in a git repository or gh not authenticated" >&2
    exit 1
}

# Export context variables (single jq call with multiple outputs)
export REPO_OWNER=$(echo "$REPO_JSON" | jq -r '.owner.login')
export REPO_NAME=$(echo "$REPO_JSON" | jq -r '.name')
export DEFAULT_BRANCH=$(echo "$REPO_JSON" | jq -r '.defaultBranchRef.name')
export REPO_FULL="${REPO_OWNER}/${REPO_NAME}"

# Account switching (optional)
# Set COMPANY_HANDLE and PERSONAL_HANDLE env vars to enable
if [[ -n "${COMPANY_HANDLE:-}" ]] && [[ -n "${PERSONAL_HANDLE:-}" ]]; then
    if [[ "$REPO_OWNER" == "$COMPANY_HANDLE" ]]; then
        if gh auth switch --user "$COMPANY_HANDLE" 2>/dev/null; then
            echo "AUTH: Switched to company account ($COMPANY_HANDLE)"
        fi
    else
        if gh auth switch --user "$PERSONAL_HANDLE" 2>/dev/null; then
            echo "AUTH: Switched to personal account ($PERSONAL_HANDLE)"
        fi
    fi
fi

# Output for non-sourced usage (when run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "REPO_OWNER=$REPO_OWNER"
    echo "REPO_NAME=$REPO_NAME"
    echo "REPO_FULL=$REPO_FULL"
    echo "DEFAULT_BRANCH=$DEFAULT_BRANCH"
fi
