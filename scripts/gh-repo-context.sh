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

# Determine if script is being sourced or run directly
_GH_CONTEXT_SOURCED=false
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    _GH_CONTEXT_SOURCED=true
fi

# Error handler - exits script but not parent shell when sourced
_gh_context_error() {
    echo "ERROR: $1" >&2
    if [[ "$_GH_CONTEXT_SOURCED" == "true" ]]; then
        return 1
    else
        exit 1
    fi
}

# Only set strict mode when run directly (not sourced)
if [[ "$_GH_CONTEXT_SOURCED" == "false" ]]; then
    set -euo pipefail
fi

# Check for required dependencies
if ! command -v gh &> /dev/null; then
    _gh_context_error "gh CLI is required but not installed"
fi

if ! command -v jq &> /dev/null; then
    _gh_context_error "jq is required but not installed"
fi

# Get repository info
REPO_JSON=$(gh repo view --json owner,name,defaultBranchRef 2>/dev/null) || {
    _gh_context_error "Not in a git repository or gh not authenticated"
}

# Export context variables
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
if [[ "$_GH_CONTEXT_SOURCED" == "false" ]]; then
    echo "REPO_OWNER=$REPO_OWNER"
    echo "REPO_NAME=$REPO_NAME"
    echo "REPO_FULL=$REPO_FULL"
    echo "DEFAULT_BRANCH=$DEFAULT_BRANCH"
fi

# Cleanup internal variables
unset _GH_CONTEXT_SOURCED
