import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/features/updates/domain/entities/app_update.dart';

void main() {
  test('parses a valid update manifest', () {
    final update = AppUpdate.fromJson({
      'versionCode': 7,
      'versionName': '1.0.6',
      'packageName': 'com.example.utang_tracker',
      'apkUrl': 'https://updates.example.com/app.apk',
      'sha256': 'a' * 64,
      'releaseNotes': 'Fixes.',
      'required': true,
    });

    expect(update.versionCode, 7);
    expect(update.apkUri.scheme, 'https');
    expect(update.isRequired, isTrue);
  });

  test('rejects an insecure APK URL', () {
    expect(
      () => AppUpdate.fromJson({
        'versionCode': 7,
        'versionName': '1.0.6',
        'packageName': 'com.example.utang_tracker',
        'apkUrl': 'http://updates.example.com/app.apk',
        'sha256': 'a' * 64,
      }),
      throwsFormatException,
    );
  });

  test('rejects an invalid SHA-256 digest', () {
    expect(
      () => AppUpdate.fromJson({
        'versionCode': 7,
        'versionName': '1.0.6',
        'packageName': 'com.example.utang_tracker',
        'apkUrl': 'https://updates.example.com/app.apk',
        'sha256': 'not-a-digest',
      }),
      throwsFormatException,
    );
  });
}
