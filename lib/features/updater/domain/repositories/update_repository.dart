import 'package:utang_tracker/features/updater/domain/entities/app_release.dart';

abstract interface class UpdateRepository {
  /// Fetches the latest non-draft, non-prerelease GitHub Release.
  /// Returns `null` when no release exists yet.
  Future<AppRelease?> fetchLatestRelease();

  /// Downloads [asset] to a temp directory, reporting fractional [onProgress]
  /// (0.0–1.0). Returns the local file path when complete.
  Future<String> downloadApk(
    ReleaseAsset asset,
    void Function(double progress) onProgress,
  );

  Future<void> saveLastCheckTime(DateTime time);
  Future<DateTime?> loadLastCheckTime();

  Future<void> saveDismissedVersion(String version);
  Future<String?> loadDismissedVersion();

  /// Deletes obsolete APK files from the download directory.
  Future<void> cleanupOldApks();
}
