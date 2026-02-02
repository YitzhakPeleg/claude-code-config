---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

1. Run `.specify/scripts/bash/check-prerequisites.sh --json` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute.
2. Load and analyze available design documents:
   - Always read plan.md for tech stack and libraries
   - IF EXISTS: Read data-model.md for entities
   - IF EXISTS: Read contracts/ for API endpoints
   - IF EXISTS: Read research.md for technical decisions
   - IF EXISTS: Read quickstart.md for test scenarios

   Note: Not all projects have all documents. For example:
   - CLI tools might not have contracts/
   - Simple libraries might not need data-model.md
   - Generate tasks based on what's available

3. Generate tasks following the template:
   - Use `.specify/templates/tasks-template.md` as the base
   - Replace example tasks with actual tasks based on:
     * **Setup tasks**: Project init, dependencies, linting
     * **Test tasks [P]**: One per contract, one per integration scenario
     * **Core tasks**: One per entity, service, CLI command, endpoint
     * **Integration tasks**: DB connections, middleware, logging
     * **Polish tasks [P]**: Unit tests, performance, docs

4. Task generation rules:
   - Each contract file → contract test task marked [P]
   - Each entity in data-model → model creation task marked [P]
   - Each endpoint → implementation task (not parallel if shared files)
   - Each user story → integration test marked [P]
   - Different files = can be parallel [P]
   - Same file = sequential (no [P])

5. Order tasks by dependencies:
   - Setup before everything
   - Tests before implementation (TDD)
   - Models before services
   - Services before endpoints
   - Core before integration
   - Everything before polish

6. Include parallel execution examples:
   - Group [P] tasks that can run together
   - Show actual Task agent commands

7. Create FEATURE_DIR/tasks.md with:
   - Correct feature name from implementation plan
   - Numbered tasks (T001, T002, etc.)
   - **Story point estimates** for each task using `[Xpt]` format
   - Clear file paths for each task
   - Dependency notes
   - Parallel execution guidance

8. **Create sub-tasks in tracking system**:

   After generating tasks.md, create sub-tasks for each task:

   a. Detect tracking backend:

   ```bash
   BACKEND=$(.specify/scripts/bash/detect-tracking-backend.sh)
   ```

   b. Extract parent ticket from branch name:

   ```bash
   BRANCH=$(git rev-parse --abbrev-ref HEAD)
   # Branch format: CLDS-1234-feature-name or #123-feature-name
   PARENT_TICKET=$(echo "$BRANCH" | grep -oE '^[A-Z]+-[0-9]+' || echo "")
   PARENT_ISSUE=$(echo "$BRANCH" | grep -oE '^#[0-9]+' | tr -d '#' || echo "")
   ```

   c. For each task in tasks.md, create sub-task:

   **If BACKEND == "jira" and PARENT_TICKET exists**:

   ```bash
   # Extract project key from parent ticket (e.g., CLDS from CLDS-1234)
   PROJECT=$(echo "$PARENT_TICKET" | grep -oE '^[A-Z]+')

   # For each task line like: "- [ ] T001 [2pt] [P] Create project structure"
   acli jira workitem create \
     --project "$PROJECT" \
     --type "Sub-task" \
     --parent "$PARENT_TICKET" \
     --summary "T001: Create project structure" \
     --json | jq -r '.key'
   # Returns: CLDS-1235
   ```

   **If BACKEND == "github" and PARENT_ISSUE exists**:

   ```bash
   gh issue create \
     --title "T001: Create project structure" \
     --body "Part of #$PARENT_ISSUE - Story points: 2pt" \
     --label "sub-task"
   # Returns: issue number
   ```

   d. Update tasks.md with tracking IDs:

   ```markdown
   - [ ] T001 [2pt] [P] [CLDS-1235] Create project structure
   - [ ] T002 [3pt] [#46] Initialize project with dependencies
   ```

9. Append tracking summary to tasks.md:

   ```markdown
   ## Tracking Summary

   - **Backend**: jira|github|none
   - **Parent**: CLDS-1234 | #123
   - **Sub-tasks created**: X
   - **Total story points**: Ypt

   | Task | Tracking ID | Points |
   | ---- | ----------- | ------ |
   | T001 | CLDS-1235 | 2pt |
   | ... | ... | ... |
   ```

Context for task generation: $ARGUMENTS

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.
