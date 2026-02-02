#!/bin/bash
# PostToolUse hook: Run ruff lint after Python file edits
# Non-blocking (exit 0) - reports issues but doesn't stop Claude

set -uo pipefail  # No -e since we always exit 0

FILE_PATH="${CLAUDE_FILE_PATH:-}"

# Only process Python files
[[ "$FILE_PATH" != *.py ]] && exit 0

# Find project root (directory with Makefile)
find_project_root() {
    local dir="$1"
    while [[ "$dir" != "/" ]]; do
        [[ -f "$dir/Makefile" ]] && echo "$dir" && return 0
        dir=$(dirname "$dir")
    done
    return 1
}

PROJECT_ROOT=$(find_project_root "$(dirname "$FILE_PATH")")
[[ -z "$PROJECT_ROOT" ]] && exit 0

cd "$PROJECT_ROOT" || exit 0

# Run ruff directly (faster than make target)
echo "🔍 Checking: $(basename "$FILE_PATH")"
if [[ -f ".venv/bin/ruff" ]]; then
    .venv/bin/ruff check "$FILE_PATH" 2>&1 | head -20
elif command -v ruff &>/dev/null; then
    ruff check "$FILE_PATH" 2>&1 | head -20
fi

# Always exit 0 (non-blocking)
exit 0
