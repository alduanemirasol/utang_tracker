# Developer Setup — Utang Tracker

Single canonical onboarding doc. If it is not here, it is not required to run or build the app. For the data spec see [`rules/database_rules.md`](../rules/database_rules.md); for the project overview see [`README.md`](../README.md).

> Android-only Flutter app. iOS / web / desktop are not supported — intentionally out of scope.

---

## 1. Prerequisites

| Requirement | Version / Value | Notes |
|---|---|---|
| **Flutter** | `3.44.0` stable | `flutter --version` must show `3.44.0` |
| **Dart SDK** | `^3.12.0` | Bundled with Flutter 3.44.0 (`Dart 3.12.0`) |
| **Android Gradle Plugin (AGP)** | `9.0.1` | `android/settings.gradle.kts:22` |
| **Kotlin** | `2.3.20` | `android/settings.gradle.kts:23` |
| **JDK** | `17` | `JavaVersion.VERSION_17` in `android/app/build.gradle.kts:30-31`, `JvmTarget.JVM_17` at line 74 |
| **Google Services Gradle plugin** | `4.4.2` | `android/settings.gradle.kts:24` + `android/app/build.gradle.kts:7` — required only when Drive backup is enabled |
| **compileSdk** | `36` | `android/app/build.gradle.kts:26` |
| **Android Studio** | Ladybug or newer with SDK 36 installed | Must include `Android SDK Platform 36` + `Google Play services` |
| **Platform** | Android only | `applicationId = com.example.utang_tracker`, `namespace = com.example.utang_tracker` |
| **OS for build** | Windows / macOS / Linux with Android SDK | Debug keystore path in this repo: `~/.android/debug.keystore` (Windows: `%USERPROFILE%\.android\debug.keystore`) |

Verify after install:

```sh
flutter --version   # Flutter 3.44.0 • Dart 3.12.0
java -version       # 17.x
flutter doctor      # Android toolchain must be green
```

---

## 2. Environment Setup

1. **Install Flutter 3.44.0** from <https://docs.flutter.dev/get-started/install> and add `flutter` to `PATH`.
2. **Install Android Studio** and via SDK Manager install `Android SDK Platform 36`, `Android SDK Build-Tools`, `Google Play services`.
3. **Accept licenses:**
   ```sh
   flutter doctor --android-licenses
   ```
4. **Set `local.properties` (auto-generated, do not commit):**
   `android/local.properties` must contain:
   ```properties
   sdk.dir=C:\\Users\\<you>\\AppData\\Local\\Android\\sdk
   flutter.sdk=C:\\flutter
   ```
   `flutter pub get` / `flutter run` regenerates `flutter.versionName` / `flutter.versionCode` there.
5. **Clone and fetch deps:**
   ```sh
   git clone <repo-url> utang_tracker
   cd utang_tracker
   flutter pub get
   ```
6. **Drift codegen (only after editing `lib/core/database/tables.dart` or `app_database.dart`):**
   ```sh
   dart run build_runner build --delete-conflicting-outputs
   ```
   This regenerates `lib/core/database/app_database.g.dart` (drift 2.34.1 + drift_flutter 0.3.0). The file IS committed — commit it after regeneration. Search ignores `*.g.dart` via `.ignore` (not `.gitignore`).
7. **Verify:**
   ```sh
   flutter analyze   # must print "No issues found!"
   flutter test      # 121 tests expected (91 + backup). CI runs analyze then test in that order.
   flutter test test/<file>.dart   # single file
   ```

---

## 3. Project Layout (quick reference)

```
lib/
  main.dart / app.dart                 # Workmanager + connectivity_plus init (main.dart:19-44)
  app/coordination.dart                # invalidateBusinessData + invalidateBackupData (31-42)
  core/database/ tables.dart / app_database.dart / database_location.dart / mappers.dart / app_database.g.dart
  core/domain/ money.dart / debt_status.dart
  core/providers/ core_providers.dart  # plain Riverpod Providers; backup providers 56-103+
  core/router/ app_router.dart / app_shell.dart   # go_router StatefulShellRoute.indexedStack (5 tabs)
  core/theme/ core/widgets/ core/utils/ core/error/ core/constants/
  features/customers|debts|payments|dashboard|notifications|updater|settings|backup  # 8 dirs
    domain/entities + domain/repositories (interface) + domain/usecases
    data/repositories (impl) + data/datasources + data/services
    presentation/pages + presentation/providers + presentation/widgets
  android/app/src/main/kotlin/.../MainActivity.kt  # updater channel com.example.utang_tracker/updater
assets/images/ + assets/release_notes/current.json
rules/database_rules.md   # authoritative schema v5 spec
test/                     # AppDatabase.forTesting() (in-memory SQLite)
```

