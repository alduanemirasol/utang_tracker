import 'payment_method.dart';

class Payment {
  final String id;
  final String debtId;
  final double amount;
  final DateTime paymentDate;
  final PaymentMethod paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime? deletedAt;

  const Payment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.deletedAt,
  });

  Payment copyWith({
    String? id,
    String? debtId,
    double? amount,
    DateTime? paymentDate,
    PaymentMethod? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool clearNotes = false,
    bool clearDeletedAt = false,
  }) {
    return Payment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
