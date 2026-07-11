import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/update/app_version.dart';

void main() {
  group('AppVersion', () {
    test('parses plain and v-prefixed versions', () {
      expect(AppVersion.tryParse('1.2.3'), const AppVersion(1, 2, 3));
      expect(AppVersion.tryParse('v1.2.3'), const AppVersion(1, 2, 3));
      expect(AppVersion.tryParse('1.0.0+12'), const AppVersion(1, 0, 0));
      expect(AppVersion.tryParse('1.2'), const AppVersion(1, 2, 0));
    });

    test('rejects invalid strings', () {
      expect(AppVersion.tryParse('latest'), isNull);
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse('abc'), isNull);
    });

    test('compares versions', () {
      const a = AppVersion(1, 0, 0);
      const b = AppVersion(1, 0, 1);
      const c = AppVersion(2, 0, 0);
      expect(b.isNewerThan(a), isTrue);
      expect(a.isNewerThan(b), isFalse);
      expect(c.isNewerThan(b), isTrue);
      expect(a.compareTo(a), 0);
    });
  });
}
