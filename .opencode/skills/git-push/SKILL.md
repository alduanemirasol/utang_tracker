---
name: git-push
description: Safely review, commit, and push completed project changes
compatibility: opencode
metadata:
  workflow: git
---

What I do

- Review the current branch, status, and diff.
- Stage only intentional completed changes.
- Create a concise commit message from the actual changes.
- Commit and push the current branch.

Rules

- Never force push or rewrite history.
- Never use destructive reset or clean commands.
- Never delete branches or tags.
- Never commit secrets, credentials, or unrelated changes.
- Do not create release tags unless explicitly requested.

Use this skill when completed changes need to be committed and pushed safely.
