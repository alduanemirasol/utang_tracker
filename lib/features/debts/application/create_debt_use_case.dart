import 'package:uuid/uuid.dart';
import 'package:utang_tracker/core/domain/debt.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/features/debts/domain/debt_repository.dart';

const _uuid = Uuid();

class CreateDebtUseCase {
  final DebtRepository _repository;

  CreateDebtUseCase(this._repository);

  Future<Result<Debt>> execute({
    required String customerId,
    required DateTime transactionDate,
    DateTime? dueDate,
    String? notes,
  }) async {
    if (customerId.trim().isEmpty) {
      return Error(ValidationFailure('Customer is required'));
    }

    final now = DateTimeHelper.createdAt();
    final trimmedNotes = notes?.trim();

    final debt = Debt(
      id: _uuid.v4(),
      customerId: customerId,
      totalAmount: 0,
      paidAmount: 0,
      balance: 0,
      status: DebtStatus.unpaid,
      transactionDate: transactionDate,
      dueDate: dueDate,
      notes: trimmedNotes == null || trimmedNotes.isEmpty ? null : trimmedNotes,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.create(debt);
  }
}
