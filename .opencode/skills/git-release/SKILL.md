---
name: git-release
description: Prepare and publish a safe semantic version release
compatibility: opencode
metadata:
  workflow: release
---

What I do

- Find the latest pushed semantic version tag.
- Review all changes since that tag.
- Choose the next semantic version from the actual changes.
- Update the existing version source and release notes.
- Verify version consistency and run relevant release checks.
- Commit, push, create the new version tag, and push the tag.

Rules

- Follow the project's existing versioning and release format.
- For a first release, use the current project version as the baseline.
- Never force push or overwrite an existing tag.
- Never delete or recreate published tags unless explicitly requested.
- Never commit secrets or unrelated changes.
- Stop if required version checks or release validation fail.

Use this skill when preparing a tagged project release.
