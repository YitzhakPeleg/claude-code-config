---
description: Create or update the feature specification from a natural language feature description.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

The text the user typed after `/specify` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `$ARGUMENTS` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

Given that feature description, do this:

**Step 1: Determine Project**

Automatically determine which project this feature belongs to using these heuristics (in order):

a. **IDE Context** (highest priority):
   - Check for `<ide_opened_file>` tags in the conversation
   - If files are open like `/workspace/{PROJECT_NAME}/...`, extract PROJECT_NAME
   - Skip if path is `.claude` or `.devcontainer`
   - This indicates user is actively working in that project

b. **Working Directory**:
   - Run `pwd` to get current directory
   - If it shows `/workspace/{PROJECT_NAME}` or `/workspace/{PROJECT_NAME}/*`, extract PROJECT_NAME
   - Skip if in `/workspace/.claude` or `/workspace/.devcontainer`

c. **Git Context**:
   - If current directory has `.git`, use `git rev-parse --show-toplevel` to find project root
   - Extract PROJECT_NAME from the path

d. **Ask User** (only if unable to determine):
   - List available projects: `ls -d /workspace/*/ | grep -v ".claude\|.devcontainer" | xargs -n1 basename`
   - Present to user:
     ```
     I couldn't determine which project this feature is for.

     Available projects:
     [list projects here]

     Which project should I use?
     ```

e. **Validate**: Confirm the project exists in `/workspace/{PROJECT_NAME}/`

**Important**: When auto-detected, inform the user: "Detected project: {PROJECT_NAME} (from {source})"

**Step 2: Determine Branch Name**

Then, ask the user for their preferred branch name format:

a. Present to the user:
   ```
   Please provide a branch/folder name for this feature.

   Supported formats:
   1. Ticket-based: CLDS-1234-feature-name (recommended if you have a Jira ticket)
   2. Sequential: 005-feature-name (auto-numbered based on existing specs in {PROJECT})
   3. Auto-generate (press Enter to use: NNN-first-three-words from description)

   Enter your choice:
   ```

b. If user provides a custom name:
   - Validate format matches one of:
     - Ticket-based: `[A-Z]+-[0-9]+-feature-name` (e.g., `CLDS-1234-auth-system`)
     - Sequential: `NNN-feature-name` (e.g., `005-auth-system`)
   - If invalid format, explain the requirement and ask again
   - Use the validated custom name for the next step

c. If user chooses auto-generate or presses Enter:
   - Generate branch name from feature description:
     - Convert to lowercase, replace non-alphanumeric with hyphens
     - Take first 3 meaningful words
     - Determine next sequential number by checking existing specs/ directory in the project
     - Format as: `NNN-first-three-words` (e.g., `005-create-auth-system`)

**Step 3: Create Feature Structure**

1. Run the appropriate script command (all commands use the shared .specify directory):
   - If using suggested name: `/workspace/.claude/.specify/scripts/bash/create-new-feature.sh --json --project=PROJECT_NAME "$ARGUMENTS"`
   - If using custom name: `/workspace/.claude/.specify/scripts/bash/create-new-feature.sh --json --project=PROJECT_NAME --custom-name=USER_PROVIDED_NAME "$ARGUMENTS"`

   Parse JSON output for PROJECT, BRANCH_NAME and SPEC_FILE. All file paths must be absolute.
   **IMPORTANT** You must only ever run this script once. The JSON is provided in the terminal as output - always refer to it to get the actual content you're looking for.

2. Load `/workspace/.claude/.specify/templates/spec-template.md` to understand required sections.

3. Write the specification to SPEC_FILE using the template structure, replacing placeholders with concrete details derived from the feature description (arguments) while preserving section order and headings.

4. Report completion with project name, branch name, spec file path, and readiness for the next phase.

Note: The script creates and checks out the new branch (if git is available) and initializes the spec file in the project's specs/ directory before writing.
