import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/notifications/domain/entities/balance_reminder.dart';

void main() {
  Debt debt({
    required String id,
    required int balance,
    DateTime? dueDate,
    DateTime? transactionDate,
  }) {
    final created = DateTime.utc(2026, 7, 1);
    return Debt(
      id: id,
      customerId: 'customer-1',
      totalAmount: Money.fromCentavos(balance),
      paidAmount: Money.zero(),
      balance: Money.fromCentavos(balance),
      status: DebtStatus.unpaid,
      transactionDate: transactionDate ?? created,
      dueDate: dueDate,
      createdAt: created,
      updatedAt: created,
    );
  }

  test('concise reminder includes total and overdue date', () {
    final message = BalanceReminder.build(
      customerName: 'Juan',
      outstandingBalance: Money.fromCentavos(45000),
      debts: [
        debt(id: 'debt-1', balance: 45000, dueDate: DateTime(2026, 8, 1)),
      ],
      style: BalanceReminderStyle.concise,
      now: DateTime(2026, 8, 3),
    );

    expect(message, contains('Hi Juan'));
    expect(message, contains('450.00'));
    expect(message, contains('overdue since Aug 1, 2026'));
    expect(message, isNot(contains('Utang details:')));
  });

  test('detailed reminder lists only debts with a remaining balance', () {
    final message = BalanceReminder.build(
      customerName: 'Maria',
      outstandingBalance: Money.fromCentavos(30000),
      debts: [
        debt(
          id: 'active',
          balance: 30000,
          transactionDate: DateTime(2026, 7, 20),
        ),
        debt(id: 'paid', balance: 0, transactionDate: DateTime(2026, 7, 10)),
      ],
      style: BalanceReminderStyle.detailed,
      now: DateTime(2026, 8, 3),
    );

    expect(message, contains('Utang details:'));
    expect(message, contains('Jul 20, 2026'));
    expect(message, isNot(contains('Jul 10, 2026')));
    expect(message, contains('Total:'));
  });
}
