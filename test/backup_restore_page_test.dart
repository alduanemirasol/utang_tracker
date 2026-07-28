import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
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

  testWidgets('success snackbar uses green background and white text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BackupRestorePage())),
    );

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          'Backup saved successfully.',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
      ),
    );
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, AppColors.success);

    final textWidget = tester.widget<Text>(
      find.text('Backup saved successfully.'),
    );
    expect(textWidget.style?.color, AppColors.textOnPrimary);
  });

  testWidgets('error snackbar uses red background and white text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BackupRestorePage())),
    );

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.danger,
        content: Text(
          'Something went wrong.',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
      ),
    );
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, AppColors.danger);

    final textWidget = tester.widget<Text>(find.text('Something went wrong.'));
    expect(textWidget.style?.color, AppColors.textOnPrimary);
  });
}
