import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_sort_order.dart';
import 'package:utang_tracker/features/debts/domain/usecases/debt_usecases.dart';

Debt _debt({
  required String id,
  required DateTime transactionDate,
  required int balancePesos,
}) {
  return Debt(
    id: id,
    customerId: 'cust',
    totalAmount: Money.fromCentavos((balancePesos + 10) * 100),
    paidAmount: Money.zero(),
    balance: Money.fromCentavos(balancePesos * 100),
    status: DebtStatus.unpaid,
    transactionDate: transactionDate,
    createdAt: transactionDate,
    updatedAt: transactionDate,
  );
}

void main() {
  final debts = [
    _debt(
      id: 'old-high',
      transactionDate: DateTime(2026, 1, 1),
      balancePesos: 90,
    ),
    _debt(
      id: 'new-low',
      transactionDate: DateTime(2026, 3, 1),
      balancePesos: 10,
    ),
    _debt(
      id: 'mid-mid',
      transactionDate: DateTime(2026, 2, 1),
      balancePesos: 50,
    ),
  ];

  test('newest sorts by transaction date desc', () {
    final sorted = applySort(debts, DebtSortOrder.newest);
    expect(sorted.map((d) => d.id), ['new-low', 'mid-mid', 'old-high']);
  });

  test('highestBalance sorts by balance desc', () {
    final sorted = applySort(debts, DebtSortOrder.highestBalance);
    expect(sorted.map((d) => d.id), ['old-high', 'mid-mid', 'new-low']);
  });

  test('lowestBalance sorts by balance asc', () {
    final sorted = applySort(debts, DebtSortOrder.lowestBalance);
    expect(sorted.map((d) => d.id), ['new-low', 'mid-mid', 'old-high']);
  });

  test('does not mutate the input list', () {
    final before = debts.map((d) => d.id).toList();
    applySort(debts, DebtSortOrder.highestBalance);
    expect(debts.map((d) => d.id), before);
  });
}
