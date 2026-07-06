import 'package:utang_tracker/core/database/tables.dart';
import 'package:utang_tracker/core/domain/debt.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';

class DebtModel {
  final String id;
  final String customerId;
  final double totalAmount;
  final double paidAmount;
  final double balance;
  final String status;
  final String transactionDate;
  final String? dueDate;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const DebtModel({
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
    this.deletedAt,
  });

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map[columnId] as String,
      customerId: map[columnCustomerId] as String,
      totalAmount: (map[columnTotalAmount] as num).toDouble(),
      paidAmount: (map[columnPaidAmount] as num).toDouble(),
      balance: (map[columnBalance] as num).toDouble(),
      status: map[columnStatus] as String,
      transactionDate: map[columnTransactionDate] as String,
      dueDate: map[columnDueDate] as String?,
      notes: map[columnNotes] as String?,
      createdAt: map[columnCreatedAt] as String,
      updatedAt: map[columnUpdatedAt] as String,
      deletedAt: map[columnDeletedAt] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnCustomerId: customerId,
      columnTotalAmount: totalAmount,
      columnPaidAmount: paidAmount,
      columnBalance: balance,
      columnStatus: status,
      columnTransactionDate: transactionDate,
      columnDueDate: dueDate,
      columnNotes: notes,
      columnCreatedAt: createdAt,
      columnUpdatedAt: updatedAt,
      columnDeletedAt: deletedAt,
    };
  }

  Debt toEntity() {
    return Debt(
      id: id,
      customerId: customerId,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      balance: balance,
      status: DebtStatus.fromString(status),
      transactionDate: DateTime.parse(transactionDate),
      dueDate: dueDate != null ? DateTime.parse(dueDate!) : null,
      notes: notes,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }

  factory DebtModel.fromEntity(Debt entity) {
    return DebtModel(
      id: entity.id,
      customerId: entity.customerId,
      totalAmount: entity.totalAmount,
      paidAmount: entity.paidAmount,
      balance: entity.balance,
      status: entity.status.value,
      transactionDate: entity.transactionDate.toUtc().toIso8601String(),
      dueDate: entity.dueDate?.toUtc().toIso8601String(),
      notes: entity.notes,
      createdAt: entity.createdAt.toUtc().toIso8601String(),
      updatedAt: entity.updatedAt.toUtc().toIso8601String(),
      deletedAt: entity.deletedAt?.toUtc().toIso8601String(),
    );
  }
}