State and navigation details are in §6.

---

## 4. Google Drive Backup Setup (full)

Backup is optional at runtime but requires the Android OAuth wiring below to work. Without it the app still builds and runs — sign-in will fail with a typed error instead of crashing (see `GoogleAuthDatasource._handleAuthError`).

### 4.1 Overview

- Scope: `https://www.googleapis.com/auth/drive.file` (file-level only — app can only see files it created).
- Package: `com.example.utang_tracker` (`applicationId` and `namespace` in `android/app/build.gradle.kts:25,35`).
- Drive folder: `utang_tracker_backup` (created via `GoogleDriveService.ensureFolderId()`).
- Key packages: `google_sign_in ^6.3.0`, `googleapis ^14.0.0`, `googleapis_auth ^2.0.0`, `archive ^4.0.7`, `crypto ^3.0.7`, `workmanager ^0.10.9`, `connectivity_plus ^6.1.5`, `shared_preferences ^2.5.3`.

### 4.2 Create Firebase / Google Cloud project

1. Go to [Google Cloud Console](https://console.cloud.google.com/) → New Project (or use existing). The example project in this repo is `utang-t` (`project_id: utang-t`, `storage_bucket: utang-t.firebasestorage.app` — replace with your project).
2. **Enable the Drive API:** APIs & Services → Library → search "Google Drive API" → Enable.
3. **Configure OAuth consent screen:** APIs & Services → OAuth consent screen
   - User type: **External**
   - App name / support email / developer contact as needed.
   - Scopes → Add: `https://www.googleapis.com/auth/drive.file` (do NOT add `drive` full scope; `drive.file` is least-privilege and matches `google_auth_datasource.dart:8`).
   - Test users → Add the Google accounts that will sign in while the app is in Testing/External-Testing. Without this, sign-in returns `access_denied`.
   - Publish later if you need production; while in Testing, auth works only for test users.
4. **Create OAuth client(s)** — Credentials → Create Credentials → OAuth client ID → **Android**
   - You need one Android client per signing certificate (debug + release). Package name must be `com.example.utang_tracker` every time.
   - Paste the SHA-1 (and SHA-256 if the console offers both fields). See §4.3 for how to obtain them.
   - Repeat for each fingerprint (debug SHA-1/SHA-256 + release SHA-1/SHA-256).

### 4.3 Obtain SHA-1 / SHA-256 fingerprints

Both fingerprints must be registered. The `google-services.json` you download later will contain an `oauth_client[]` entry per fingerprint — if `oauth_client` is empty, the fingerprints were not registered before download (see §4.7).

**Debug (Windows PowerShell shown; macOS/Linux use `./gradlew`):**

```sh
# Fastest — prints both debug fingerprints for every variant
.\gradlew signingReport
# Or via keytool directly
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android
```

Example debug fingerprints from this repo (your machine will differ — use YOUR output):
```
SHA1:   0C:9A:48:70:5C:24:BC:40:4F:5A:4E:5F:3C:D3:4D:D8:49:49:60:5C
SHA-256: 48:8C:49:4A:BE:A4:F2:B5:A6:8A:2D:C7:F0:9F:ED:44:F9:BF:34:94:A9:44:9F:46:92:CC:18:44:CF:56:24:AB
```

**Release:**

```sh
keytool -list -v -keystore <path\to\release-keystore.jks> -alias <key-alias> -storepass <storePassword>
# key alias / storeFile / passwords are in android/key.properties (gitignored, see §7)
```

Register the release SHA-1 and SHA-256 in the same Cloud Console Android OAuth client (or as a second Android client). There is no step to "convert" SHA-1 to SHA-256 — they are distinct hashes.

### 4.4 Download and place `google-services.json`

1. After creating the Android OAuth client and adding fingerprints, go to Credentials → your Android client → Download JSON, or Firebase Console → Project settings → Your apps → `google-services.json`.
2. Place it at:
   ```
   android/app/google-services.json
   ```
   This file is **gitignored** (`/.gitignore:52`) — never commit it. It contains `client_id` (e.g. `586311375935-....apps.googleusercontent.com`), `project_id`, `storage_bucket`, `oauth_client` entries, etc. Do not paste its contents into docs or chat.
3. The file must satisfy:
   - `package_name` / `client[].client_info.android_client_info.package_name` contains `com.example.utang_tracker`.
   - `oauth_client[]` is **non-empty** after you re-download post-fingerprint (see §4.7).

### 4.5 Gradle plugin wiring

Already configured in this repo — verify you have not removed these:

**`android/settings.gradle.kts`:**

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false   // <-- required
}
```

**`android/app/build.gradle.kts`:**

```kotlin
plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")   // <-- required, no version here
}
```

If Drive backup is removed in the future, both lines can be deleted together; otherwise the build fails with `google-services.json not found` or `Plugin with id 'com.google.gms.google-services' not found`.

### 4.6 AndroidManifest `<queries>`

`android/app/src/main/AndroidManifest.xml` already contains (lines 54-62):

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT" />
        <data android:mimeType="text/plain" />
    </intent>
    <!-- Required for Google Sign-In / Credential Manager on Android 11+ -->
    <package android:name="com.google.android.gms" />
    <package android:name="com.android.vending" />
</queries>
```

