# Development Team Workflows

Use the smallest workflow that can complete the task correctly.

Always inspect existing code and follow the project's architecture and conventions.

## Agent Responsibilities

- `plan` — technical lead and workflow coordinator
- `explore` — repository investigation
- `architect` — architecture design
- `architecture-guard` — architecture consistency verification
- `analyze` — deep technical investigation
- `brainstorm` — solution comparison

- `light-build` — small and straightforward implementation
- `build` — complex and heavy implementation
- `ui` — screens and UI implementation
- `database` — database and persistence implementation
- `refactor` — behavior-preserving code improvement

- `debug` — bug investigation
- `test` — verification
- `code-reviewer` — final code review
- `security` — security review
- `performance` — performance analysis

- `dependency` — dependency management
- `git` — Git and release operations
- `docs` — documentation

## Bug Fix

explore → debug → light-build/build → test → architecture-guard → code-reviewer

Use `light-build` for isolated or straightforward fixes.

Use `build` when the bug requires complex logic, multiple layers, or significant changes.

## Small Change

explore → light-build → test

Examples:

- Simple bug fix
- Validation change
- Configuration change
- Minor UI change
- Small refactor
- Repetitive code update

## New Feature

explore → plan → architect if needed → build → test → architecture-guard → code-reviewer

Use `architect` only when the feature affects architecture, layers, dependencies, data flow, or multiple modules.

## New Screen / UI

explore → plan → ui → test → architecture-guard → code-reviewer

Reuse existing:

- Components
- Widgets
- Styles
- Navigation
- State management
- Folder structure

Keep business logic outside UI code.

## Database Change

explore → plan → database → test → architecture-guard → code-reviewer

Always preserve existing data when possible.

Check:

- Schema
- Migrations
- Relationships
- Queries
- Indexes
- Transactions
- Upgrade compatibility

## Complex Feature

explore → architect → plan → build → test → architecture-guard → code-reviewer

Use for changes spanning several layers or modules.

## Refactoring

explore → refactor → test → architecture-guard → code-reviewer

Do not change application behavior during refactoring.

## Performance Issue

explore → performance → analyze if needed → light-build/build → test

Optimize only confirmed or meaningful bottlenecks.

## Security-Sensitive Change

explore → plan → build → test → security → code-reviewer

Use for:

- Authentication
- Authorization
- Credentials
- Permissions
- Sensitive data
- APIs
- File access
- Input validation

## Dependency Change

dependency → plan if needed → light-build → test

Avoid unnecessary dependency upgrades.

## Git / Release Task

git

Use safe and reversible Git operations.

Never discard uncommitted work or force-push unless explicitly requested.

## Documentation

docs

Documentation must describe actual implemented behavior.

## Skills

Load relevant skills when specialized technology guidance is needed.

Examples:

- Flutter → Flutter skill
- Riverpod → Riverpod skill
- Clean Architecture → Clean Architecture skill
- Drift → Drift skill
- FastAPI → FastAPI skill
- Docker → Docker skill
- GitHub Actions → GitHub Actions skill

Agents define who performs the work.

Skills define technology-specific knowledge and rules.

## Delegation Rules

Do not call every agent for every task.

Use specialized agents only when they provide clear value.

Prefer:

DeepSeek V4 Flash:
- Small code changes
- UI work
- Refactoring
- Git
- Documentation

GPT-5.6 Luna:
- Complex implementation
- Heavy coding
- Multi-file features
- Difficult changes

MiMo V2.5:
- Exploration
- Brainstorming
- Dependency investigation

DeepSeek V4 Pro:
- Architecture
- Deep analysis
- Debugging
- Database work
- Performance investigation

MiniMax M3:
- Testing and verification

GLM-5.2:
- Important code reviews
- Security reviews

Reserve expensive models for tasks that require deeper reasoning.

## General Rules

- Follow existing architecture strictly.
- Inspect existing implementations before creating new patterns.
- Prefer reuse over duplication.
- Keep solutions simple.
- Avoid unnecessary abstractions.
- Avoid unrelated changes.
- Keep responsibilities separated.
- Run relevant verification after implementation.
- Do not claim success when tests or checks fail.