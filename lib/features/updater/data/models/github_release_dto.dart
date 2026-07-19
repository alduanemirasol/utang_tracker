import 'package:utang_tracker/features/updater/domain/entities/app_release.dart';

/// Maps a raw GitHub Releases API JSON object to [AppRelease].
class GithubReleaseDto {
  static AppRelease fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? '';
    final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
    final assets = (json['assets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_assetFromJson)
        .toList(growable: false);

    return AppRelease(
      tagName: tagName,
      version: version,
      releaseNotes: json['body'] as String? ?? '',
      publishedAt: DateTime.parse(
        json['published_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      isDraft: json['draft'] as bool? ?? false,
      isPrerelease: json['prerelease'] as bool? ?? false,
      assets: assets,
    );
  }

  static ReleaseAsset _assetFromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String? ?? '',
      browserDownloadUrl: json['browser_download_url'] as String? ?? '',
      sizeBytes: json['size'] as int? ?? 0,
    );
  }
}
