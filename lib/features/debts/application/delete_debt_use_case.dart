import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/debts/domain/debt_repository.dart';

class DeleteDebtUseCase {
  final DebtRepository _repository;

  DeleteDebtUseCase(this._repository);

  Future<Result<void>> execute(String id) {
    return _repository.delete(id);
  }
}
