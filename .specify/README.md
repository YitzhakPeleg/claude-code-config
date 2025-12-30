# Specify System - Multi-Project Support

This `.specify` directory is located at the workspace level (`/workspace/.claude/.specify/`) and provides shared specification tools and templates for all projects in the workspace.

## Structure

```
/workspace/.claude/.specify/
├── scripts/
│   └── bash/
│       ├── common.sh                    # Shared utility functions (multi-project aware)
│       ├── create-new-feature.sh        # Multi-project aware feature creation
│       ├── check-prerequisites.sh       # Validate feature setup and get paths
│       ├── setup-plan.sh                # Initialize plan.md from template
│       └── update-agent-context.sh      # Update AI agent context files
├── templates/
│   ├── spec-template.md                 # Feature specification template
│   ├── plan-template.md                 # Implementation plan template
│   ├── tasks-template.md                # Task breakdown template
│   └── agent-file-template.md           # AI agent context file template
└── README.md                            # This file
```

## Available Scripts

### common.sh
Shared utility functions used by all other scripts:
- `get_project_root()` - Detect project from SPECIFY_PROJECT env var or current directory
- `get_repo_root()` - Get repository root path
- `get_current_branch()` - Get current feature branch name
- `get_feature_paths()` - Export all feature-related paths
- `check_feature_branch()` - Validate feature branch naming

### create-new-feature.sh
Creates a new feature specification with proper directory structure and git branch.

### check-prerequisites.sh
Validates that required files exist and outputs feature paths. Supports `--json`, `--paths-only`, `--require-tasks`, and `--include-tasks` flags.

### setup-plan.sh
Initializes a plan.md file from the shared template in the current feature directory.

### update-agent-context.sh
Updates AI agent context files (CLAUDE.md, GEMINI.md, etc.) with information from plan.md. Supports all major AI coding assistants.

## How It Works

### Multi-Project Architecture

Each project in the workspace maintains its own `specs/` directory where feature specifications are stored:
- `/workspace/wiliot-mcp-python/specs/`
- `/workspace/wiliot-agentic-kit/specs/`
- `/workspace/wilibot-backend-python/specs/`

The shared `.specify` directory provides:
1. **Shared scripts** - Feature creation and management scripts
2. **Shared templates** - Consistent specification templates across all projects
3. **Centralized configuration** - Single source of truth for the specification system

### Usage

The `/specify` slash command uses these shared tools to:
1. Ask which project the feature belongs to
2. Create the appropriate branch (if git is available)
3. Create the spec folder in the project's `specs/` directory
4. Initialize the spec file from the shared template

### Script Usage

The main script supports multiple projects:

```bash
/workspace/.claude/.specify/scripts/bash/create-new-feature.sh \
  --json \
  --project=PROJECT_NAME \
  [--custom-name=BRANCH_NAME] \
  <feature_description>
```

**Options:**
- `--json`: Output in JSON format
- `--project=NAME`: Required. Specify which project (e.g., `wiliot-mcp-python`)
- `--custom-name=NAME`: Optional. Use custom branch name format:
  - Ticket-based: `CLDS-1234-feature-name`
  - Sequential: `005-feature-name`

**Examples:**
```bash
# Auto-generated sequential name
/workspace/.claude/.specify/scripts/bash/create-new-feature.sh \
  --json \
  --project=wiliot-mcp-python \
  create authentication system

# Custom ticket-based name
/workspace/.claude/.specify/scripts/bash/create-new-feature.sh \
  --json \
  --project=wiliot-agentic-kit \
  --custom-name=CLDS-1234-auth-system \
  create authentication system
```

### Output

The script creates:
1. A new git branch (if git is available) named according to the format
2. A directory in the project's `specs/` folder: `{PROJECT}/specs/{BRANCH_NAME}/`
3. A `spec.md` file initialized from the template

JSON output includes:
```json
{
  "PROJECT": "wiliot-mcp-python",
  "BRANCH_NAME": "001-create-auth-system",
  "SPEC_FILE": "/workspace/wiliot-mcp-python/specs/001-create-auth-system/spec.md",
  "FEATURE_NUM": "001"
}
```

## Benefits

1. **Consistency** - All projects use the same specification format and workflow
2. **Maintainability** - Single location to update templates and scripts
3. **Isolation** - Each project maintains its own specs while sharing tooling
4. **Scalability** - Easy to add new projects without duplicating specification infrastructure
