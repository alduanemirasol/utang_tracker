import 'package:utang_tracker/core/database/tables.dart';
import 'package:utang_tracker/core/domain/payment.dart';
import 'package:utang_tracker/core/domain/payment_method.dart';

class PaymentModel {
  final String id;
  final String debtId;
  final double amount;
  final String paymentDate;
  final String paymentMethod;
  final String? notes;
  final String createdAt;
  final String? deletedAt;

  const PaymentModel({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.deletedAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map[columnId] as String,
      debtId: map[columnDebtId] as String,
      amount: (map[columnAmount] as num).toDouble(),
      paymentDate: map[columnPaymentDate] as String,
      paymentMethod: map[columnPaymentMethod] as String,
      notes: map[columnNotes] as String?,
      createdAt: map[columnCreatedAt] as String,
      deletedAt: map[columnDeletedAt] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnDebtId: debtId,
      columnAmount: amount,
      columnPaymentDate: paymentDate,
      columnPaymentMethod: paymentMethod,
      columnNotes: notes,
      columnCreatedAt: createdAt,
      columnDeletedAt: deletedAt,
    };
  }

  Payment toEntity() {
    return Payment(
      id: id,
      debtId: debtId,
      amount: amount,
      paymentDate: DateTime.parse(paymentDate),
      paymentMethod: PaymentMethod.fromString(paymentMethod),
      notes: notes,
      createdAt: DateTime.parse(createdAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }

  factory PaymentModel.fromEntity(Payment entity) {
    return PaymentModel(
      id: entity.id,
      debtId: entity.debtId,
      amount: entity.amount,
      paymentDate: entity.paymentDate.toUtc().toIso8601String(),
      paymentMethod: entity.paymentMethod.value,
      notes: entity.notes,
      createdAt: entity.createdAt.toUtc().toIso8601String(),
      deletedAt: entity.deletedAt?.toUtc().toIso8601String(),
    );
  }
}
