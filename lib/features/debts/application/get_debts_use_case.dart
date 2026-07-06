import 'package:utang_tracker/core/domain/debt.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/debts/domain/debt_repository.dart';

class GetDebtsUseCase {
  final DebtRepository _repository;

  GetDebtsUseCase(this._repository);

  Future<Result<List<Debt>>> execute({String? customerId, DebtStatus? status}) {
    return _repository.getAll(customerId: customerId, status: status);
  }
}
