# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [Est] [P?] [Tracking] Description`

- **[ID]**: Task number (T001, T002, ...)
- **[Est]**: Story point estimate in brackets, e.g., `[2pt]`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Tracking]**: Jira sub-task or GitHub issue reference after creation
- Include exact file paths in descriptions

### Example Task Line

```markdown
- [ ] T001 [2pt] [P] Create project structure per implementation plan
- [ ] T002 [3pt] Initialize [language] project with [framework] dependencies
```

After sub-task creation:

```markdown
- [ ] T001 [2pt] [P] [CLDS-1234] Create project structure per implementation plan
- [ ] T002 [3pt] [#45] Initialize [language] project with [framework] dependencies
```

### Estimation Guidelines

| Points | Complexity | Example |
| ------ | ---------- | ------- |
| 1pt | Trivial | Config change, single-line fix |
| 2pt | Simple | Add a single function/method |
| 3pt | Moderate | New file with tests |
| 5pt | Complex | New module with integration |
| 8pt | Large | Multi-file refactor |

**Rule**: If estimate > 5pt, break into smaller tasks.

## Path Conventions
- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 3.1: Setup

- [ ] T001 [2pt] Create project structure per implementation plan
- [ ] T002 [3pt] Initialize [language] project with [framework] dependencies
- [ ] T003 [1pt] [P] Configure linting and formatting tools

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3

**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

- [ ] T004 [2pt] [P] Contract test POST /api/users in tests/contract/test_users_post.py
- [ ] T005 [2pt] [P] Contract test GET /api/users/{id} in tests/contract/test_users_get.py
- [ ] T006 [3pt] [P] Integration test user registration in tests/integration/test_registration.py
- [ ] T007 [3pt] [P] Integration test auth flow in tests/integration/test_auth.py

## Phase 3.3: Core Implementation (ONLY after tests are failing)

- [ ] T008 [2pt] [P] User model in src/models/user.py
- [ ] T009 [3pt] [P] UserService CRUD in src/services/user_service.py
- [ ] T010 [2pt] [P] CLI --create-user in src/cli/user_commands.py
- [ ] T011 [2pt] POST /api/users endpoint
- [ ] T012 [2pt] GET /api/users/{id} endpoint
- [ ] T013 [2pt] Input validation
- [ ] T014 [2pt] Error handling and logging

## Phase 3.4: Integration

- [ ] T015 [3pt] Connect UserService to DB
- [ ] T016 [3pt] Auth middleware
- [ ] T017 [2pt] Request/response logging
- [ ] T018 [2pt] CORS and security headers

## Phase 3.5: Polish

- [ ] T019 [2pt] [P] Unit tests for validation in tests/unit/test_validation.py
- [ ] T020 [2pt] Performance tests (<200ms)
- [ ] T021 [1pt] [P] Update docs/api.md
- [ ] T022 [2pt] Remove duplication
- [ ] T023 [1pt] Run manual-testing.md

## Dependencies
- Tests (T004-T007) before implementation (T008-T014)
- T008 blocks T009, T015
- T016 blocks T018
- Implementation before polish (T019-T023)

## Parallel Example
```
# Launch T004-T007 together:
Task: "Contract test POST /api/users in tests/contract/test_users_post.py"
Task: "Contract test GET /api/users/{id} in tests/contract/test_users_get.py"
Task: "Integration test registration in tests/integration/test_registration.py"
Task: "Integration test auth in tests/integration/test_auth.py"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - Each contract file → contract test task [P]
   - Each endpoint → implementation task
   
2. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks
   
3. **From User Stories**:
   - Each story → integration test [P]
   - Quickstart scenarios → validation tasks

4. **Ordering**:
   - Setup → Tests → Models → Services → Endpoints → Polish
   - Dependencies block parallel execution

## Validation Checklist

*GATE: Checked by main() before returning*

- [ ] All contracts have corresponding tests
- [ ] All entities have model tasks
- [ ] All tests come before implementation
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task
- [ ] All tasks have story point estimates

---

## Tracking Backend Integration

After generating tasks, the `/feature:tasks` command will automatically create sub-tasks in the appropriate tracking system.

### Backend Detection

Uses `detect-tracking-backend.sh` to determine:

| Remote Pattern | Backend | Tool |
| -------------- | ------- | ---- |
| Contains "wiliot" | Jira | `acli jira workitem create --parent` |
| Personal GitHub | GitHub Issues | `gh issue create` |
| No remote | None | Local tasks.md only |

### Sub-Task Creation

**For Jira (Wiliot repos)**:

```bash
acli jira workitem create \
  --project "CLDS" \
  --type "Sub-task" \
  --parent "$PARENT_TICKET" \
  --summary "T001: Create project structure"
```

**For GitHub Issues (Personal repos)**:

```bash
gh issue create \
  --title "T001: Create project structure" \
  --body "Part of #$PARENT_ISSUE - [2pt]" \
  --label "sub-task"
```

### Status Lifecycle

| Event | Jira Transition | GitHub Action |
| ----- | --------------- | ------------- |
| `/feature:implement` starts | → "In Progress" | Add "in-progress" label |
| `/pr:create` runs | → "In Review" | Add "in-review" label |
| PR merged | → "Done" | Close issue |

### Tracking Summary Section

After sub-task creation, a summary is appended:

```markdown
## Tracking Summary

- **Backend**: jira
- **Parent**: CLDS-1234
- **Sub-tasks created**: 23
- **Total story points**: 48pt

| Task | Tracking ID | Points |
| ---- | ----------- | ------ |
| T001 | CLDS-1235 | 2pt |
| T002 | CLDS-1236 | 3pt |
| ... | ... | ... |
```