Without these, `GoogleSignIn.signIn()` throws `ApiException: 7` / returns null on Android 11+ due to package visibility.

### 4.7 Re-download `google-services.json` after adding fingerprints

The downloaded JSON is a snapshot. If you add a SHA fingerprint after downloading, the existing file will have **empty `oauth_client`** and auth will fail with `DEVELOPER_ERROR 10`. Fix:

1. In Cloud Console → Credentials → verify the Android OAuth client now lists both SHA-1 and SHA-256.
2. Re-download `google-services.json`.
3. Replace `android/app/google-services.json`.
4. Open the file and confirm `client[].oauth_client` is populated (array length ≥ 1, each entry has `client_id` + `certificate_hash` matching your SHA-1). If still empty, wait 1-2 minutes and re-download (propagation delay).
5. Clean rebuild:
   ```sh
   flutter clean
   flutter pub get
   flutter run
   ```

---

## 5. Subsystems Reference

### 5.1 Drift SQLite — schema v5

- **Files:** `lib/core/database/tables.dart`, `lib/core/database/app_database.dart`, `lib/core/database/database_location.dart`, `lib/core/database/mappers.dart`, `lib/core/database/app_database.g.dart` (generated).
- **Schema version:** `5` (`AppDatabase.schemaVersion`). No SQL `CHECK`/`UNIQUE`/cascade — rules enforced in repository impls.
- **Tables:** `customers`, `debts`, `debt_items`, `payments` — see `rules/database_rules.md` for columns, indexes, and business rules.
- **Migrations:** v2 soft-delete (`deleted_at`), v3 recreate `debt_items`, v4 add `unit` default `piece`, v5 `unit_price+subtotal -> price` (custom line amount, quantity does NOT multiply price).
- **Date handling:** user-selected local day + save-time clock → stored UTC (`DateTime` as `INTEGER`). `due_date` is date-only (no save-time stamping).
- **Testing:** `AppDatabase.forTesting()` creates an in-memory DB; migration tests seed legacy schemas via raw SQL.
- **Codegen:** `dart run build_runner build --delete-conflicting-outputs` after editing drift tables. Commit the updated `app_database.g.dart`.

### 5.2 Money

- `lib/core/domain/money.dart` — `Money` is integer **centavos** (`int`), never `double`. 100 centavos = 1 peso. `debt_items.price` is the final custom line amount; `total_amount = sum(active prices)`.

### 5.3 Backup persistence — SharedPreferences 12 keys

No SQLite table or migration. All backup state lives in `SharedPreferences` JSON (see `rules/database_rules.md` Backup Audit).

