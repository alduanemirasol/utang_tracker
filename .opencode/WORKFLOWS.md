# Agentic Development Team Workflows

Use the smallest workflow that can complete the task correctly.
Always inspect existing code first.
Follow the project's established architecture, patterns, and conventions.

## Primary Agents

### `plan` — Technical Planner

Use `plan` when the task requires planning, coordination, investigation, or decomposition.

Use for:
- New features
- Complex bug fixes
- Multi-file changes
- Architecture-sensitive work
- Database changes
- Security-sensitive work
- Unclear requirements
- Tasks involving multiple specialists

`plan` should inspect the codebase before producing a plan.
`plan` should delegate only when another agent adds clear value.
`plan` must not edit source files.

### `build` — Implementation Lead

Use `build` when the task is ready for substantial implementation.

Use for:
- Complex features
- Difficult fixes
- Multi-file implementation
- Cross-layer changes
- Significant application logic
- Coordinated implementation work

Use `light-implementer` instead for small and straightforward changes.
`build` should follow an approved plan when one exists.
`build` should run relevant verification before finishing.

## Subagents

### `codebase-explorer`

Use to locate and explain existing code relevant to the task.
Use for files, classes, functions, dependencies, data flow, and tests.
Search before making assumptions.
Do not edit files.

### `software-architect`

Use when a change affects architecture or multiple system boundaries.
Use for module boundaries, layers, dependencies, state management, and data flow.
Use for database or API boundaries when design decisions are required.
Do not use for simple isolated changes.
Do not edit files.

### `architecture-reviewer`

Use after architecture-sensitive changes.
Verify folder structure, layer boundaries, dependency direction, and established patterns.
Use existing project code as the source of truth.
Report concrete violations only.
Do not edit files.

### `technical-analysis`

Use for difficult technical reasoning and root-cause investigation.
Use for state behavior, dependency interactions, failure conditions, and data flow.
Separate confirmed findings from assumptions.
Recommend the simplest correct solution.
Do not edit files.

### `solution-designer`

Use when multiple implementation approaches are reasonable.
Compare tradeoffs, simplicity, maintainability, and architecture compatibility.
Recommend one approach at the end.
Do not edit files.

### `light-implementer`

Use for small, isolated, and low-risk implementation work.

Use for:
- Simple bug fixes
- Small features
- Validation changes
- Configuration changes
- Minor UI changes
- Small refactors
- Repetitive code updates

Make the smallest necessary change.
Follow existing patterns.
Avoid architecture changes.
Run relevant checks after changes.

### `ui-developer`

Use for screens, components, widgets, forms, navigation, and responsive layouts.
Use for loading, empty, error, and interaction states.
Reuse existing components and styles.
Keep business logic outside UI components.
Follow existing state management patterns.

### `database-engineer`

Use for schema changes, migrations, queries, relationships, indexes, and transactions.
Use for data integrity and upgrade compatibility.
Understand the existing schema first.
Preserve existing data whenever possible.
Consider rollback and upgrade behavior.

### `debugger`

Use when the root cause of a bug or failure is unknown.
Use for crashes, failed tests, incorrect state, logs, and regression analysis.
Reproduce or trace the issue before recommending a fix.
Avoid speculative fixes.
Do not edit source files.

### `refactoring-specialist`

Use to improve structure without changing behavior.
Use for duplication, readability, large functions, dead code, and unnecessary complexity.
Keep refactors small and focused.
Do not mix unrelated feature changes with refactoring.
Run relevant tests after changes.

### `test-verifier`

Use after implementation to verify completed changes.
Use for unit tests, integration tests, static analysis, linting, formatting, and builds.
Run only relevant checks.
Separate existing failures from new failures.
Do not claim success unless checks pass.

### `code-reviewer`

Use after important completed changes.
Review correctness, bugs, edge cases, maintainability, performance, and security.
Review only the actual changes.
Prioritize real problems over style preferences.
Do not edit files.

### `security-reviewer`

Use for authentication, authorization, credentials, permissions, and secrets.
Use for sensitive data, APIs, file access, input validation, and exposure risks.
Focus on realistic risks.
Recommend minimal practical fixes.
Do not edit files.

### `performance-reviewer`

Use only for confirmed or meaningful performance concerns.
Use for slow code paths, expensive loops, queries, API calls, rendering, and memory usage.
Use for blocking operations, large I/O, caching, and resource leaks.
Inspect or measure before recommending changes.
Avoid premature optimization.

### `git-manager`

Use for branches, commits, diffs, merge conflicts, tags, and releases.
Use for cherry-picks and rebases.
Inspect repository state before destructive operations.
Prefer safe and reversible operations.
Never discard uncommitted work or force-push unless explicitly requested.

### `documentation-writer`

Use when documentation must be created or updated.
Use for README files, setup instructions, configuration, features, and developer notes.
Document only implemented behavior.
Keep documentation concise.
Do not modify application logic.

## Common Workflows

### Small Change
`codebase-explorer → light-implementer → test-verifier`

### Bug Fix
`codebase-explorer → debugger → light-implementer/build → test-verifier → code-reviewer`
Add `architecture-reviewer` only when architecture is affected.

### New Feature
`codebase-explorer → plan → software-architect if needed → build → test-verifier → architecture-reviewer → code-reviewer`
For a small feature: `codebase-explorer → plan → light-implementer → test-verifier`

### New Screen / UI
`codebase-explorer → plan → ui-developer → test-verifier → code-reviewer`
Add `architecture-reviewer` if navigation, state management, or module structure changes.

### Database Change
`codebase-explorer → plan → database-engineer → test-verifier → architecture-reviewer → code-reviewer`
