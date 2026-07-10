import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_status.dart';
import 'package:utang_tracker/features/debts/domain/repositories/debt_repository.dart';

class GetDebts {
  const GetDebts(this._repository);
  final DebtRepository _repository;
  Future<List<Debt>> call({DebtStatus? status}) =>
      _repository.getAll(status: status);
}

class GetDebtsByCustomer {
  const GetDebtsByCustomer(this._repository);
  final DebtRepository _repository;
  Future<List<Debt>> call(String customerId) =>
      _repository.getByCustomer(customerId);
}

class GetDebtDetail {
  const GetDebtDetail(this._repository);
  final DebtRepository _repository;
  Future<DebtDetail?> call(String id) => _repository.getById(id);
}

class CreateDebt {
  const CreateDebt(this._repository);
  final DebtRepository _repository;
  Future<Debt> call({
    required String customerId,
    required DateTime transactionDate,
    DateTime? dueDate,
    String? notes,
    required List<DebtItemInput> items,
  }) {
    return _repository.create(
      customerId: customerId,
      transactionDate: transactionDate,
      dueDate: dueDate,
      notes: notes,
      items: items,
    );
  }
}

class UpdateDebt {
  const UpdateDebt(this._repository);
  final DebtRepository _repository;
  Future<Debt> call({
    required String id,
    required DateTime transactionDate,
    DateTime? dueDate,
    String? notes,
    required List<DebtItemInput> items,
  }) {
    return _repository.update(
      id: id,
      transactionDate: transactionDate,
      dueDate: dueDate,
      notes: notes,
      items: items,
    );
  }
}
