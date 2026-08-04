import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/reports/domain/overdue_aging.dart';

void main() {
  final now = DateTime(2026, 8, 4, 10, 0);

  Debt debt({
    required String id,
    required Money balance,
    DateTime? dueDate,
    DebtStatus status = DebtStatus.unpaid,
  }) {
    return Debt(
      id: id,
      customerId: 'customer-id',
      totalAmount: balance,
      paidAmount: status == DebtStatus.unpaid ? Money.zero() : balance,
      balance: balance,
      status: status,
      transactionDate: now,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      customerName: 'Maria',
    );
  }

  test('assigns outstanding debts to the correct overdue buckets', () {
    final buckets = OverdueAging.compute(
      [
        debt(
          id: '1',
          balance: Money.fromPesos(100),
          dueDate: now.subtract(const Duration(days: 3)),
        ),
        debt(
          id: '2',
          balance: Money.fromPesos(200),
          dueDate: now.subtract(const Duration(days: 7)),
        ),
        debt(
          id: '3',
          balance: Money.fromPesos(400),
          dueDate: now.subtract(const Duration(days: 8)),
        ),
        debt(
          id: '4',
          balance: Money.fromPesos(800),
          dueDate: now.subtract(const Duration(days: 30)),
        ),
        debt(
          id: '5',
          balance: Money.fromPesos(1600),
          dueDate: now.subtract(const Duration(days: 31)),
        ),
      ],
      now: now,
    );

    expect(buckets.length, 3);
    expect(buckets[0].label, '1\u20137 days overdue');
    expect(buckets[0].total.centavos, 30000);
    expect(buckets[0].debtCount, 2);
    expect(buckets[1].label, '8\u201330 days overdue');
    expect(buckets[1].total.centavos, 120000);
    expect(buckets[1].debtCount, 2);
    expect(buckets[2].label, '30+ days overdue');
    expect(buckets[2].total.centavos, 160000);
    expect(buckets[2].debtCount, 1);
  });

  test('excludes paid, no due date, and not yet overdue debts', () {
    final buckets = OverdueAging.compute(
      [
        debt(
          id: 'paid',
          balance: Money.fromPesos(50),
          dueDate: now.subtract(const Duration(days: 5)),
          status: DebtStatus.paid,
        ),
        debt(id: 'no-due-date', balance: Money.fromPesos(60)),
        debt(
          id: 'future',
          balance: Money.fromPesos(70),
          dueDate: now.add(const Duration(days: 2)),
        ),
        debt(id: 'due-today', balance: Money.fromPesos(80), dueDate: now),
      ],
      now: now,
    );

    expect(buckets.every((bucket) => bucket.debtCount == 0), isTrue);
    expect(buckets.every((bucket) => bucket.total.isZero), isTrue);
  });
}