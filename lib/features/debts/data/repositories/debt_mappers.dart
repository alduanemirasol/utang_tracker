import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';

Debt mapDebt(DebtRow row, {String? customerName}) {
  return Debt(
    id: row.id,
    customerId: row.customerId,
    totalAmount: Money.fromCentavos(row.totalAmount),
    paidAmount: Money.fromCentavos(row.paidAmount),
    balance: Money.fromCentavos(row.balance),
    status: DebtStatus.fromValue(row.status),
    transactionDate: row.transactionDate,
    dueDate: row.dueDate,
    notes: row.notes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    customerName: customerName,
  );
}

DebtItem mapDebtItem(DebtItemRow row) {
  return DebtItem(
    id: row.id,
    debtId: row.debtId,
    productName: row.productName,
    quantity: row.quantity,
    unit: row.unit,
    price: Money.fromCentavos(row.price),
  );
}
