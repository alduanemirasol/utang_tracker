import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/features/notifications/domain/entities/debt_reminder.dart';
import 'package:utang_tracker/features/notifications/domain/repositories/reminder_scheduler.dart';
import 'package:utang_tracker/features/settings/presentation/pages/settings_page.dart';

class _FakeReminderScheduler implements ReminderScheduler {
  int rescheduleCount = 0;
  int cancelCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> rescheduleAll(List<DebtReminder> reminders) async {
    rescheduleCount++;
  }

  @override
  Future<void> cancelAll() async {
    cancelCount++;
  }
}

void main() {
  late AppDatabase db;
  late _FakeReminderScheduler fakeScheduler;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting();
    fakeScheduler = _FakeReminderScheduler();
    addTearDown(db.close);
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          reminderSchedulerProvider.overrideWithValue(fakeScheduler),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('settings page shows Backup & Restore and About menu items', (
    tester,
  ) async {
    await pumpSettings(tester);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Export or restore your data'), findsOneWidget);
    expect(find.text('App version and updates'), findsOneWidget);

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(
      listView.padding,
      const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        0,
        AppSpacing.pagePadding,
        AppSpacing.xxl,
      ),
    );
  });

  testWidgets('reminders toggle is on by default and reschedules on enable', (
    tester,
  ) async {
    await pumpSettings(tester);

    final toggle = find.byType(SwitchListTile);
    expect(toggle, findsOneWidget);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(fakeScheduler.cancelCount, 1);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(fakeScheduler.rescheduleCount, 1);
  });
}