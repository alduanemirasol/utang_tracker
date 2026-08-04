import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_period.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_report.dart';
import 'package:utang_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:utang_tracker/features/reports/presentation/pages/collection_report_page.dart';

class _FakeReportRepository implements ReportRepository {
  _FakeReportRepository({this.empty = false});

  final bool empty;

  @override
  Future<CollectionReport> getCollectionReport({
    required CollectionPeriod period,
    required DateTime now,
  }) async {
    return CollectionReport(
      period: period,
      collectedTotal: empty ? Money.zero() : Money.fromPesos(225),
      paymentCount: empty ? 0 : 2,
      perCustomer: empty
          ? []
          : [
              CustomerCollection(
                customerName: 'Maria Santos',
                total: Money.fromPesos(150),
                paymentCount: 1,
              ),
              CustomerCollection(
                customerName: 'Juan Dela Cruz',
                total: Money.fromPesos(75),
                paymentCount: 1,
              ),
            ],
      overdueBuckets: empty
          ? List.generate(
              3,
              (_) =>
                  OverdueBucket(label: '', total: Money.zero(), debtCount: 0),
            )
          : [
              OverdueBucket(
                label: '1\u20137 days overdue',
                total: Money.fromPesos(100),
                debtCount: 2,
              ),
              OverdueBucket(
                label: '8\u201330 days overdue',
                total: Money.zero(),
                debtCount: 0,
              ),
              OverdueBucket(
                label: '30+ days overdue',
                total: Money.zero(),
                debtCount: 0,
              ),
            ],
    );
  }
}

void main() {
  Widget build(ReportRepository repository) {
    return ProviderScope(
      overrides: [reportRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: CollectionReportPage()),
    );
  }

  testWidgets('renders collected total, customer breakdown and overdue', (
    tester,
  ) async {
    await tester.pumpWidget(build(_FakeReportRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Collection Report'), findsOneWidget);
    expect(find.text('Today'), findsNWidgets(2));
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);
    expect(find.text('Collected'), findsOneWidget);
    expect(find.text(Money.fromPesos(225).format()), findsOneWidget);
    expect(find.text('2 payments'), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('By customer'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('1\u20137 days overdue'), findsOneWidget);
    expect(find.text(Money.fromPesos(100).format()), findsOneWidget);
  });

  testWidgets('shows empty states when nothing to report', (tester) async {
    await tester.pumpWidget(build(_FakeReportRepository(empty: true)));
    await tester.pumpAndSettle();

    expect(find.text('Wala pay bayad niining panahona'), findsOneWidget);
    expect(find.text('Wala nay overdue nga utang'), findsOneWidget);
    expect(find.text('0 payments'), findsOneWidget);
  });
}
