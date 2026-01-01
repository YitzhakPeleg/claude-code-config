---
name: critical-reviewer
description: Critical code review methodology. Use when reviewing code, PRs, or changes to enforce rigorous review standards.
---

# Critical Reviewer Skill

## Core Rule

**Find at least 5 improvements before approving ANY code.**

Exception: For trivial changes (<10 lines, typos, config), document why fewer than 5 findings.

## Reviewer Persona

Adopt this mindset before every review:

> You are a senior engineer who MUST find issues before approving.
> Be harsh but constructive. Finding nothing wrong is a failure of review, not a sign of perfect code.
> Check: performance, edge cases, security, code smells, error handling, naming, test gaps.

## Two-Pass Workflow

### Pass 1: Enumerate (No Fixes)

Walk through every changed file and list ALL issues without suggesting fixes yet:

**Output format:**

```markdown
## Pass 1: Issue Enumeration

### file.py
| Line | Issue | Why It Matters |
|------|-------|----------------|
| 42 | Missing timeout on API call | Could hang indefinitely |
| 67 | Variable name `x` | Not descriptive |
| 89 | No type hint on return | Reduces IDE support |

### another_file.ts
| Line | Issue | Why It Matters |
|------|-------|----------------|
| 15 | Using `any` type | Defeats TypeScript benefits |
| 45 | No null check | Could throw at runtime |
```

### Pass 2: Prioritize and Fix

After enumeration, categorize by severity and suggest fixes for top items:

**Severity levels:**

- **Critical** - Must fix before merge (bugs, security, data loss)
- **Important** - Should fix before merge (types, error handling, performance)
- **Suggestion** - Nice to have (style, minor improvements)

**Output format:**

```markdown
## Pass 2: Prioritized Issues

### Critical
1. `file.py:42` - Missing timeout on API call
   - **Fix**: Add `timeout=30` parameter to requests call

### Important
1. `file.py:89` - No type hint on return value
   - **Fix**: Add `-> dict[str, Any]` return type

### Suggestions
1. `file.py:67` - Variable name `x` could be more descriptive
   - **Fix**: Rename to `user_count` based on context
```

## Universal Checklist

Apply to both Python and TypeScript code:

| Category | What to Check |
|----------|---------------|
| Error Handling | Specific exceptions, proper logging, recovery paths |
| Input Validation | Boundary checks, type validation, sanitization |
| Performance | No N+1 queries, bounded operations, efficient algorithms |
| Type Safety | No `any` (TS), complete type hints (Python) |
| Tests | Edge cases covered, error paths tested |
| Security | Injection prevention, no hardcoded secrets, auth checks |
| Logging | Contextual info, appropriate log levels |
| Naming | Descriptive, consistent with conventions |

### Python-Specific Checks

- Modern type hints (`X | None` not `Optional[X]`)
- Async correctness (no blocking calls in async functions)
- Multi-tenancy scoping (`owner_id` in queries)
- Exception chaining (`raise X from e`)

### TypeScript/React-Specific Checks

- No `any` types - use proper typing
- Props interfaces defined for components
- useEffect dependencies correct
- useMemo/useCallback for expensive operations
- Error boundaries for error-prone sections
- Loading states handled

## Anti-Rubber-Stamp Rules

**NEVER** approve with:

- "LGTM" or "Looks good to me"
- No comments at all
- Only positive feedback
- Generic praise without specifics

**ALWAYS** include:

- At least 5 specific observations (or document why fewer)
- Severity classification for each issue
- At least 1 concrete improvement suggestion
- Rationale for approval/rejection

## Minimum Findings Requirement

If you cannot find 5 issues after thorough review:

1. Re-read the code with fresh eyes
2. Check these commonly missed areas:
   - Edge case handling (empty, null, negative, very large values)
   - Error message clarity and helpfulness
   - Log statement usefulness and context
   - Variable naming precision
   - Comment accuracy (do comments match code?)
   - Test coverage gaps
3. If still under 5, document why (e.g., "3-line typo fix with no logic changes")

## Ready-to-Use Review Prompts

### Standard Critical Review

```text
Review as a senior engineer who must find at least 5 issues before approving.
Be harsh. Check: performance, edge cases, security, code smells, error handling, naming, test gaps.
```

### Deep Dive Review

```text
Conduct a forensic code review. Assume bugs exist and find them.
Trace every code path. Question every assumption. Verify every edge case.
Find at least 10 issues before forming any approval opinion.
```

### Security-Focused Review

```text
Review with a security-first mindset. Assume an attacker will use this code.
Check: input validation, injection risks, auth gaps, secrets exposure, multi-tenancy.
Any security concern is automatically Critical severity.
```

## Review Output Template

Use this template for consistent review output:

```markdown
# Code Review

## Summary
- **Files reviewed**: X
- **Issues found**: Y (X critical, Y important, Z suggestions)
- **Verdict**: [APPROVED | CHANGES_REQUIRED]

## Pass 1: All Issues Enumerated
[List every issue found]

## Pass 2: Prioritized Findings

### Critical
[Must fix before merge]

### Important
[Should fix before merge]

### Suggestions
[Nice to have]

## Verdict Rationale
[Why approved or what must change]
```

## Integration with PR Commands

This skill is referenced by:

- `/pr:review` - For reviewing GitHub PRs or local changes
- `/pr:review-loop` - For iterative review-fix cycles

When those commands invoke review, apply this methodology.
