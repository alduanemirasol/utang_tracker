import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';

void main() {
  test('app bar titles use the shared 20 px size', () {
    final titleStyle = AppTheme.light().appBarTheme.titleTextStyle;

    expect(titleStyle?.fontSize, 20);
  });
}
