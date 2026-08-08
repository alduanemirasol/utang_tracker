import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/notifications/domain/entities/debt_reminder.dart';
import 'package:utang_tracker/features/notifications/domain/usecases/build_debt_reminders.dart';

Debt _debt({
  required String id,
  DateTime? dueDate,
  DebtStatus status = DebtStatus.unpaid,
  int balancePesos = 100,
  String? customerName = 'Customer',
}) {
  return Debt(
    id: id,
    customerId: 'cust',
    totalAmount: Money.fromPesos(balancePesos),
    paidAmount: status == DebtStatus.unpaid
        ? Money.zero()
        : Money.fromPesos(balancePesos),
    balance: status == DebtStatus.unpaid
        ? Money.fromPesos(balancePesos)
        : Money.zero(),
    status: status,
    transactionDate: DateTime(2026, 1, 1),
    dueDate: dueDate,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    customerName: customerName,
  );
}

void main() {
  final now = DateTime(2026, 8, 8, 12, 0);

  test('creates an overdue reminder for debts due before today', () {
    final reminders = buildDebtReminders(
      [_debt(id: 'overdue', dueDate: DateTime(2026, 8, 1))],
      now: now,
    );
    expect(reminders, hasLength(1));
    final reminder = reminders.single;
    expect(reminder.debtId, 'overdue');
    expect(reminder.kind, DebtReminderKind.overdue);
    expect(reminder.scheduledDate, DateTime(2026, 8, 8));
  });

  test('creates a due-today reminder scheduled on the due date', () {
    final reminders = buildDebtReminders(
      [
        _debt(id: 'today', dueDate: DateTime(2026, 8, 8)),
        _debt(id: 'future', dueDate: DateTime(2026, 8, 15)),
      ],
      now: now,
    );
    expect(reminders, hasLength(2));
    expect(reminders[0].kind, DebtReminderKind.dueToday);
    expect(reminders[0].scheduledDate, DateTime(2026, 8, 8));
    expect(reminders[1].scheduledDate, DateTime(2026, 8, 15));
  });

  test('sorts reminders by scheduled date', () {
    final reminders = buildDebtReminders(
      [
        _debt(id: 'later', dueDate: DateTime(2026, 8, 20)),
        _debt(id: 'earlier', dueDate: DateTime(2026, 8, 5)),
      ],
      now: now,
    );
    expect(reminders.map((r) => r.debtId), ['earlier', 'later']);
  });

  test('skips debts without a due date', () {
    final reminders = buildDebtReminders(
      [_debt(id: 'nodue', dueDate: null)],
      now: now,
    );
    expect(reminders, isEmpty);
  });

  test('skips paid debts', () {
    final reminders = buildDebtReminders(
      [
        _debt(
          id: 'paid',
          dueDate: DateTime(2026, 8, 1),
          status: DebtStatus.paid,
        ),
      ],
      now: now,
    );
    expect(reminders, isEmpty);
  });

  test('uses the customer name and formatted balance in the body', () {
    final reminders = buildDebtReminders(
      [
        _debt(
          id: 'named',
          dueDate: DateTime(2026, 8, 1),
          balancePesos: 500,
          customerName: 'Maria Santos',
        ),
      ],
      now: now,
    );
    expect(reminders.single.title, 'Overdue utang');
    expect(reminders.single.body, 'Maria Santos - ₱500.00');
  });
}