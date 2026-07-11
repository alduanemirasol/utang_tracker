import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/update/app_version.dart';

/// A versioned GitHub release that includes a downloadable APK.
class GithubReleaseUpdate {
  const GithubReleaseUpdate({
    required this.version,
    required this.tagName,
    required this.apkUrl,
    required this.apkName,
    this.releaseNotes,
  });

  final AppVersion version;
  final String tagName;
  final String apkUrl;
  final String apkName;
  final String? releaseNotes;
}

/// Fetches versioned releases and downloads APK assets from GitHub.
class GithubReleaseService {
  GithubReleaseService({
    http.Client? client,
    this.owner = AppConstants.githubOwner,
    this.repo = AppConstants.githubRepo,
    DeviceInfoPlugin? deviceInfo,
  }) : _client = client ?? http.Client(),
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final http.Client _client;
  final DeviceInfoPlugin _deviceInfo;
  final String owner;
  final String repo;

  static final _semverTag = RegExp(r'^v?\d+\.\d+\.\d+$');

  /// Known split-APK ABIs produced by `flutter build apk --split-per-abi`.
  static const preferredAbiOrder = ['arm64-v8a', 'armeabi-v7a', 'x86_64'];

  Uri get _releasesUri => Uri.https(
    'api.github.com',
    '/repos/$owner/$repo/releases',
    {'per_page': '30'},
  );

  Map<String, String> get _headers => {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'utang-tracker',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  /// Device ABIs in preference order (best first), then known defaults.
  Future<List<String>> resolvePreferredAbis() async {
    if (!Platform.isAndroid) return preferredAbiOrder;
    try {
      final android = await _deviceInfo.androidInfo;
      final supported = android.supportedAbis
          .map((a) => a.toLowerCase())
          .where((a) => a.isNotEmpty)
          .toList();
      if (supported.isEmpty) return preferredAbiOrder;

      // Keep device order first, then fill remaining known ABIs as fallbacks.
      final ordered = <String>[];
      for (final abi in supported) {
        if (!ordered.contains(abi)) ordered.add(abi);
      }
      for (final abi in preferredAbiOrder) {
        if (!ordered.contains(abi)) ordered.add(abi);
      }
      return ordered;
    } catch (_) {
      return preferredAbiOrder;
    }
  }

  /// Picks the best APK asset for [preferredAbis] from [apkAssets] name→url.
  static MapEntry<String, String>? pickApkAsset(
    Map<String, String> apkAssets, {
    List<String> preferredAbis = preferredAbiOrder,
  }) {
    if (apkAssets.isEmpty) return null;

    for (final abi in preferredAbis) {
      for (final entry in apkAssets.entries) {
        final name = entry.key.toLowerCase();
        if (name.endsWith('.apk') && name.contains(abi.toLowerCase())) {
          return entry;
        }
      }
    }

    // Universal / unmatched fallback (e.g. app-release.apk).
    for (final entry in apkAssets.entries) {
      if (entry.key.toLowerCase().endsWith('.apk')) {
        return entry;
      }
    }
    return null;
  }

  /// Returns the newest stable semver release that has an `.apk` asset, or null.
  Future<GithubReleaseUpdate?> fetchLatestApkRelease() async {
    final preferredAbis = await resolvePreferredAbis();
    final response = await _client.get(_releasesUri, headers: _headers);
    if (response.statusCode != 200) {
      throw AppException(
        'Could not check for updates (HTTP ${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! List) {
      throw const AppException('Unexpected GitHub releases response.');
    }

    GithubReleaseUpdate? best;
    for (final item in body) {
      if (item is! Map<String, dynamic>) continue;
      if (item['draft'] == true) continue;
      if (item['prerelease'] == true) continue;

      final tagName = item['tag_name'] as String? ?? '';
      // Ignore rolling non-semver tags such as "latest".
      if (!_semverTag.hasMatch(tagName)) continue;

      final version = AppVersion.tryParse(tagName);
      if (version == null) continue;

      final assets = item['assets'];
      if (assets is! List) continue;

      final apkAssets = <String, String>{};
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = asset['name'] as String? ?? '';
        final url = asset['browser_download_url'] as String?;
        if (name.toLowerCase().endsWith('.apk') &&
            url != null &&
            url.isNotEmpty) {
          apkAssets[name] = url;
        }
      }

      final picked = pickApkAsset(apkAssets, preferredAbis: preferredAbis);
      if (picked == null) continue;

      final notes = item['body'] as String?;
      final candidate = GithubReleaseUpdate(
        version: version,
        tagName: tagName,
        apkUrl: picked.value,
        apkName: picked.key,
        releaseNotes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      );

      if (best == null || candidate.version.isNewerThan(best.version)) {
        best = candidate;
      }
    }

    return best;
  }

  /// Downloads [update.apkUrl] to app cache. Reports [onProgress] 0.0–1.0 when
  /// content length is known; otherwise reports null progress after chunks.
  Future<File> downloadApk(
    GithubReleaseUpdate update, {
    void Function(double? progress)? onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(update.apkUrl));
    request.headers.addAll(_headers);
    final response = await _client.send(request);

    if (response.statusCode != 200) {
      throw AppException('Download failed (HTTP ${response.statusCode}).');
    }

    final total = response.contentLength;
    final dir = await getTemporaryDirectory();
    final safeName = update.apkName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final file = File(p.join(dir.path, 'utang_update_$safeName'));
    final sink = file.openWrite();

    var received = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (onProgress != null) {
          if (total != null && total > 0) {
            onProgress(received / total);
          } else {
            onProgress(null);
          }
        }
      }
      await sink.flush();
    } catch (e) {
      await sink.close();
      if (await file.exists()) {
        await file.delete();
      }
      throw AppException('Download interrupted: $e');
    }
    await sink.close();

    if (received == 0) {
      if (await file.exists()) {
        await file.delete();
      }
      throw const AppException('Downloaded file is empty.');
    }

    onProgress?.call(1.0);
    return file;
  }

  void close() => _client.close();
}