| # | Key | File (`BackupPrefsKeys.*`) | Value |
|---|---|---|---|
| 1 | `backup_audit_log` | `auditLog` | JSON list of `AuditLogEntry` — last 100, append-only |
| 2 | `backup_history` | `history` | JSON list of `BackupHistoryEntry` — last 100, append-only |
| 3 | `backup_last_time_ms` | `lastBackupTime` | Epoch ms of last successful backup |
| 4 | `backup_interval` | `interval` | `off` / `daily` / `threeDays` / `weekly` (`BackupInterval` names) |
| 5 | `backup_last_hash` | `lastBackupHash` | SHA-256 hex of last uploaded zip |
| 6 | `backup_drive_folder_id` | `driveFolderId` | Drive folder `utang_tracker_backup` id |
| 7 | `backup_next_scheduled_ms` | `nextScheduledTime` | Next auto-backup epoch ms |
| 8 | `backup_queued` | `queuedBackup` | `bool` — true if `backup_queue_json` non-empty |
| 9 | `backup_last_size` | `lastBackupSize` | Bytes of last zip |
| 10 | `backup_queue_json` | `queue` | JSON list of `BackupQueueEntry` — max 20, dedup by type+timestamp and 5-min window |
| 11 | `backup_last_error` | `lastError` | Last error message (empty after success) |
| 12 | `backup_auto_enabled` | `autoEnabled` | **Dead code** — written but never read; `backup_interval` is authoritative |

Source of truth: `lib/features/backup/data/datasources/backup_prefs_keys.dart`.

**Intervals:** `off` (disabled), `daily`, `threeDays`, `weekly` — see `BackupInterval` / `BackupIntervalX.fromName` / `.duration`.

### 5.4 Queue + Scheduler + Connectivity

- **Queue** (`lib/features/backup/data/services/backup_queue_service.dart` + `backup_queue_entry.dart`): offline/failed backups enqueued as JSON in `backup_queue_json`. Max 20 (oldest trimmed on save). Dedup by `type+timestamp` and guard `type` with `retryCount==0` + 5-minute window. 3 retries max; `backoffFor`: 1m (retry 0) → 5m (retry 1) → 30m (retry 2+).
- **Scheduler** (`lib/features/backup/data/services/backup_scheduler.dart`, `workmanager ^0.10.9`): periodic task `utang_auto_backup` / unique name `utang_auto_backup_periodic`, `NetworkType.connected` constraint, frequency from `BackupInterval.duration` clamped to minimum 15m, registered via `BackupScheduler.register(interval)` in `lib/main.dart:19-44`, background entry `@pragma('vm:entry-point') callbackDispatcher`.
- **Connectivity queue drain** (`lib/main.dart:26-43`): `connectivity_plus ^6.1.5` listens to `onConnectivityChanged`; when back online, entries are considered for retry respecting `backoffFor` and 3-retry cap. Hash dedup (`crypto ^3.0.7`): `sha256.convert(zipBytes)` stored in `backup_last_hash` and Drive `appProperties['sha256']`; duplicates skipped with `DuplicateBackupException`.

### 5.5 Auth & Drive services

- **`GoogleAuthDatasource`** (`lib/features/backup/data/datasources/google_auth_datasource.dart`): wraps `GoogleSignIn(scopes: [drive.file])` (`google_sign_in ^6.3.0`), exposes `signIn()` / `silentSignIn()` / `isSignedIn()` / `getAuthHeaders()`. `_handleAuthError` maps: 401/invalid_grant/unauthenticated/expired → `AuthExpiredException`; network/socket/host lookup → `NetworkException`; else → `BackupException` (`Sign-in failed`).
- **`GoogleDriveService`** (`lib/features/backup/data/datasources/google_drive_service.dart` + `googleapis ^14.0.0`): `ensureFolderId()` (find or create `utang_tracker_backup`), `uploadFile()`, `listBackupsInFolder()`, `getQuota()`. Used only via `BackupRepositoryImpl`.

### 5.6 Updater (GitHub Releases)

- **Channel:** `com.example.utang_tracker/updater` lives in `android/app/src/main/kotlin/.../MainActivity.kt` (only method channel in the app). Handles APK install permission (`REQUEST_INSTALL_PACKAGES`) + `FileProvider` (`@xml/file_provider_paths`).
- **Dart side:** `lib/features/updater/data/repositories/update_repository_impl.dart` checks `https://api.github.com/repos/<owner>/<repo>/releases/latest` via `http ^1.4.0` + `pub_semver ^2.2.0` comparison, surfaces via `lib/features/updater/presentation` sheet + About page.
- **Known quirk:** permission flow uses deprecated `onActivityResult` — intentional for now, do not migrate without testing on Android 11-15.

