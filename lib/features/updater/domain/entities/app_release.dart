import 'package:equatable/equatable.dart';

class ReleaseAsset extends Equatable {
  const ReleaseAsset({
    required this.name,
    required this.browserDownloadUrl,
    required this.sizeBytes,
  });

  final String name;
  final String browserDownloadUrl;
  final int sizeBytes;

  @override
  List<Object?> get props => [name, browserDownloadUrl, sizeBytes];
}

class AppRelease extends Equatable {
  const AppRelease({
    required this.tagName,
    required this.version,
    required this.releaseNotes,
    required this.publishedAt,
    required this.isDraft,
    required this.isPrerelease,
    required this.assets,
  });

  /// Raw tag from GitHub, e.g. `v1.2.0`.
  final String tagName;

  /// Semver string with leading `v` stripped, e.g. `1.2.0`.
  final String version;

  final String releaseNotes;
  final DateTime publishedAt;
  final bool isDraft;
  final bool isPrerelease;
  final List<ReleaseAsset> assets;

  @override
  List<Object?> get props => [
    tagName,
    version,
    releaseNotes,
    publishedAt,
    isDraft,
    isPrerelease,
    assets,
  ];
}
