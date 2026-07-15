import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/app.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';

void main() {
  testWidgets('app shell shows dashboard title', (tester) async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const UtangTrackerApp(),
      ),
    );

    // Flush post-frame update-check delay and fail-open network check.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Store overview'), findsNothing);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Due reminders'));
    await tester.pumpAndSettle();

    expect(find.text('Due reminders'), findsOneWidget);
    expect(find.text('Nothing needs attention'), findsOneWidget);
  });
}
