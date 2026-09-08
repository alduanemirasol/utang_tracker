# utang_tracker

Sari-sari store utang/bayad ledger - Android-only Flutter app. Tracks customers, debts (with line items), and payments. UI strings are hardcoded Taglish/Cebuano (no i18n, intentional).

> **New dev?** Start with [`docs/SETUP.md`](docs/SETUP.md) — single canonical setup doc (prerequisites, Drive backup, all subsystems, troubleshooting).

## Features

- **Customers** - create/edit/soft-delete, unique name (case-insensitive), search, sort by name/date
- **Debts** - one debt = many `debt_items` (product, qty, unit, price), editable only while `paid_amount == 0`
- **Payments** - record partial/full bayad, balance/status derived atomically
- **Dashboard** - outstanding balance, active debt count, collected amount, recent activity
- **Overdue & notifications** - due-date aware
- **Backup & Restore (Google Drive)** - Drive folder `utang_tracker_backup`, DB zipped via `archive` + SHA256 (`crypto`), auto intervals Off/Daily/3days/Weekly, Backup Now / Browse & Restore, audit log + history, offline queue, background `workmanager` periodic
- **Updater** - GitHub Releases check, in-app update sheet + About page

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.44.0 (stable, Dart SDK ^3.12.0, Android only) |
| State | `flutter_riverpod` - plain `Provider`s in `lib/core/providers/core_providers.dart` |
| DB | `drift` 2.34.1 + `drift_flutter` 0.3.0 + `sqlite3` 3.5.0, schema v5, `AppDatabase.forTesting()` for tests |
| Nav | `go_router` `StatefulShellRoute.indexedStack` (5 tabs) |
| Money | `Money` (`lib/core/domain/money.dart`) - integer centavos, never `double` |
| Fonts | Poppins, Material 3 theme |
| Backup | `shared_preferences` ^2.5.3, `connectivity_plus` ^6.1.5, `google_sign_in` ^6.3.0, `googleapis` ^14.0.0, `googleapis_auth` ^2.0.0, `archive` ^4.0.7, `crypto` ^3.0.7, `workmanager` ^0.10.9, `path_provider` ^2.1.5, `package_info_plus` ^8.3.0, `path` ^1.9.1, `http` ^1.4.0 |

Version: `1.0.44+43` (`pubspec.yaml` + `assets/release_notes/current.json` must match tag `v<version>`).

## Prerequisites

| Requirement | Version |
|---|---|
| Flutter | `3.44.0` stable (Dart `^3.12.0`) |
| AGP | `9.0.1` |
| Kotlin | `2.3.20` |
| JDK | `17` |
| compileSdk | `36` |
| Platform | Android only (`com.example.utang_tracker`) |

Full details, env setup, and subsystem docs → [`docs/SETUP.md`](docs/SETUP.md).

## Project Structure

```
lib/
  main.dart / app.dart                 # Workmanager + connectivity queue init (backup)
  app/coordination.dart                # invalidateBusinessData + invalidateBackupData (31-42)
  core/
    database/ tables.dart / app_database.dart / database_location.dart / mappers.dart / app_database.g.dart (generated, committed)
    domain/ money.dart / debt_status.dart
    providers/ core_providers.dart     # + backup providers (56-103)
    router/ app_router.dart / app_shell.dart
    theme/ widgets/ utils/ constants/ error/
  features/
    customers|debts|payments|dashboard|notifications|updater|settings|backup  # 8 feature dirs
      domain/entities + domain/repositories (interface) + domain/usecases
      data/repositories (impl - enforces business rules) + data/datasources + data/services
      presentation/pages + presentation/providers + presentation/widgets
    backup specific: entities (audit_action/audit_log_entry/backup_history_entry/backup_interval/backup_meta/backup_source/backup_status/storage_quota), 3 repos+impls, 5 datasources (backup_prefs_keys/google_auth_datasource/google_drive_service/backup_local_datasource/backup_queue_entry), 3 services (backup_prefs_service/backup_queue_service/backup_scheduler), 2 pages (backup_settings_page/backup_browse_page)
  android/app/src/main/kotlin/.../MainActivity.kt  # updater channel only (com.example.utang_tracker/updater)
  assets/images/ + assets/release_notes/current.json
  rules/database_rules.md              # authoritative data spec (schema v5)
  test/                                # repo + migration tests (in-memory DB)
```

## Data Rules

Full spec -> [`rules/database_rules.md`](rules/database_rules.md) (schema v5, authoritative).

Summary (enforced in repository impls, not SQL):

- IDs = UUID v4 `TEXT`, Money = `INTEGER` centavos, `deleted_at IS NULL` = active, no cascades
- `debt_items.price` = final custom line amount - `quantity` does **not** multiply price; `total_amount = sum(active prices)`
- Debt status derived: `UNPAID (paid<=0)` -> `PARTIAL (0<paid<total)` -> `PAID (paid>=total)`; `balance = total - paid`
- Debt editable only while `paid_amount == 0`; edit = soft-delete old items + insert new in transaction
- Payment: `0 < amount <= balance`, only against active non-PAID debt; insert + debt update atomic
- Dates: user-selected local day + save-time clock -> stored UTC; `due_date` is date-only
- Customer delete blocked if active `UNPAID`/`PARTIAL` debts exist; names unique among active (case-insensitive)

Indexes: `idx_debts_customer_id/status/transaction_date`, `idx_debt_items_debt_id`, `idx_payments_debt_id/payment_date`.

Migrations: v2 soft-delete, v3 recreate `debt_items`, v4 add `unit` (default `piece`), v5 `unit_price+subtotal -> price`.

