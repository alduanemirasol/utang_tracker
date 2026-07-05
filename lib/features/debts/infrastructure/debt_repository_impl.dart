import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/debts/domain/debt.dart';
import 'package:utang_tracker/features/debts/domain/debt_repository.dart';
import 'package:utang_tracker/features/debts/infrastructure/debt_data_source.dart';
import 'package:utang_tracker/features/debts/infrastructure/debt_model.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DebtDataSource _dataSource;

  DebtRepositoryImpl(this._dataSource);

  @override
  Future<Result<Debt>> create(Debt debt) async {
    try {
      final model = DebtModel.fromEntity(debt);
      await _dataSource.insert(model.toMap());
      return Success(debt);
    } catch (e) {
      return Error(DatabaseFailure('Failed to create debt: $e'));
    }
  }

  @override
  Future<Result<List<Debt>>> getAll({String? customerId}) async {
    try {
      final maps = await _dataSource.getAll(customerId: customerId);
      final debts = maps.map((m) => DebtModel.fromMap(m).toEntity()).toList();
      return Success(debts);
    } catch (e) {
      return Error(DatabaseFailure('Failed to load debts: $e'));
    }
  }

  @override
  Future<Result<Debt>> getById(String id) async {
    try {
      final map = await _dataSource.getById(id);
      if (map == null) {
        return Error(NotFoundFailure('Debt not found'));
      }
      return Success(DebtModel.fromMap(map).toEntity());
    } catch (e) {
      return Error(DatabaseFailure('Failed to load debt: $e'));
    }
  }

  @override
  Future<Result<Debt>> update(Debt debt) async {
    try {
      final model = DebtModel.fromEntity(debt);
      await _dataSource.update(model.toMap());
      return Success(debt);
    } catch (e) {
      return Error(DatabaseFailure('Failed to update debt: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _dataSource.delete(id);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Failed to delete debt: $e'));
    }
  }
}
