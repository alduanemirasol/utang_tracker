import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/data_sources/debt_data_source.dart';
import 'package:utang_tracker/core/database/data_sources/debt_item_data_source.dart';
import 'package:utang_tracker/core/database/data_sources/payment_data_source.dart';
import 'package:utang_tracker/core/domain/debt.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/infrastructure/models/debt_item_model.dart';
import 'package:utang_tracker/core/infrastructure/models/debt_model.dart';
import 'package:utang_tracker/core/infrastructure/models/payment_model.dart';
import 'package:utang_tracker/features/debts/domain/debt_detail.dart';
import 'package:utang_tracker/features/debts/domain/debt_repository.dart';
import 'package:utang_tracker/helpers/date_time_helper.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DebtDataSource _debtDataSource;
  final DebtItemDataSource _debtItemDataSource;
  final PaymentDataSource _paymentDataSource;
  final Database _db;

  DebtRepositoryImpl(
    this._debtDataSource,
    this._debtItemDataSource,
    this._paymentDataSource,
    this._db,
  );

  @override
  Future<Result<Debt>> create(Debt debt) async {
    try {
      final model = DebtModel.fromEntity(debt);
      await _debtDataSource.insert(model.toMap());
      return Success(debt);
    } catch (e) {
      return Error(DatabaseFailure('Failed to create debt: $e'));
    }
  }

  @override
  Future<Result<List<Debt>>> getAll(
      {String? customerId, DebtStatus? status}) async {
    try {
      final maps =
          await _debtDataSource.getAll(customerId: customerId, status: status);
      final debts = maps.map((m) => DebtModel.fromMap(m).toEntity()).toList();
      return Success(debts);
    } catch (e) {
      return Error(DatabaseFailure('Failed to load debts: $e'));
    }
  }

  @override
  Future<Result<Debt>> getById(String id) async {
    try {
      final map = await _debtDataSource.getById(id);
      if (map == null) {
        return Error(NotFoundFailure('Debt not found'));
      }
      return Success(DebtModel.fromMap(map).toEntity());
    } catch (e) {
      return Error(DatabaseFailure('Failed to load debt: $e'));
    }
  }

  @override
  Future<Result<DebtDetail>> getDetail(String id) async {
    try {
      final debtMap = await _debtDataSource.getById(id);
      if (debtMap == null) {
        return Error(NotFoundFailure('Debt not found'));
      }
      final debt = DebtModel.fromMap(debtMap).toEntity();

      final itemMaps = await _debtItemDataSource.getByDebtId(id);
      final items =
          itemMaps.map((m) => DebtItemModel.fromMap(m).toEntity()).toList();

      final paymentMaps = await _paymentDataSource.getByDebtId(id);
      final payments =
          paymentMaps.map((m) => PaymentModel.fromMap(m).toEntity()).toList();

      return Success(DebtDetail(debt: debt, items: items, payments: payments));
    } catch (e) {
      return Error(DatabaseFailure('Failed to load debt detail: $e'));
    }
  }

  @override
  Future<Result<Debt>> update(Debt debt) async {
    try {
      final model = DebtModel.fromEntity(debt);
      await _debtDataSource.update(model.toMap());
      return Success(debt);
    } catch (e) {
      return Error(DatabaseFailure('Failed to update debt: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _db.transaction((txn) async {
        final now = DateTimeHelper.updatedAt().toUtc().toIso8601String();
        await _paymentDataSource.deleteByDebtId(id, now, txn);
        await _debtItemDataSource.deleteByDebtId(id, now, txn);
        await _debtDataSource.delete(id, now, txn);
      });
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Failed to delete debt: $e'));
    }
  }
}
