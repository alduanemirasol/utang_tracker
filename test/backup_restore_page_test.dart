import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/features/backup/presentation/pages/backup_restore_page.dart';

void main() {
  testWidgets('explains replacement and exposes both backup actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BackupRestorePage())),
    );

    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('Save backup'), findsOneWidget);
    expect(find.text('Choose backup to restore'), findsOneWidget);
    expect(find.textContaining('Restore replaces data'), findsOneWidget);
    expect(find.textContaining('does not merge or duplicate'), findsOneWidget);
    expect(find.textContaining('rollback backup'), findsWidgets);
  });
}
