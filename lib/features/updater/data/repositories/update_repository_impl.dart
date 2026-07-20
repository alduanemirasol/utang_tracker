import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/features/updater/data/models/github_release_dto.dart';
import 'package:utang_tracker/features/updater/domain/entities/app_release.dart';
import 'package:utang_tracker/features/updater/domain/repositories/update_repository.dart';

const _keyLastCheck = 'updater_last_check_ms';
const _keyDismissedVersion = 'updater_dismissed_version';

class UpdateRepositoryImpl implements UpdateRepository {
  UpdateRepositoryImpl({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  @override
  Future<AppRelease?> fetchLatestRelease() async {
    final uri = Uri.parse(
      '${AppConstants.githubApiBaseUrl}/repos'
      '/${AppConstants.githubOwner}/${AppConstants.githubRepo}'
      '/releases/latest',
    );

    final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {'Accept': 'application/vnd.github+json'},
      );
    } on SocketException {
      throw const AppException('No internet connection.');
    } on http.ClientException catch (e) {
      throw AppException('Network error: ${e.message}');
    }

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw AppException(
        'GitHub API error ${response.statusCode}. Please try again later.',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final release = GithubReleaseDto.fromJson(json);

    if (release.isDraft || release.isPrerelease) return null;
    return release;
  }

  @override
  Future<String> downloadApk(
    ReleaseAsset asset,
    void Function(double progress) onProgress,
  ) async {
    final dir = await _updateDir();
    final file = File('${dir.path}/${asset.name}');

    if (await file.exists() && await file.length() == asset.sizeBytes) {
      onProgress(1.0);
      return file.path;
    }

    final uri = Uri.parse(asset.browserDownloadUrl);
    final http.StreamedResponse response;
    try {
      response = await _client.send(http.Request('GET', uri));
    } on SocketException {
      throw const AppException('No internet connection.');
    } on http.ClientException catch (e) {
      throw AppException('Download failed: ${e.message}');
    }

    if (response.statusCode != 200) {
      throw AppException('Download error ${response.statusCode}.');
    }

    final totalBytes = response.contentLength ?? asset.sizeBytes;
    var received = 0;
    final sink = file.openWrite();

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (totalBytes > 0) onProgress(received / totalBytes);
      }
    } catch (e) {
      await sink.close();
      if (await file.exists()) await file.delete();
      throw AppException('Download interrupted: $e');
    }

    await sink.close();

    await _validateApk(file);
    return file.path;
  }

  @override
  Future<void> saveLastCheckTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastCheck, time.millisecondsSinceEpoch);
  }

  @override
  Future<DateTime?> loadLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyLastCheck);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<void> saveDismissedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDismissedVersion, version);
  }

  @override
  Future<String?> loadDismissedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDismissedVersion);
  }

  @override
  Future<void> cleanupOldApks() async {
    final dir = await _updateDir();
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.apk')) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  Future<Directory> _updateDir() async {
    final base = await getExternalStorageDirectory();
    final dir = Directory('${base!.path}/utang_tracker_updates');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _validateApk(File file) async {
    if (!file.path.endsWith('.apk')) {
      throw const AppException('Downloaded file is not a valid APK.');
    }
    final bytes = await file.openRead(0, 4).expand((b) => b).toList();
    if (bytes.length < 4 ||
        bytes[0] != 0x50 ||
        bytes[1] != 0x4B ||
        bytes[2] != 0x03 ||
        bytes[3] != 0x04) {
      await file.delete();
      throw const AppException('Downloaded file is not a valid APK (bad magic bytes).');
    }
  }
}

/// Best ABI match from [assets]; falls back to universal APK.
ReleaseAsset? selectApkAsset(
  List<ReleaseAsset> assets,
  List<String> abis, {
  String prefix = AppConstants.apkAssetPrefix,
  String universalAbi = AppConstants.universalAbiName,
}) {
  for (final abi in abis) {
    final match = assets.where((a) => a.name.startsWith('$prefix-$abi-')).firstOrNull;
    if (match != null) return match;
  }
  return assets
      .where((a) => a.name.startsWith('$prefix-$universalAbi-'))
      .firstOrNull;
}

/// True when [latestVersion] > [currentVersion]; pads missing segments.
bool isNewerVersion(String currentVersion, String latestVersion) {
  return Version.parse(_pad(latestVersion)) > Version.parse(_pad(currentVersion));
}

String _pad(String v) {
  final parts = v.split('.');
  while (parts.length < 3) {
    parts.add('0');
  }
  return parts.join('.');
}
