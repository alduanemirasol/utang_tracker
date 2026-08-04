import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/debts/domain/repositories/debt_repository.dart';
import 'package:utang_tracker/features/payments/domain/repositories/payment_repository.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_period.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_report.dart';
import 'package:utang_tracker/features/reports/domain/overdue_aging.dart';
import 'package:utang_tracker/features/reports/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({required this.debts, required this.payments});

  final DebtRepository debts;
  final PaymentRepository payments;

  @override
  Future<CollectionReport> getCollectionReport({
    required CollectionPeriod period,
    required DateTime now,
  }) async {
    final (start, end) = period.localRange(now);
    final paymentsInRange = await payments.getBetween(
      start: start,
      end: end,
    );
    final allDebts = await debts.getAll();

    var totalCents = 0;
    final perCustomer = <String, ({int cents, int count})>{};
    for (final payment in paymentsInRange) {
      final name = payment.customerName ?? 'Customer';
      final entry = perCustomer[name] ?? (cents: 0, count: 0);
      perCustomer[name] = (
        cents: entry.cents + payment.amount.centavos,
        count: entry.count + 1,
      );
      totalCents += payment.amount.centavos;
    }

    final breakdown = perCustomer.entries
        .map(
          (entry) => CustomerCollection(
            customerName: entry.key,
            total: Money.fromCentavos(entry.value.cents),
            paymentCount: entry.value.count,
          ),
        )
        .toList()
      ..sort((a, b) => b.total.centavos.compareTo(a.total.centavos));

    return CollectionReport(
      period: period,
      collectedTotal: Money.fromCentavos(totalCents),
      paymentCount: paymentsInRange.length,
      perCustomer: breakdown,
      overdueBuckets: OverdueAging.compute(allDebts, now: now),
    );
  }
}