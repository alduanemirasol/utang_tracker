# Release Checklist

## 1. Edit Release Notes

Edit `RELEASE_NOTES.md` at the project root with user-facing "What's new" entries:

```text
What's new in v1.0.13

- Auto-scroll to first validation error
- Unsaved changes protection
- Improved install from unknown sources flow
```

This file is read by the CI workflow and becomes the GitHub Release body —
the content users see in the app's update dialog.

## 2. Bump Version

Update the version in `pubspec.yaml`:

```yaml
version: 1.0.13+14
```

Commit:

```powershell
git add pubspec.yaml
git commit -m "bump version to 1.0.13"
```

## 3. Commit Everything

```powershell
git add .
git commit -m "release v1.0.13"
```

## 4. Tag and Push

```powershell
git tag v1.0.13
git push origin main --tags
```

The CI pipeline (`.github/workflows/release.yml`) will:

1. Build and sign APKs (split + universal)
2. Validate `RELEASE_NOTES.md` exists
3. Create a GitHub Release with body from `RELEASE_NOTES.md`
4. Upload all APKs as release assets

## Release Notes

Only the content of `RELEASE_NOTES.md` appears in the app's **What's New** section.
Keep entries concise and user-facing.
