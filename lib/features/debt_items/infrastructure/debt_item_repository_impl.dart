import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/data_sources/debt_data_source.dart';
import 'package:utang_tracker/core/database/data_sources/debt_item_data_source.dart';
import 'package:utang_tracker/core/database/tables.dart';
import 'package:utang_tracker/core/domain/debt_item.dart';
import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/infrastructure/models/debt_item_model.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item_repository.dart';

class DebtItemRepositoryImpl implements DebtItemRepository {
  final DebtItemDataSource _dataSource;
  final DebtDataSource _debtDataSource;
  final Database _db;

  DebtItemRepositoryImpl(this._dataSource, this._debtDataSource, this._db);

  @override
  Future<Result<DebtItem>> create(DebtItem item) async {
    try {
      late final DebtItem created;
      await _db.transaction((txn) async {
        final debtMap = await _debtDataSource.getById(item.debtId, txn);
        if (debtMap == null) {
          throw _RepoException(NotFoundFailure('Debt not found'));
        }

        final model = DebtItemModel.fromEntity(item);
        await _dataSource.insert(model.toMap(), txn);
        await _debtDataSource.recalculateTotals(item.debtId, txn);
        created = item;
      });
      return Success(created);
    } on _RepoException catch (e) {
      return Error(e.failure);
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
      late final DebtItem updatedItem;
      await _db.transaction((txn) async {
        final results = await txn.query(
          tableDebtItems,
          where: '$columnId = ? AND $columnDeletedAt IS NULL',
          whereArgs: [item.id],
        );
        if (results.isEmpty) {
          throw _RepoException(NotFoundFailure('Debt item not found'));
        }
        final existingItem = DebtItemModel.fromMap(results.first).toEntity();

        final debtMap =
            await _debtDataSource.getById(existingItem.debtId, txn);
        if (debtMap == null) {
          throw _RepoException(NotFoundFailure('Debt not found'));
        }

        updatedItem = item.copyWith(debtId: existingItem.debtId);
        final model = DebtItemModel.fromEntity(updatedItem);
        await _dataSource.update(model.toMap(), txn);
        await _debtDataSource.recalculateTotals(updatedItem.debtId, txn);
      });
      return Success(updatedItem);
    } on _RepoException catch (e) {
      return Error(e.failure);
    } catch (e) {
      return Error(DatabaseFailure('Failed to update debt item: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _db.transaction((txn) async {
        final results = await txn.query(
          tableDebtItems,
          where: '$columnId = ? AND $columnDeletedAt IS NULL',
          whereArgs: [id],
        );
        if (results.isEmpty) {
          throw _RepoException(NotFoundFailure('Debt item not found'));
        }
        final existingItem = DebtItemModel.fromMap(results.first).toEntity();

        final now = DateTimeHelper.updatedAt().toUtc().toIso8601String();
        await _dataSource.delete(id, now, txn);
        await _debtDataSource.recalculateTotals(existingItem.debtId, txn);
      });
      return const Success(null);
    } on _RepoException catch (e) {
      return Error(e.failure);
    } catch (e) {
      return Error(DatabaseFailure('Failed to delete debt item: $e'));
    }
  }
}

class _RepoException implements Exception {
  final Failure failure;
  _RepoException(this.failure);
}
