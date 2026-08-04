import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_report.dart';

class OverdueAging {
  OverdueAging._();

  static const List<String> _labels = [
    '1\u20137 days overdue',
    '8\u201330 days overdue',
    '30+ days overdue',
  ];

  static List<OverdueBucket> compute(
    Iterable<Debt> debts, {
    required DateTime now,
  }) {
    final today = _localDay(now);
    final totals = List.filled(3, 0);
    final counts = List.filled(3, 0);

    for (final debt in debts) {
      if (debt.status == DebtStatus.paid) continue;
      final dueDate = debt.dueDate;
      if (dueDate == null) continue;
      final daysOverdue = today.difference(_localDay(dueDate)).inDays;
      if (daysOverdue <= 0) continue;

      final index = switch (daysOverdue) {
        <= 7 => 0,
        <= 30 => 1,
        _ => 2,
      };
      totals[index] += debt.balance.centavos;
      counts[index] += 1;
    }

    return List.generate(
      3,
      (i) => OverdueBucket(
        label: _labels[i],
        total: Money.fromCentavos(totals[i]),
        debtCount: counts[i],
      ),
    );
  }

  static DateTime _localDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}