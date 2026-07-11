import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/update/app_version.dart';
import 'package:utang_tracker/core/update/github_release_service.dart';

/// Result of checking whether an update is available.
class UpdateCheckResult {
  const UpdateCheckResult({required this.currentVersion, this.update});

  final AppVersion currentVersion;
  final GithubReleaseUpdate? update;

  bool get isUpdateAvailable => update != null;
}

/// Checks GitHub for a newer APK and installs it after download.
class AppUpdateChecker {
  AppUpdateChecker({GithubReleaseService? service})
    : _service = service ?? GithubReleaseService();

  final GithubReleaseService _service;

  Future<UpdateCheckResult> checkForUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final current =
        AppVersion.tryParse(info.version) ?? const AppVersion(0, 0, 0);

    final latest = await _service.fetchLatestApkRelease();
    if (latest == null || !latest.version.isNewerThan(current)) {
      return UpdateCheckResult(currentVersion: current);
    }

    return UpdateCheckResult(currentVersion: current, update: latest);
  }

  Future<void> downloadAndInstall(
    GithubReleaseUpdate update, {
    void Function(double? progress)? onProgress,
  }) async {
    if (!Platform.isAndroid) {
      throw const AppException(
        'In-app APK install is only supported on Android.',
      );
    }

    await _ensureInstallPermission();

    final file = await _service.downloadApk(update, onProgress: onProgress);
    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done) {
      final message = result.message.isNotEmpty
          ? result.message
          : 'Could not open the installer.';
      throw AppException(message);
    }
  }

  Future<void> _ensureInstallPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final status = await Permission.requestInstallPackages.status;
    if (status.isGranted) return;

    final requested = await Permission.requestInstallPackages.request();
    if (!requested.isGranted) {
      // User must enable "Install unknown apps" for this package.
      await openAppSettings();
      throw const AppException(
        'Please allow Utang Tracker to install updates, then try again.',
      );
    }
  }

  void dispose() => _service.close();
}
