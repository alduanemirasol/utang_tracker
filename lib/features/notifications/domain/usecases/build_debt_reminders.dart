import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/debts/domain/repositories/debt_repository.dart';
import 'package:utang_tracker/features/notifications/domain/entities/debt_reminder.dart';

class BuildDebtReminders {
  const BuildDebtReminders(this._debts);

  final DebtRepository _debts;

  Future<List<DebtReminder>> call({DateTime? now}) async {
    final debts = await _debts.getAll();
    return buildDebtReminders(debts, now: now ?? DateTime.now());
  }
}

List<DebtReminder> buildDebtReminders(List<Debt> debts, {DateTime? now}) {
  final today = _localDay(now ?? DateTime.now());
  final reminders = <DebtReminder>[];

  for (final debt in debts) {
    final dueDate = debt.dueDate;
    if (dueDate == null ||
        debt.status == DebtStatus.paid ||
        !debt.balance.isPositive) {
      continue;
    }

    final dueDay = _localDay(dueDate);
    final daysFromToday = dueDay.difference(today).inDays;
    final kind = daysFromToday < 0
        ? DebtReminderKind.overdue
        : DebtReminderKind.dueToday;
    reminders.add(
      DebtReminder(
        debtId: debt.id,
        customerName: debt.customerName ?? 'Customer',
        balance: debt.balance,
        kind: kind,
        scheduledDate: daysFromToday < 0 ? today : dueDay,
      ),
    );
  }

  reminders.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  return reminders;
}

DateTime _localDay(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}