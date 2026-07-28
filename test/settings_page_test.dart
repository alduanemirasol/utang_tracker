import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/features/settings/presentation/pages/settings_page.dart';
void main() {
  testWidgets('settings page shows Backup & Restore and About menu items', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsPage()),
      ),
    );
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Export or replace your ledger data'), findsOneWidget);
    expect(find.text('App version and updates'), findsOneWidget);
  });
}
