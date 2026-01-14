#!/usr/bin/env bash
# Detect whether to use Jira or GitHub Issues based on git remote
#
# Returns:
#   "jira"   - For Wiliot organization repos (use acli)
#   "github" - For personal repos (use gh CLI)
#   "none"   - No git remote detected
#
# Usage:
#   BACKEND=$(detect-tracking-backend.sh)
#   if [[ "$BACKEND" == "jira" ]]; then
#       # Use acli jira workitem ...
#   elif [[ "$BACKEND" == "github" ]]; then
#       # Use gh issue ...
#   fi

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Known Wiliot organization patterns in git remotes
WILIOT_PATTERNS=(
    "wiliot"
    "Wiliot"
    "wiliot-com"
)

# Known personal GitHub patterns (add more as needed)
PERSONAL_PATTERNS=(
    "YitzhakPeleg"
    "yitzhak-peleg"
    "yitzhakp"
)

detect_tracking_backend() {
    local remote_url=""

    # Try to get git remote origin URL
    if ! git remote get-url origin >/dev/null 2>&1; then
        echo "none"
        return 0
    fi

    remote_url=$(git remote get-url origin)

    # Check for Wiliot patterns
    for pattern in "${WILIOT_PATTERNS[@]}"; do
        if [[ "$remote_url" == *"$pattern"* ]]; then
            echo "jira"
            return 0
        fi
    done

    # Check for personal patterns (explicitly)
    for pattern in "${PERSONAL_PATTERNS[@]}"; do
        if [[ "$remote_url" == *"$pattern"* ]]; then
            echo "github"
            return 0
        fi
    done

    # Default: if it's GitHub but not Wiliot, assume personal
    if [[ "$remote_url" == *"github.com"* ]] || [[ "$remote_url" == *"github-"* ]]; then
        echo "github"
        return 0
    fi

    # Default: if it's a corporate domain, assume Jira
    if [[ "$remote_url" == *"gitlab"* ]] || [[ "$remote_url" == *"bitbucket"* ]]; then
        echo "jira"
        return 0
    fi

    # Fallback
    echo "none"
}

# JSON output mode for integration with other tools
json_output() {
    local backend=$(detect_tracking_backend)
    local remote_url=""

    if git remote get-url origin >/dev/null 2>&1; then
        remote_url=$(git remote get-url origin)
    fi

    cat <<EOF
{
  "backend": "$backend",
  "remote_url": "$remote_url",
  "detection_method": "pattern_matching"
}
EOF
}

# Main execution
main() {
    local json_mode=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                json_mode=true
                shift
                ;;
            --help|-h)
                echo "Usage: detect-tracking-backend.sh [--json]"
                echo ""
                echo "Detects whether to use Jira or GitHub Issues for tracking."
                echo ""
                echo "Options:"
                echo "  --json    Output in JSON format"
                echo "  --help    Show this help message"
                echo ""
                echo "Returns:"
                echo "  jira      Use acli jira workitem commands"
                echo "  github    Use gh issue commands"
                echo "  none      No git remote detected"
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done

    if [[ "$json_mode" == "true" ]]; then
        json_output
    else
        detect_tracking_backend
    fi
}

main "$@"
