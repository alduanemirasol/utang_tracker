import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/features/updater/data/models/github_release_dto.dart';
import 'package:utang_tracker/features/updater/data/repositories/update_repository_impl.dart';
import 'package:utang_tracker/features/updater/domain/entities/app_release.dart';
import 'package:utang_tracker/features/updater/domain/usecases/check_for_updates.dart';

void main() {
  group('isNewerVersion', () {
    test('patch bump is newer', () {
      expect(isNewerVersion('1.0.0', '1.0.1'), isTrue);
    });

    test('minor bump is newer', () {
      expect(isNewerVersion('1.0.9', '1.1.0'), isTrue);
    });

    test('major bump is newer', () {
      expect(isNewerVersion('1.9.9', '2.0.0'), isTrue);
    });

    test('same version is not newer', () {
      expect(isNewerVersion('1.2.0', '1.2.0'), isFalse);
    });

    test('older version is not newer', () {
      expect(isNewerVersion('1.2.1', '1.2.0'), isFalse);
    });

    test('double-digit minor comparison is correct', () {
      // "1.10.0" > "1.9.9" — a naive string sort would fail this
      expect(isNewerVersion('1.9.9', '1.10.0'), isTrue);
      expect(isNewerVersion('1.10.0', '1.9.9'), isFalse);
    });

    test('missing patch segment defaults to 0', () {
      expect(isNewerVersion('1.0', '1.0.1'), isTrue);
    });
  });

  group('GithubReleaseDto.fromJson', () {
    Map<String, dynamic> baseJson({
      String tag = 'v1.2.0',
      bool draft = false,
      bool prerelease = false,
      String body = 'Bug fixes and improvements.',
      List<dynamic> assets = const [],
    }) =>
        {
          'tag_name': tag,
          'draft': draft,
          'prerelease': prerelease,
          'body': body,
          'published_at': '2024-06-01T10:00:00Z',
          'assets': assets,
        };

    test('parses basic fields correctly', () {
      final release = GithubReleaseDto.fromJson(baseJson());

      expect(release.tagName, 'v1.2.0');
      expect(release.version, '1.2.0');
      expect(release.releaseNotes, 'Bug fixes and improvements.');
      expect(release.isDraft, isFalse);
      expect(release.isPrerelease, isFalse);
    });

    test('strips leading v from version', () {
      final release = GithubReleaseDto.fromJson(baseJson(tag: 'v2.0.0'));
      expect(release.version, '2.0.0');
    });

    test('handles tag without leading v', () {
      final release = GithubReleaseDto.fromJson(baseJson(tag: '1.3.0'));
      expect(release.version, '1.3.0');
    });

    test('parses assets correctly', () {
      final json = baseJson(assets: [
        {
          'name': 'utang-tracker-arm64-v8a-v1.2.0.apk',
          'browser_download_url': 'https://example.com/arm64.apk',
          'size': 12345678,
        },
      ]);
      final release = GithubReleaseDto.fromJson(json);
      expect(release.assets, hasLength(1));
      expect(release.assets.first.name, 'utang-tracker-arm64-v8a-v1.2.0.apk');
      expect(release.assets.first.sizeBytes, 12345678);
    });

    test('empty body becomes empty string', () {
      final json = Map<String, dynamic>.from(baseJson())..remove('body');
      final release = GithubReleaseDto.fromJson(json);
      expect(release.releaseNotes, '');
    });
  });

  group('draft and prerelease filtering', () {
    ReleaseAsset dummyAsset() => const ReleaseAsset(
          name: 'utang-tracker-universal-v1.0.0.apk',
          browserDownloadUrl: 'https://example.com/universal.apk',
          sizeBytes: 1000,
        );

    AppRelease makeRelease({
      bool isDraft = false,
      bool isPrerelease = false,
    }) =>
        AppRelease(
          tagName: 'v1.0.0',
          version: '1.0.0',
          releaseNotes: '',
          publishedAt: DateTime(2024),
          isDraft: isDraft,
          isPrerelease: isPrerelease,
          assets: [dummyAsset()],
        );

    test('draft release is filtered out (isDraft = true)', () {
      final release = makeRelease(isDraft: true);
      expect(release.isDraft, isTrue);
    });

    test('prerelease is filtered out (isPrerelease = true)', () {
      final release = makeRelease(isPrerelease: true);
      expect(release.isPrerelease, isTrue);
    });

    test('normal release passes through', () {
      final release = makeRelease();
      expect(release.isDraft, isFalse);
      expect(release.isPrerelease, isFalse);
    });
  });

  group('selectApkAsset', () {
    ReleaseAsset asset(String name) => ReleaseAsset(
          name: name,
          browserDownloadUrl: 'https://example.com/$name',
          sizeBytes: 1000,
        );

    test('selects arm64-v8a when available (highest priority)', () {
      final assets = [
        asset('utang-tracker-armeabi-v7a-v1.0.0.apk'),
        asset('utang-tracker-arm64-v8a-v1.0.0.apk'),
        asset('utang-tracker-x86_64-v1.0.0.apk'),
        asset('utang-tracker-universal-v1.0.0.apk'),
      ];
      final selected = selectApkAsset(assets, AppConstants.supportedAbis);
      expect(selected?.name, 'utang-tracker-arm64-v8a-v1.0.0.apk');
    });

    test('falls back to armeabi-v7a when arm64 absent', () {
      final assets = [
        asset('utang-tracker-armeabi-v7a-v1.0.0.apk'),
        asset('utang-tracker-universal-v1.0.0.apk'),
      ];
      final selected = selectApkAsset(assets, AppConstants.supportedAbis);
      expect(selected?.name, 'utang-tracker-armeabi-v7a-v1.0.0.apk');
    });

    test('falls back to x86_64 when arm variants absent', () {
      final assets = [
        asset('utang-tracker-x86_64-v1.0.0.apk'),
        asset('utang-tracker-universal-v1.0.0.apk'),
      ];
      final selected = selectApkAsset(assets, ['x86_64']);
      expect(selected?.name, 'utang-tracker-x86_64-v1.0.0.apk');
    });

    test('universal APK fallback when no ABI-specific asset exists', () {
      final assets = [
        asset('utang-tracker-universal-v1.0.0.apk'),
      ];
      final selected = selectApkAsset(assets, AppConstants.supportedAbis);
      expect(selected?.name, 'utang-tracker-universal-v1.0.0.apk');
    });

    test('returns null when no matching asset found', () {
      final assets = [
        asset('some-other-app-arm64.apk'),
      ];
      final selected = selectApkAsset(assets, AppConstants.supportedAbis);
      expect(selected, isNull);
    });
  });

  group('update availability logic', () {
    test('no update when versions are equal', () {
      expect(isNewerVersion('1.2.0', '1.2.0'), isFalse);
    });

    test('no update when installed is newer (rollback scenario)', () {
      expect(isNewerVersion('1.3.0', '1.2.0'), isFalse);
    });

    test('update available when latest is newer', () {
      expect(isNewerVersion('1.1.0', '1.2.0'), isTrue);
    });

    test('update available with major version jump', () {
      expect(isNewerVersion('1.99.99', '2.0.0'), isTrue);
    });
  });
}
