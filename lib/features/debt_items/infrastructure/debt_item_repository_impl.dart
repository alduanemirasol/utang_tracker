import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item_repository.dart';
import 'package:utang_tracker/features/debt_items/infrastructure/debt_item_data_source.dart';
import 'package:utang_tracker/features/debt_items/infrastructure/debt_item_model.dart';
import 'package:utang_tracker/features/debts/infrastructure/debt_data_source.dart';
import 'package:utang_tracker/helpers/date_time_helper.dart';

class DebtItemRepositoryImpl implements DebtItemRepository {
  final DebtItemDataSource _dataSource;
  final DebtDataSource _debtDataSource;
  final Database _db;

  DebtItemRepositoryImpl(this._dataSource, this._debtDataSource, this._db);

  @override
  Future<Result<DebtItem>> create(DebtItem item) async {
    try {
      await _db.transaction((txn) async {
        final model = DebtItemModel.fromEntity(item);
        await _dataSource.insert(model.toMap(), txn);
        await _debtDataSource.recalculateFromItems(item.debtId, txn);
      });
      return Success(item);
    } catch (e) {
      return Error(DatabaseFailure('Failed to create debt item: $e'));
    }
  }

  @override
  Future<Result<DebtItem>> getById(String id) async {
    try {
      final map = await _dataSource.getById(id);
      if (map == null) {
        return Error(NotFoundFailure('Debt item not found'));
      }
      return Success(DebtItemModel.fromMap(map).toEntity());
    } catch (e) {
      return Error(DatabaseFailure('Failed to load debt item: $e'));
    }
  }

  @override
  Future<Result<List<DebtItem>>> getByDebtId(String debtId) async {
    try {
      final maps = await _dataSource.getByDebtId(debtId);
      final items =
          maps.map((m) => DebtItemModel.fromMap(m).toEntity()).toList();
      return Success(items);
    } catch (e) {
      return Error(DatabaseFailure('Failed to load debt items: $e'));
    }
  }

  @override
  Future<Result<DebtItem>> update(DebtItem item) async {
    try {
      final existingMap = await _dataSource.getById(item.id);
      if (existingMap == null) {
        return Error(NotFoundFailure('Debt item not found'));
      }
      final existingItem = DebtItemModel.fromMap(existingMap).toEntity();

      final updatedItem = item.copyWith(debtId: existingItem.debtId);

      await _db.transaction((txn) async {
        final model = DebtItemModel.fromEntity(updatedItem);
        await _dataSource.update(model.toMap(), txn);
        await _debtDataSource.recalculateFromItems(updatedItem.debtId, txn);
      });
      return Success(updatedItem);
    } catch (e) {
      return Error(DatabaseFailure('Failed to update debt item: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final existingMap = await _dataSource.getById(id);
      if (existingMap == null) {
        return Error(NotFoundFailure('Debt item not found'));
      }
      final existingItem = DebtItemModel.fromMap(existingMap).toEntity();

      final now = DateTimeHelper.updatedAt().toUtc().toIso8601String();
      await _db.transaction((txn) async {
        await _dataSource.delete(id, now, txn);
        await _debtDataSource.recalculateFromItems(existingItem.debtId, txn);
      });
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Failed to delete debt item: $e'));
    }
  }
}
