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

| Command | Description |
|---------|-------------|
| `/pr:review` | Review PRs or local changes against develop branch |
| `/pr:fix` | Fix PR review comments (from local file + GitHub) |
| `/pr:review-loop` | Iterative review-fix loop until no blocking issues |
| `/specify` | Create feature specifications from natural language |
| `/plan` | Generate implementation plans |
| `/tasks` | Generate task lists from specs |
| `/clarify` | Identify underspecified areas in specs |
| `/analyze` | Cross-artifact consistency analysis |
| `/constitution` | Manage project coding principles |

### Feature Development Workflow (`.specify/`)

Scaffolding templates for structured feature development:

```
/specify "add user authentication"
    ↓
/clarify (ask clarifying questions)
    ↓
/plan (generate implementation plan)
    ↓
/tasks (create task checklist)
    ↓
/implement (execute tasks)
```

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
