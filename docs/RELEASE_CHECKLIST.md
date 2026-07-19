# Release Checklist

Template for publishing a new release. Replace `x.x.x` with the target version.

---

## Commands

```powershell
# ── 1. BUMP VERSION ───────────────────────────────────────────
# Edit pubspec.yaml and bump version (e.g. 1.0.13+14)

git add pubspec.yaml
git commit -m "bump version to 1.0.13"

# ── 2. BUILD SPLIT APKS ───────────────────────────────────────
flutter build apk --release --split-per-abi

# ── 3. RENAME APKS ────────────────────────────────────────────
$tag = "v1.0.13"
$src = "build\app\outputs\flutter-apk"
New-Item -ItemType Directory -Force -Path release
Copy-Item "$src\app-arm64-v8a-release.apk" "release\utang-tracker-arm64-v8a-$tag.apk"
Copy-Item "$src\app-armeabi-v7a-release.apk" "release\utang-tracker-armeabi-v7a-$tag.apk"
Copy-Item "$src\app-x86_64-release.apk" "release\utang-tracker-x86_64-$tag.apk"

# (Optional) universal fallback
flutter build apk --release
Copy-Item "$src\app-release.apk" "release\utang-tracker-universal-$tag.apk"

# ── 4. COMMIT REMAINING, TAG & PUSH ──────────────────────────
git add . && git commit -m "release v1.0.13"
git tag v1.0.13
git push origin main --tags

# ── 5. CREATE GITHUB RELEASE ─────────────────────────────────
# --notes text becomes "What's new" in the update sheet.
# Each line is one bullet point.
cd release
gh release create v1.0.13 `
  --title "v1.0.13" `
  --notes "Auto-scroll to first validation error
Unsaved changes protection
Improved install from unknown sources flow" `
  *.apk
cd ..
```

---

## What goes in `--notes`

Only the `--notes` text appears in the app's update sheet under **"What's new"**.
Keep entries concise and user-facing:

```
Short description of change 1
Short description of change 2
Short description of change 3
```

Everything else (tag name, title, APK filenames) is internal and not shown to users.
