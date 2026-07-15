import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/recent_activity_item.dart';
import 'package:utang_tracker/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:utang_tracker/features/dashboard/presentation/pages/dashboard_page.dart';

void main() {
  testWidgets('activity time appears below amount and beside date', (
    tester,
  ) async {
    final database = AppDatabase.forTesting();
    addTearDown(database.close);

    final activityDate = DateTime(2026, 7, 15, 14, 5);
    final summary = DashboardSummary(
      outstandingBalance: Money.zero(),
      collectedToday: Money.zero(),
      activeDebtsCount: 1,
      totalCustomers: 1,
      recentActivity: [
        RecentActivityItem(
          type: RecentActivityType.debt,
          id: 'activity-id',
          debtId: 'debt-id',
          customerName: 'Maria Santos',
          amount: Money.fromPesos(125),
          date: activityDate,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          dashboardRepositoryProvider.overrideWithValue(
            _FakeDashboardRepository(summary),
          ),
        ],
        child: const MaterialApp(home: DashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    final typeAndDate = find.text(
      'Debt · ${DateFormatters.formatDate(activityDate)}',
    );
    final time = find.text(DateFormatters.formatTime(activityDate));
    final amount = find.text(Money.fromPesos(125).format());

    expect(typeAndDate, findsOneWidget);
    expect(time, findsOneWidget);
    expect(amount, findsOneWidget);
    expect(
      tester.getTopLeft(time).dy,
      greaterThan(tester.getTopLeft(amount).dy),
    );
    expect(
      tester.getTopLeft(time).dy,
      closeTo(tester.getTopLeft(typeAndDate).dy, 1),
    );
    expect(
      tester.getTopRight(time).dx,
      closeTo(tester.getTopRight(amount).dx, 1),
    );
  });
}

class _FakeDashboardRepository implements DashboardRepository {
  const _FakeDashboardRepository(this.summary);

  final DashboardSummary summary;

  @override
  Future<DashboardSummary> getSummary() async => summary;
}
