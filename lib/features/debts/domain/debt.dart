import 'debt_status.dart';

class Debt {
  final String id;
  final String customerId;
  final double totalAmount;
  final double paidAmount;
  final double balance;
  final DebtStatus status;
  final DateTime transactionDate;
  final DateTime? dueDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Debt({
    required this.id,
    required this.customerId,
    required this.totalAmount,
    required this.paidAmount,
    required this.balance,
    required this.status,
    required this.transactionDate,
    this.dueDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Debt copyWith({
    String? id,
    String? customerId,
    double? totalAmount,
    double? paidAmount,
    double? balance,
    DebtStatus? status,
    DateTime? transactionDate,
    DateTime? dueDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDueDate = false,
    bool clearNotes = false,
  }) {
    return Debt(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      transactionDate: transactionDate ?? this.transactionDate,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  DebtStatus calculateStatus() {
    if (balance <= 0) return DebtStatus.paid;
    if (paidAmount > 0) return DebtStatus.partial;
    return DebtStatus.unpaid;
  }
}
