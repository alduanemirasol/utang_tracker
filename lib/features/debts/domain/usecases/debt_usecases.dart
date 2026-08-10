import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_sort_order.dart';

List<Debt> applySort(List<Debt> debts, DebtSortOrder sort) {
  final sorted = List<Debt>.from(debts);
  switch (sort) {
    case DebtSortOrder.newest:
      sorted.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    case DebtSortOrder.highestBalance:
      sorted.sort((a, b) => b.balance.centavos.compareTo(a.balance.centavos));
    case DebtSortOrder.lowestBalance:
      sorted.sort((a, b) => a.balance.centavos.compareTo(b.balance.centavos));
  }
  return sorted;
}