## Setup & Commands

> Exhaustive steps → [`docs/SETUP.md`](docs/SETUP.md) (canonical). Summary below.

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # after editing drift tables (app_database.g.dart is committed)
flutter analyze
flutter test
flutter test test/<file>.dart   # single file
```

Search ignores `*.g.dart` via `.ignore` (not `.gitignore`).

## Architecture Notes

- **Push refresh, not streams:** after writes call `invalidateBusinessData(ref)` and for backup `invalidateBackupData(ref)` from `lib/app/coordination.dart` (31-42) — register new `FutureProvider`s there (business + backup providers).
- **DI:** plain Riverpod `Provider`s in `core_providers.dart`; repo interfaces `features/<f>/domain/repositories`, impls `features/<f>/data/repositories`. Backup providers live in `core_providers.dart:56-103` (`backupLocalDatasourceProvider`, `auditLogRepositoryProvider`, `backupHistoryRepositoryProvider`, `googleAuthDatasourceProvider`, `googleDriveServiceProvider`, `backupRepositoryProvider`, `backupConnectionStatusProvider`, `backupQuotaProvider`, `backupSchedulerProvider`, `connectivityProvider`, `backupQueueServiceProvider`).
- **Testing:** `AppDatabase.forTesting()` (in-memory); migration tests seed legacy schemas via raw SQL. Backup persistence is SharedPreferences JSON (no SQLite migration).
- **Method channels:** updater only lives in `MainActivity.kt` (install-permission flow uses deprecated `onActivityResult`).
- **Signing:** `android/key.properties` + keystores gitignored; CI signs from `SIGNING_*` secrets.
- **Backup bg work:** `lib/main.dart:19-44` initializes `Workmanager` and listens to `connectivity_plus` to drain the offline queue.

## Google Drive Backup Setup

> Full walkthrough (Firebase project, Drive API, OAuth consent screen with `drive.file` + test users, SHA-1/SHA-256 via `.\gradlew signingReport` / `keytool`, placing `google-services.json`, Gradle plugins, `<queries>`, re-download check for populated `oauth_client`) → [`docs/SETUP.md` §4](docs/SETUP.md#4-google-drive-backup-setup-full). Summary below.

Google Drive backup requires Android-side OAuth configuration. Without it, sign-in will fail with a clear error message instead of crashing.

### Required files (NOT committed — contain secrets)

1. **`android/app/google-services.json`** — Download from [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials → Android OAuth 2.0 client. The file must match `applicationId = com.example.utang_tracker`. Gitignored (`android/app/google-services.json` in `.gitignore:52`). After adding SHA fingerprints, re-download — `oauth_client[]` must be populated or auth fails with `DEVELOPER_ERROR 10`.

2. **SHA-1 and SHA-256 certificate fingerprints** — Register both debug and release fingerprints in the Cloud Console OAuth client:
    ```sh
    # Debug — fastest (Windows: .\gradlew, macOS/Linux: ./gradlew)
    .\gradlew signingReport
    # or direct
    keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android
    # Release
    keytool -list -v -keystore <release-keystore.jks> -alias <key-alias>
    ```

3. **Google Services Gradle plugin** — Already wired in this repo; verify in `android/app/build.gradle.kts` (`id("com.google.gms.google-services")`) and `android/settings.gradle.kts` (`id("com.google.gms.google-services") version "4.4.2" apply false`).

### Required OAuth scopes

The app uses `https://www.googleapis.com/auth/drive.file` (file-level access only — no full Drive access). Consent screen: **External**, add `drive.file` scope, add test users while in Testing.

### AndroidManifest queries

`android/app/src/main/AndroidManifest.xml` already contains for Android 11+ package visibility:
```xml
<queries>
    <package android:name="com.google.android.gms" />
    <package android:name="com.android.vending" />
</queries>
```

### Troubleshooting

- **Sign-in returns null:** User cancelled the Google account picker. This is normal.
- **"Sign-in failed" error:** Check that `google-services.json` exists and matches the `applicationId`. Check SHA-1/SHA-256 fingerprints in Cloud Console.
- **"Authentication expired":** Token refresh failed. Sign out and sign in again.
- **"No internet connection":** Network unavailable. Backup will be queued for retry.
- **Full troubleshooting** (DEVELOPER_ERROR 10, empty `oauth_client`, queued reconnect, `adb logcat`) → [`docs/SETUP.md` §7](docs/SETUP.md#7-troubleshooting).

## Routes

- `/dashboard`, `/customers` (`/new`, `/:id`, `/:id/edit`), `/debts` (`/new?customerId`, `/:id`, `/:id/edit`), `/payments` (`/new?debtId`), `/settings`, `/about`, `/settings/backup`, `/settings/backup/browse`.

## Release

1. Bump `version` in **both** `pubspec.yaml` and `assets/release_notes/current.json`
2. Tag `v<version>` - CI fails if `tag != pubspec != notes`
3. Push tag -> `.github/workflows/release.yml` runs: `verify_version.py` (tag = pubspec = notes) -> `test_release_scripts.py` (validates note generation) -> `flutter analyze` -> `flutter test` -> `configure_signing.py` (GH secrets -> keystore) -> `flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64` -> `prepare_release.py` + `generate_release_notes.py` -> GitHub Release with `RELEASE_NOTES.md` (5 helpers in `.github/scripts/`)

```sh
# example
# edit pubspec.yaml: 1.0.44+43
# edit assets/release_notes/current.json: { "version": "1.0.44", ... }
git commit -m "release: v1.0.44"
git tag v1.0.44 && git push origin v1.0.44
```