### 5.7 Signing

- `android/key.properties` + `android/app/*.jks` / `*.keystore` are **gitignored** (`.gitignore:49-51`). Never commit them.
- **Local release build:** create `android/key.properties`:
  ```properties
  storePassword=<storePassword>
  keyPassword=<keyPassword>
  keyAlias=<keyAlias>
  storeFile=../app/<your>.jks   # or absolute path; resolved via rootProject.file()
  ```
  `android/app/build.gradle.kts:10-70` validates this at `taskGraph.whenReady` and throws `Release signing is not configured` if any of the four keys is missing when any `*Release*` task runs.
- **CI:** `.github/workflows/release.yml` runs `.github/scripts/configure_signing.py` which materializes the keystore from `SIGNING_*` GitHub Secrets. No local `key.properties` needed in CI.

### 5.8 Navigation (go_router)

- `lib/core/router/app_router.dart` + `lib/core/router/app_shell.dart`.
- `go_router ^17.3.0`, `StatefulShellRoute.indexedStack` with 5 tabs: `/dashboard`, `/customers` (`/new`, `/:id`, `/:id/edit`), `/debts` (`/new?customerId`, `/:id`, `/:id/edit`), `/payments` (`/new?debtId`), `/settings` (`/about`, `/settings/backup`, `/settings/backup/browse`).
- Add new top-level routes in `app_router.dart` and add the shell branch in `app_shell.dart`.

### 5.9 State (Riverpod) — push invalidation, not streams

- **DI:** plain `Provider`s in `lib/core/providers/core_providers.dart` (business + backup providers). Repo interfaces in `features/<f>/domain/repositories`, impls in `features/<f>/data/repositories`.
- **Refresh model:** Drift reactive streams are NOT used. After any write, call:
  ```dart
  invalidateBusinessData(ref, customerId: ..., debtId: ...);
  invalidateBackupData(ref);
  ```
  from `lib/app/coordination.dart:9-42`. New `FutureProvider`s for list/detail/backup must be registered there (business providers in `invalidateBusinessData`, backup providers in `invalidateBackupData`). Backup also invalidates `backupHistoryProvider` + `backupAuditLogProvider` via `invalidateBusinessData` for the dashboard hook.
- **Backup providers in `core_providers.dart:66-141`:** `backupLocalDatasourceProvider`, `auditLogRepositoryProvider`, `backupHistoryRepositoryProvider`, `googleAuthDatasourceProvider`, `googleDriveServiceProvider`, `backupRepositoryProvider`, `backupConnectionStatusProvider`, `backupQuotaProvider`, `backupSchedulerProvider`, `connectivityProvider`, `backupQueueServiceProvider`, `backupPrefsRepositoryProvider`, `backupQueueRepositoryProvider`, `backupAuthRepositoryProvider`, `getBackupStatusProvider`, `handleBackupQueueProvider`, `getConnectionDetailsProvider`, `performBackupProvider`.

### 5.10 Release process

Version is triple-locked — CI fails if any drift:

1. Bump `version: 1.0.44+43` in `pubspec.yaml` (semver + build number).
2. Bump `version: "1.0.44"` in `assets/release_notes/current.json` (same semver, no `+build`).
3. Tag `v<version>` where `<version>` is the semver from `pubspec.yaml` (e.g. `v1.0.44`):
   ```sh
   git commit -m "release: v1.0.44"
   git tag v1.0.44
   git push origin v1.0.44
   ```
4. Push tag triggers `.github/workflows/release.yml`:
   `verify_version.py` (tag == pubspec == notes) → `test_release_scripts.py` → `flutter analyze` → `flutter test` → `configure_signing.py` → `flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64` → `prepare_release.py` + `generate_release_notes.py` → GitHub Release with `RELEASE_NOTES.md` (5 helpers in `.github/scripts/`).

---

