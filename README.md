# Claude Code Configuration

Personal Claude Code configuration for Python backend development with async patterns, LangGraph multi-agent systems, and FastAPI.

## What's Included

### Skills (`skills/`)

| Skill | Description |
|-------|-------------|
| `python-developer` | Python 3.12+ patterns: async/await, FastAPI, Pydantic v2, SQLAlchemy, LangGraph |
| `python-reviewer` | Code review checklist with severity levels (Critical/Important/Suggestion) |
| `acli-jira` | Atlassian CLI commands for Jira ticket management |
| `wilibot-backend-mcp-team-guide` | Team coding standards and conventions |

### Commands (`commands/`)

#### Main Commands

| Command | Description |
|---------|-------------|
| `/feature` | **End-to-end feature development** - from idea to code |
| `/pr:review` | Review PRs or local changes |
| `/pr:fix` | Fix PR review comments |
| `/pr:review-loop` | Iterative review-fix loop |

#### Feature Sub-Commands

These are called by `/feature` but can be run individually:

| Command | Description |
|---------|-------------|
| `/feature:specify` | Create feature specification |
| `/feature:clarify` | Fill gaps in specification |
| `/feature:plan` | Generate technical design |
| `/feature:tasks` | Create task checklist |
| `/feature:analyze` | Consistency check |
| `/feature:implement` | Execute tasks |
| `/feature:constitution` | Manage project principles |

### Feature Development Workflow

Single command to go from idea to implementation:

```bash
/feature "add user authentication with JWT"
```

This runs the full workflow with checkpoints:

```
/feature "add user auth"
    │
    ├─► Specify   → spec.md created
    ├─► Clarify   → gaps filled
    ├─► Plan      → technical design
    ├─► Tasks     → actionable checklist
    ├─► Analyze   → consistency check
    └─► Implement → code written
```

Use `--quick` to skip confirmations: `/feature --quick "add auth"`

### Hooks (`hooks/`)

- `play_sound.sh` - Terminal bell on prompt submission

## Installation

Copy to your project root or home directory:

```bash
# Clone this repo
git clone git@github.com:YitzhakPeleg/claude-code-config.git

# Copy to your project
cp -r claude-code-config/.claude /path/to/your/project/

# Or copy to home for global use
cp -r claude-code-config/.claude ~/
```

## Key Features

### Code Review System

The `/pr:review` command provides:
- Multi-level severity (Critical/Important/Suggestion)
- Security checks (SQL injection, secrets, multi-tenancy)
- Async correctness validation
- Type hint verification
- Jira ticket alignment checking

### Python Standards Enforced

- Modern type hints (`X | None` not `Optional[X]`)
- Async patterns (no blocking calls in async context)
- Error handling (specific exceptions, proper chaining)
- Multi-tenancy (`owner_id` scoping on all queries)
- Function limits (<50 lines, <4 parameters, <3 nesting levels)

## Customization

### Local Settings

Create `settings.local.json` (gitignored) for personal permission overrides:

```json
{
  "permissions": {
    "allow": ["Bash", "Edit", "Read", "Write"],
    "deny": [],
    "ask": []
  }
}
```

### Adding Skills

Create a new skill in `skills/<skill-name>/SKILL.md`:

```markdown
---
name: my-skill
description: What this skill does
---

# My Skill

Instructions for Claude...
```

## License

MIT
