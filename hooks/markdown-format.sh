#!/bin/bash
# Hook to auto-format markdown files after Write/Edit operations
# Uses mdformat with GFM and tables plugins

# Read JSON input from stdin and extract file path
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Exit if no file path provided
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Only process markdown files
if [[ ! "$FILE_PATH" =~ \.(md|markdown)$ ]]; then
    exit 0
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Run mdformat with GFM and tables plugins
# Using --wrap=keep to preserve intentional line breaks
mdformat --wrap keep "$FILE_PATH" 2>/dev/null

# Exit successfully regardless of mdformat result
# (don't block the workflow if formatting fails)
exit 0
