import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('screen and component colors come from AppColors', () {
    final lib = Directory('lib');
    final offenders = <String>[];
    final directColor = RegExp(r'\bColor\s*\(');
    final frameworkColor = RegExp(r'\b(?:Colors|CupertinoColors)\.');

    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('app_colors.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (directColor.hasMatch(line) || frameworkColor.hasMatch(line)) {
          offenders.add('${entity.path}:${index + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Add semantic colors to AppColors instead of declaring them in '
          'screens, components, or AppTheme.\n${offenders.join('\n')}',
    );
  });
}
