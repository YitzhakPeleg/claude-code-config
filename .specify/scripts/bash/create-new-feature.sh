#!/usr/bin/env bash

set -e

JSON_MODE=false
CUSTOM_NAME=""
PROJECT=""
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --custom-name=*) CUSTOM_NAME="${arg#*=}" ;;
        --project=*) PROJECT="${arg#*=}" ;;
        --help|-h)
            echo "Usage: $0 [--json] [--project=PROJECT_NAME] [--custom-name=TICKET-feature-name] <feature_description>"
            echo ""
            echo "Options:"
            echo "  --json                    Output in JSON format"
            echo "  --project=NAME            Specify project name (e.g., wiliot-mcp-python)"
            echo "  --custom-name=NAME        Use custom branch name (e.g., CLDS-1234-feature-name or 005-feature-name)"
            echo ""
            echo "Examples:"
            echo "  $0 --project=wiliot-mcp-python create authentication system"
            echo "  $0 --project=wilibot-backend-python --custom-name=CLDS-1234-auth-system create authentication system"
            echo "  $0 --project=wiliot-agentic-kit --custom-name=005-auth-system create authentication system"
            exit 0
            ;;
        *) ARGS+=("$arg") ;;
    esac
done

FEATURE_DESCRIPTION="${ARGS[*]}"
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "Usage: $0 [--json] [--project=PROJECT_NAME] [--custom-name=TICKET-feature-name] <feature_description>" >&2
    exit 1
fi

# Workspace root is the parent of .claude
WORKSPACE_ROOT="/workspace"

