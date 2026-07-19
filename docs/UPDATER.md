# In-App Updater — Developer Guide

This document covers everything needed to publish, configure, and test the
GitHub Releases–based in-app update feature for **Utang Tracker**.

---

## How it works

1. On startup (at most once every 24 hours) the app calls the GitHub Releases
   API to check for a newer version.
2. If an update is available, a bottom sheet appears offering the user a chance
   to download and install the APK.
3. The user can also check manually via **Home → ⓘ About → Check for updates**.

---

## Release tag format

Tags **must** follow strict semver with a leading `v`:

```
v{major}.{minor}.{patch}
```

Examples: `v1.0.0`, `v1.2.3`, `v2.0.0`

The app strips the leading `v` before comparing versions, so `v1.2.0` maps to
installed version `1.2.0` (the value in `pubspec.yaml`).

> **Do not** use pre-release suffixes like `v1.0.0-beta.1` for production
> releases — the updater ignores any release marked `prerelease: true` or
> `draft: true` on GitHub.

---

## APK asset naming format

Each GitHub Release must include one or more APKs named using this pattern:

```
{prefix}-{abi}-{tag}.apk
```

| Placeholder | Value |
|---|---|
| `{prefix}` | `utang-tracker` |
| `{abi}` | `arm64-v8a`, `armeabi-v7a`, `x86_64`, or `universal` |
| `{tag}` | The full release tag, e.g. `v1.2.0` |

Full examples:

```
utang-tracker-arm64-v8a-v1.2.0.apk
utang-tracker-armeabi-v7a-v1.2.0.apk
utang-tracker-x86_64-v1.2.0.apk
utang-tracker-universal-v1.2.0.apk
```

The app selects the best APK in priority order:
`arm64-v8a` → `armeabi-v7a` → `x86_64` → `universal`

If none of these match the asset prefix, the update dialog will show an error.
Always include at least a `universal` APK as a fallback.

---

## Android Manifest & FileProvider configuration

These are already configured in the project. For reference:

**`AndroidManifest.xml`** — required permissions and provider declaration:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />

<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_provider_paths" />
</provider>
```

**`res/xml/file_provider_paths.xml`** — exposes external storage to the
package installer:

```xml
<paths>
    <external-path name="external_files" path="." />
</paths>
```

**`MainActivity.kt`** — MethodChannel `com.example.utang_tracker/updater`
exposes three methods to Dart:

| Method | Description |
|---|---|
| `canInstallUnknownApps` | Returns `true` if the app has permission to install APKs |
| `openInstallSettings` | Opens the system "Install unknown apps" settings page |
| `installApk({path})` | Fires `ACTION_VIEW` with a `FileProvider` URI for the APK |

---

## Publishing a new release

1. Bump `version` in `pubspec.yaml`, e.g. `1.2.0+11`.
2. Build ABI-split release APKs:
   ```bash
   flutter build apk --release --split-per-abi
   ```
   This produces files under `build/app/outputs/flutter-apk/`:
   - `app-arm64-v8a-release.apk`
   - `app-armeabi-v7a-release.apk`
   - `app-x86_64-release.apk`

3. (Optional) Build a universal fallback:
   ```bash
   flutter build apk --release
   # produces build/app/outputs/flutter-apk/app-release.apk
   ```

4. Rename each APK using the required naming convention, for example:
   ```
   utang-tracker-arm64-v8a-v1.2.0.apk
   utang-tracker-armeabi-v7a-v1.2.0.apk
   utang-tracker-x86_64-v1.2.0.apk
   utang-tracker-universal-v1.2.0.apk
   ```

5. Create a new GitHub Release:
   - Go to **Releases → Draft a new release**
   - Tag: `v1.2.0` (must match the version string in `pubspec.yaml`)
   - Attach all renamed APKs as release assets
   - Uncheck **Set as a pre-release**
   - Publish the release

The app will detect the new version on the next startup (or when the user taps
"Check for updates").

---

## Testing the updater locally

### Simulate an update being available

1. Temporarily lower the version in `pubspec.yaml`, e.g. change `1.2.0+11` to
   `1.1.0+10`:
   ```yaml
   version: 1.1.0+10
   ```
2. Run the app on a device or emulator with internet access.
3. The startup check will see `v1.2.0` on GitHub is newer than the installed
   `1.1.0` and show the update bottom sheet.

### Simulate the download + install flow

1. Follow steps above to trigger the update dialog.
2. Tap **Update now** — the app streams the APK to
   `/sdcard/Android/data/com.example.utang_tracker/files/utang_tracker_updates/`.
3. Once downloaded, tap **Install now** — the system package installer opens.
4. If the device has never installed APKs from unknown sources, the app
   directs you to **Settings → Install unknown apps** first.

### Run unit tests

```bash
flutter test test/updater_test.dart
```

All tests are pure Dart; no device or emulator is required.

### Inspect downloaded files

```bash
adb shell ls /sdcard/Android/data/com.example.utang_tracker/files/utang_tracker_updates/
```

Old APK files are deleted automatically before each new download.
