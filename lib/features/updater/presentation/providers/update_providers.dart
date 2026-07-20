import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/features/updater/data/repositories/update_repository_impl.dart';
import 'package:utang_tracker/features/updater/domain/entities/app_release.dart';
import 'package:utang_tracker/features/updater/domain/repositories/update_repository.dart';

final updateRepositoryProvider = Provider<UpdateRepository>(
  (_) => UpdateRepositoryImpl(),
);

final updateNotifierProvider =
    NotifierProvider<UpdateNotifier, UpdateState>(UpdateNotifier.new);

sealed class UpdateState {
  const UpdateState();
}

class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

class UpdateNotAvailable extends UpdateState {
  const UpdateNotAvailable();
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable({
    required this.release,
    required this.asset,
    required this.currentVersion,
  });

  final AppRelease release;
  final ReleaseAsset asset;
  final String currentVersion;
}

class UpdateDownloading extends UpdateState {
  const UpdateDownloading({required this.release, required this.progress});

  final AppRelease release;

  final double progress;
}

class UpdateDownloaded extends UpdateState {
  const UpdateDownloaded({required this.release, required this.apkPath});

  final AppRelease release;
  final String apkPath;
}

class UpdateInstalling extends UpdateState {
  const UpdateInstalling();
}

class UpdatePermissionRequired extends UpdateState {
  const UpdatePermissionRequired({
    required this.release,
    required this.apkPath,
  });

  final AppRelease release;
  final String apkPath;
}

class UpdateError extends UpdateState {
  const UpdateError({
    required this.message,
    this.isNetworkError = false,
    this.isPermissionError = false,
  });

  final String message;
  final bool isNetworkError;
  final bool isPermissionError;
}

class UpdateNotifier extends Notifier<UpdateState> {
  static const _channel = MethodChannel(AppConstants.updaterChannel);

  bool _busy = false;

  @override
  UpdateState build() => const UpdateIdle();

  UpdateRepository get _repo => ref.read(updateRepositoryProvider);

  /// Silent mode avoids flashing "up to date" on startup.
  Future<void> checkForUpdates({bool silent = false}) async {
    if (_busy) return;
    _busy = true;
    state = const UpdateChecking();

    try {
      await _repo.saveLastCheckTime(DateTime.now());

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final release = await _repo.fetchLatestRelease();

      if (release == null || !isNewerVersion(currentVersion, release.version)) {
        state = silent ? const UpdateIdle() : const UpdateNotAvailable();
        return;
      }

      final dismissed = await _repo.loadDismissedVersion();
      if (silent && dismissed == release.version) {
        state = const UpdateIdle();
        return;
      }

      final asset = selectApkAsset(release.assets, AppConstants.supportedAbis);
      if (asset == null) {
        state = silent
            ? const UpdateIdle()
            : const UpdateError(message: 'No compatible APK found in this release.');
        return;
      }

      state = UpdateAvailable(
        release: release,
        asset: asset,
        currentVersion: currentVersion,
      );
    } on AppException catch (e) {
      final isNetwork = e.message.contains('internet') ||
          e.message.contains('Network error');
      state = UpdateError(
        message: e.message,
        isNetworkError: isNetwork,
      );
    } catch (e) {
      state = UpdateError(message: 'Unexpected error: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> download() async {
    final current = state;
    if (current is! UpdateAvailable) return;
    if (_busy) return;
    _busy = true;

    state = UpdateDownloading(release: current.release, progress: 0);

    try {
      await _repo.cleanupOldApks();
      final path = await _repo.downloadApk(current.asset, (p) {
        state = UpdateDownloading(release: current.release, progress: p);
      });
      state = UpdateDownloaded(release: current.release, apkPath: path);
    } on AppException catch (e) {
      final isNetwork = e.message.contains('internet') ||
          e.message.contains('interrupted');
      state = UpdateError(
        message: e.message,
        isNetworkError: isNetwork,
      );
    } catch (e) {
      state = UpdateError(message: 'Download failed: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> install() async {
    final current = state;
    final apkPath = switch (current) {
      UpdateDownloaded(:final apkPath) => apkPath,
      UpdatePermissionRequired(:final apkPath) => apkPath,
      _ => null,
    };
    if (apkPath == null) return;

    try {
      final canInstall = await _channel.invokeMethod<bool>('canInstallUnknownApps') ?? false;
      if (!canInstall) {
        state = UpdatePermissionRequired(
          release: current is UpdateDownloaded
              ? current.release
              : (current as UpdatePermissionRequired).release,
          apkPath: apkPath,
        );
        return;
      }

      state = const UpdateInstalling();
      await _channel.invokeMethod<void>('installApk', {'path': apkPath});
      state = const UpdateIdle();
    } on PlatformException catch (e) {
      state = UpdateError(message: e.message ?? 'Installation failed.');
    }
  }

  Future<void> openInstallSettings() async {
    try {
      await _channel.invokeMethod<void>('openInstallSettings');
    } on PlatformException catch (e) {
      state = UpdateError(message: e.message ?? 'Could not open settings.');
    }
  }

  Future<void> dismiss() async {
    final current = state;
    final version = switch (current) {
      UpdateAvailable(:final release) => release.version,
      UpdateDownloading(:final release) => release.version,
      UpdateDownloaded(:final release) => release.version,
      UpdatePermissionRequired(:final release) => release.version,
      _ => null,
    };
    if (version != null) await _repo.saveDismissedVersion(version);
    state = const UpdateIdle();
  }

  void reset() => state = const UpdateIdle();
}
