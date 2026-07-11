import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/update/github_release_service.dart';

void main() {
  group('GithubReleaseService.pickApkAsset', () {
    test('prefers device arm64 over other split APKs', () {
      final assets = {
        'utang-tracker-v1.0.1-armeabi-v7a.apk': 'https://example/v7a.apk',
        'utang-tracker-v1.0.1-arm64-v8a.apk': 'https://example/v8a.apk',
        'utang-tracker-v1.0.1-x86_64.apk': 'https://example/x86.apk',
      };

      final picked = GithubReleaseService.pickApkAsset(
        assets,
        preferredAbis: const ['arm64-v8a', 'armeabi-v7a', 'x86_64'],
      );

      expect(picked?.key, 'utang-tracker-v1.0.1-arm64-v8a.apk');
      expect(picked?.value, 'https://example/v8a.apk');
    });

    test('falls back to armeabi-v7a when arm64 missing', () {
      final assets = {
        'utang-tracker-v1.0.1-armeabi-v7a.apk': 'https://example/v7a.apk',
        'utang-tracker-v1.0.1-x86_64.apk': 'https://example/x86.apk',
      };

      final picked = GithubReleaseService.pickApkAsset(
        assets,
        preferredAbis: const ['arm64-v8a', 'armeabi-v7a'],
      );

      expect(picked?.key, contains('armeabi-v7a'));
    });

    test('falls back to any apk when no abi match', () {
      final assets = {
        'utang-tracker-v1.0.1.apk': 'https://example/universal.apk',
      };

      final picked = GithubReleaseService.pickApkAsset(
        assets,
        preferredAbis: const ['arm64-v8a'],
      );

      expect(picked?.key, 'utang-tracker-v1.0.1.apk');
    });
  });
}
