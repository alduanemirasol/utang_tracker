# Agent Workflows

Use the smallest workflow that fits the task.

## Bug Fix

explore → debug → light-build/build → test → architecture-guard → code-reviewer

Use `light-build` for small and isolated fixes.
Use `build` for complex or multi-file fixes.

## New Feature

explore → plan → architect (if needed) → build → test → architecture-guard → code-reviewer

Use `architect` only when the feature affects structure, layers, dependencies, or multiple modules.

## New Screen / UI

explore → plan → ui → test → architecture-guard → code-reviewer

Reuse existing screens, components, state management, navigation, and styling patterns.

## Database Change

explore → plan → database → test → architecture-guard → code-reviewer

Preserve existing data and follow current database patterns.

## Large Architectural Feature

explore → architect → plan → build → architecture-guard → test → code-reviewer

Use this only for changes that significantly affect project structure or multiple layers.

## Small Change

explore → light-build → test

Use for:
- Small UI changes
- Configuration changes
- Simple fixes
- Minor validation changes
- Small refactors

## Rules

- Follow the existing project architecture.
- Reuse existing patterns before creating new ones.
- Keep solutions simple.
- Avoid unrelated changes.
- Use `light-build` whenever the task does not require heavy implementation.
- Use `build` for complex implementation.
- Run verification after implementation.
- Use `architecture-guard` when architecture consistency could be affected.