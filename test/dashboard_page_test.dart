import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:utang_tracker/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:utang_tracker/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:utang_tracker/features/payments/domain/entities/payment.dart';

void main() {
  testWidgets('activity date and time appear with label below amount', (
    tester,
  ) async {
    final database = AppDatabase.forTesting();
    addTearDown(database.close);

    final activityDate = DateTime(2026, 7, 15, 14, 5);
    final payment = Payment(
      id: 'activity-id',
      debtId: 'debt-id',
      amount: Money.fromPesos(125),
      paymentDate: activityDate,
      paymentMethod: 'GCash',
      createdAt: activityDate,
      customerName: 'Maria Santos',
    );

    final data = DashboardData(
      outstandingBalance: Money.zero(),
      collectedToday: Money.zero(),
      activeDebtsCount: 1,
      totalCustomers: 1,
      recentDebts: const [],
      recentPayments: [payment],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          dashboardRepositoryProvider.overrideWithValue(
            _FakeDashboardRepository(data),
          ),
        ],
        child: const MaterialApp(home: DashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    final dateAndTime = find.text(
      DateFormatters.smartTimestamp(
        activityDate,
        relativeTo: DateTime.now(),
        locale: 'en-US',
        use24HourFormat: false,
      ),
    );
    final label = find.text('Bayad');
    final amount = find.text(Money.fromPesos(125).format());

    expect(dateAndTime, findsOneWidget);
    expect(tester.widget<Text>(dateAndTime).style?.fontWeight, FontWeight.w500);
    expect(label, findsOneWidget);
    expect(find.text('GCash'), findsNothing);
    expect(amount, findsOneWidget);
    expect(
      tester.getTopLeft(label).dy,
      greaterThan(tester.getTopLeft(amount).dy),
    );
    expect(
      tester.getTopLeft(label).dy,
      closeTo(tester.getTopLeft(dateAndTime).dy, 1),
    );
    expect(
      tester.getTopRight(label).dx,
      closeTo(tester.getTopRight(amount).dx, 1),
    );
  });
}

class _FakeDashboardRepository implements DashboardRepository {
  const _FakeDashboardRepository(this.data);

  final DashboardData data;

  @override
  Future<DashboardSummary> getSummary() async => DashboardSummary(
        outstandingBalance: data.outstandingBalance,
        collectedToday: data.collectedToday,
        activeDebtsCount: data.activeDebtsCount,
        totalCustomers: data.totalCustomers,
        recentActivity: const [],
      );

  @override
  Future<DashboardData> getDashboardData() async => data;
}
