import 'package:utang_tracker/core/domain/debt.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/debts/domain/debt_repository.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';

class UpdateDebtUseCase {
  final DebtRepository _repository;

  UpdateDebtUseCase(this._repository);

  Future<Result<Debt>> execute({
    required String id,
    DateTime? transactionDate,
    DateTime? dueDate,
    String? notes,
    bool clearDueDate = false,
    bool clearNotes = false,
  }) async {
    final existing = await _repository.getById(id);
    switch (existing) {
      case Success():
        final updated = existing.data.copyWith(
          transactionDate: transactionDate,
          dueDate: dueDate,
          notes: notes?.trim(),
          updatedAt: DateTimeHelper.updatedAt(),
          clearDueDate: clearDueDate,
          clearNotes: clearNotes,
        );
        return _repository.update(updated);
      case Error():
        return existing;
    }
  }
}