# If no project specified, list available projects and exit
if [ -z "$PROJECT" ]; then
    echo "Error: --project parameter is required" >&2
    echo "" >&2
    echo "Available projects:" >&2
    for dir in "$WORKSPACE_ROOT"/*; do
        if [ -d "$dir" ] && [ "$(basename "$dir")" != ".claude" ] && [ "$(basename "$dir")" != ".devcontainer" ]; then
            echo "  - $(basename "$dir")" >&2
        fi
    done
    echo "" >&2
    echo "Usage: $0 --project=PROJECT_NAME <feature_description>" >&2
    exit 1
fi

# Validate project exists
PROJECT_ROOT="$WORKSPACE_ROOT/$PROJECT"
if [ ! -d "$PROJECT_ROOT" ]; then
    echo "Error: Project '$PROJECT' not found in workspace" >&2
    echo "Available projects:" >&2
    for dir in "$WORKSPACE_ROOT"/*; do
        if [ -d "$dir" ] && [ "$(basename "$dir")" != ".claude" ] && [ "$(basename "$dir")" != ".devcontainer" ]; then
            echo "  - $(basename "$dir")" >&2
        fi
    done
    exit 1
fi

# Change to project directory
cd "$PROJECT_ROOT"

# Check if project has git
HAS_GIT=false
if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
    HAS_GIT=true
else
    REPO_ROOT="$PROJECT_ROOT"
fi

SPECS_DIR="$PROJECT_ROOT/specs"
mkdir -p "$SPECS_DIR"

HIGHEST=0
if [ -d "$SPECS_DIR" ]; then
    for dir in "$SPECS_DIR"/*; do
        [ -d "$dir" ] || continue
        dirname=$(basename "$dir")
        number=$(echo "$dirname" | grep -o '^[0-9]\+' || echo "0")
        number=$((10#$number))
        if [ "$number" -gt "$HIGHEST" ]; then HIGHEST=$number; fi
    done
fi

NEXT=$((HIGHEST + 1))
FEATURE_NUM=$(printf "%03d" "$NEXT")

# If custom name provided, validate and use it; otherwise auto-generate
if [ -n "$CUSTOM_NAME" ]; then
    # CRITICAL: Reject branch names containing slashes
    if echo "$CUSTOM_NAME" | grep -q '/'; then
        echo "Error: Branch names must NOT contain slashes (/)" >&2
        echo "       Slashes cause deployment issues and are forbidden." >&2
        echo "       Use format: TICKET-type-description (e.g., CLDS-1234-feature-name)" >&2
        exit 1
    fi

    # Validate custom name format - supports both:
    # - Ticket-based: CLDS-1234-feature-name, PROJ-999-feature-name
    # - Sequential: 001-feature-name, 005-feature-name
    if echo "$CUSTOM_NAME" | grep -qE '^[A-Z]+-[0-9]+-[a-z0-9-]+$'; then
        # Ticket-based format (e.g., CLDS-1234-feature-name)
        BRANCH_NAME="$CUSTOM_NAME"
        # Extract ticket ID as feature num for tracking
        FEATURE_NUM=$(echo "$CUSTOM_NAME" | grep -oE '^[A-Z]+-[0-9]+')
    elif echo "$CUSTOM_NAME" | grep -qE '^[0-9]{3}-[a-z0-9-]+$'; then
        # Sequential format (e.g., 005-feature-name)
        CUSTOM_NUM=$(echo "$CUSTOM_NAME" | grep -o '^[0-9]\+')
        CUSTOM_NUM=$((10#$CUSTOM_NUM))

        # Verify the number matches the next expected number
        if [ "$CUSTOM_NUM" -ne "$NEXT" ]; then
            echo "Warning: Custom name uses number $CUSTOM_NUM but next available is $NEXT" >&2
            echo "         Using custom number anyway. Make sure this is intentional." >&2
        fi

        BRANCH_NAME="$CUSTOM_NAME"
        FEATURE_NUM=$(printf "%03d" "$CUSTOM_NUM")
    else
        echo "Error: Custom name must match one of these formats:" >&2
        echo "       - Ticket-based: CLDS-1234-feature-name (e.g., CLDS-1234-auth-system)" >&2
        echo "       - Sequential: 005-feature-name (e.g., 005-auth-system)" >&2
        echo "       Feature name must contain only lowercase letters, numbers, and hyphens" >&2
        exit 1
    fi
else
    # Auto-generate branch name from description (sequential format)
    BRANCH_NAME=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//')
    WORDS=$(echo "$BRANCH_NAME" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//')
    BRANCH_NAME="${FEATURE_NUM}-${WORDS}"
fi

if [ "$HAS_GIT" = true ]; then
    git checkout -b "$BRANCH_NAME"
else
    >&2 echo "[specify] Warning: Git repository not detected; skipped branch creation for $BRANCH_NAME"
fi

FEATURE_DIR="$SPECS_DIR/$BRANCH_NAME"
mkdir -p "$FEATURE_DIR"

TEMPLATE="$WORKSPACE_ROOT/.claude/.specify/templates/spec-template.md"
SPEC_FILE="$FEATURE_DIR/spec.md"
if [ -f "$TEMPLATE" ]; then cp "$TEMPLATE" "$SPEC_FILE"; else touch "$SPEC_FILE"; fi

# Set the SPECIFY_FEATURE environment variable for the current session
export SPECIFY_FEATURE="$BRANCH_NAME"
export SPECIFY_PROJECT="$PROJECT"

if $JSON_MODE; then
    printf '{"PROJECT":"%s","BRANCH_NAME":"%s","SPEC_FILE":"%s","FEATURE_NUM":"%s"}\n' "$PROJECT" "$BRANCH_NAME" "$SPEC_FILE" "$FEATURE_NUM"
else
    echo "PROJECT: $PROJECT"
    echo "BRANCH_NAME: $BRANCH_NAME"
    echo "SPEC_FILE: $SPEC_FILE"
    echo "FEATURE_NUM: $FEATURE_NUM"
    echo "SPECIFY_FEATURE environment variable set to: $BRANCH_NAME"
    echo "SPECIFY_PROJECT environment variable set to: $PROJECT"
fi
