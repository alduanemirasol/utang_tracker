import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/payments/domain/entities/payment.dart';

Payment mapPayment(PaymentRow row, {String? customerName, String? customerId}) {
  return Payment(
    id: row.id,
    debtId: row.debtId,
    amount: Money.fromCentavos(row.amount),
    paymentDate: row.paymentDate,
    paymentMethod: row.paymentMethod,
    notes: row.notes,
    createdAt: row.createdAt,
    customerName: customerName,
    customerId: customerId,
  );
}