## 6. Commands Cheat Sheet

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # only after editing drift tables
flutter analyze
flutter test
flutter test test/<file>.dart
flutter clean && flutter pub get   # after changing google-services.json or Gradle plugins
.\gradlew signingReport             # from android/ — prints debug SHA-1/SHA-256 (Windows: .\gradlew)
```

---

## 7. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| **Sign-in returns `null` / "Sign-in not completed"** | User cancelled the account picker. | Normal — no action needed. `GoogleAuthDatasource.signIn()` returns `null` and `BackupSettingsPage` shows `Sign-in not completed` via `BackupErrorMapper.toEnglish`. |
| **"Sign-in failed" / `BackupException`** | `android/app/google-services.json` missing, wrong `applicationId`, or Gradle plugin not applied. | Check file exists at `android/app/google-services.json` and `package_name` contains `com.example.utang_tracker`. Verify `android/settings.gradle.kts` has `com.google.gms.google-services:4.4.2 apply false` and `android/app/build.gradle.kts` has `id("com.google.gms.google-services")`. Run `flutter clean && flutter pub get`. |
| **"Authentication expired, please sign in again." / `AuthExpiredException`** | Refresh token revoked/expired (401 / invalid_grant / unauthenticated). | Sign out and sign in again via Backup Settings. Check `BackupAuthRepositoryImpl.getConnectionDetails` → `isSignedIn()` then `getAuthHeaders()` mapping (`signedOut` / `expired` / `signedIn`). |
| **"No internet connection" / `NetworkException` — backup queued** | Device offline (socket / host lookup failure). | App enqueues to `backup_queue_json` (max 20) and retries with backoff via `connectivity_plus` listener in `main.dart:28-43`. Bring device online; queue drains when `ConnectivityResult != none`. Check `backup_last_error` in SharedPreferences if stuck. |
| **`DEVELOPER_ERROR 10` / `ApiException: 10`** | SHA fingerprint not registered for this `applicationId`, or `google-services.json` downloaded before fingerprint was added. | Re-check Cloud Console → Credentials → Android OAuth client lists correct SHA-1/SHA-256 for `com.example.utang_tracker`. Re-download `google-services.json` (see §4.7) and `flutter clean`. On Windows, confirm with `.\gradlew signingReport` or `keytool -list -v`. For release, verify `android/key.properties` `keyAlias`/`storeFile` match the registered fingerprint. |
| **`google-services.json` has empty `oauth_client: []`** | File downloaded before SHA fingerprints were saved. | Not a valid config. Re-download after fingerprints show in Console, verify `oauth_client` is populated, then `flutter clean && flutter run`. Propagation can take 1-2 minutes. |
| **Release build fails: "Release signing is not configured"** | `android/key.properties` missing or incomplete. | Create `android/key.properties` with all four keys (`storePassword`, `keyPassword`, `keyAlias`, `storeFile`). Keystore file itself must exist at the `storeFile` path (also gitignored). In CI, secrets are injected by `configure_signing.py`. |
| **Workmanager periodic task not firing** | `BackupInterval.off`, no network, or OS battery optimization. | Check `SharedPreferences backup_interval` is not `off`. Scheduler clamps to min 15m (`BackupScheduler._frequency`). Workmanager requires `NetworkType.connected`; test on a real device with battery optimization disabled for the app. |

### Where to find logs

```sh
# Device logs (filter to Flutter / backup)
adb logcat | findstr /i "flutter utang backup googlesignin"   # Windows
adb logcat | grep -i "flutter\|utang\|backup\|googlesignin"    # macOS/Linux

# Specific Google Sign-In errors
adb logcat | findstr /i "DEVELOPER_ERROR ApiException"
# Workmanager background task
adb logcat | findstr /i "workmanager utang_auto_backup"

# SharedPreferences inspection (debug)
# Add a temporary log in app: prefs.getString(BackupPrefsKeys.lastError) / backup_queue_json / backup_last_hash

# Flutter run verbose
flutter run -v
flutter analyze -v
```

---

## 8. Gotchas

- UI strings are hardcoded Taglish/Cebuano — no i18n, intentional. Do not add localization plumbing.
- `Money` must stay integer centavos — never introduce `double` for amounts.
- `debt_items.price` is final — quantity does NOT multiply price.
- Soft delete everywhere (`deleted_at IS NULL` = active); debt/payment deletion is intentionally not exposed.
- Dates: local day + save-time clock → stored UTC; `due_date` is date-only.
- `backup_auto_enabled` SharedPreferences key is dead code — do not branch on it; `backup_interval` is authoritative.
- Do not commit `android/app/google-services.json`, `android/key.properties`, or `*.jks` — all gitignored.

