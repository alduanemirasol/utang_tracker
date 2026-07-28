import 'package:pub_semver/pub_semver.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/features/updater/domain/entities/app_release.dart';
import 'package:utang_tracker/features/updater/domain/repositories/update_repository.dart';

class CheckForUpdates {
  const CheckForUpdates(this._repo);

  final UpdateRepository _repo;

  Future<CheckResult> call({bool silent = false}) async {
    final currentVersion = await _repo.getCurrentVersion();
    final release = await _repo.fetchLatestRelease();
    await _repo.saveLastCheckTime(DateTime.now());

    if (release == null || !isNewerVersion(currentVersion, release.version)) {
      return const CheckResult(updateAvailable: false);
    }

    final dismissed = await _repo.loadDismissedVersion();
    if (silent && dismissed == release.version) {
      return const CheckResult(updateAvailable: false);
    }

    final deviceAbis = await _repo.getSupportedAbis();
    final asset = selectApkAsset(release.assets, deviceAbis);
    if (asset == null) {
      return CheckResult(
        updateAvailable: false,
        error: 'No compatible APK found in this release.',
      );
    }

    return CheckResult(
      updateAvailable: true,
      release: release,
      asset: asset,
      currentVersion: currentVersion,
    );
  }
}

class CheckResult {
  const CheckResult({
    required this.updateAvailable,
    this.release,
    this.asset,
    this.currentVersion,
    this.error,
  });

  final bool updateAvailable;
  final AppRelease? release;
  final ReleaseAsset? asset;
  final String? currentVersion;
  final String? error;
}

ReleaseAsset? selectApkAsset(
  List<ReleaseAsset> assets,
  List<String> abis, {
  String prefix = AppConstants.apkAssetPrefix,
  String universalAbi = AppConstants.universalAbiName,
}) {
  for (final abi in abis) {
    final match = assets
        .where(
          (a) =>
              a.name.startsWith('$prefix-$abi-') &&
              a.name.toLowerCase().endsWith('.apk'),
        )
        .firstOrNull;
    if (match != null) return match;
  }
  return assets
      .where(
        (a) =>
            a.name.startsWith('$prefix-$universalAbi-') &&
            a.name.toLowerCase().endsWith('.apk'),
      )
      .firstOrNull;
}

bool isNewerVersion(String currentVersion, String latestVersion) {
  return Version.parse(_pad(latestVersion)) >
      Version.parse(_pad(currentVersion));
}

String _pad(String v) {
  final parts = v.split('.');
  while (parts.length < 3) {
    parts.add('0');
  }
  return parts.join('.');
}
