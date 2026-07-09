import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/data_sources/debt_data_source.dart';
import 'package:utang_tracker/core/database/data_sources/payment_data_source.dart';
import 'package:utang_tracker/core/database/tables.dart';
import 'package:utang_tracker/core/domain/debt_calculator.dart';
import 'package:utang_tracker/core/domain/payment.dart';
import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/infrastructure/models/payment_model.dart';
import 'package:utang_tracker/features/payments/domain/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentDataSource _dataSource;
  final DebtDataSource _debtDataSource;
  final Database _db;

  PaymentRepositoryImpl(this._dataSource, this._debtDataSource, this._db);

  @override
  Future<Result<Payment>> create(Payment payment) async {
    try {
      late final Payment created;
      await _db.transaction((txn) async {
        final debtMap = await _debtDataSource.getById(payment.debtId, txn);
        if (debtMap == null) {
          throw _RepoException(NotFoundFailure('Debt not found'));
        }

        final balance = (debtMap[columnBalance] as num).toDouble();
        if (DebtCalculator.exceedsBalance(
          amount: payment.amount,
          remainingBalance: balance,
        )) {
          throw _RepoException(
            ValidationFailure(
              'Amount cannot be more than remaining balance',
            ),
          );
        }

        final model = PaymentModel.fromEntity(payment);
        await _dataSource.insert(model.toMap(), txn);
        await _debtDataSource.recalculateTotals(payment.debtId, txn);
        created = payment;
      });
      return Success(created);
    } on _RepoException catch (e) {
      return Error(e.failure);
    } catch (e) {
      return Error(DatabaseFailure('Failed to create payment: $e'));
    }
  }

  @override
  Future<Result<Payment>> getById(String id) async {
    try {
      final map = await _dataSource.getById(id);
      if (map == null) {
        return Error(NotFoundFailure('Payment not found'));
      }
      return Success(PaymentModel.fromMap(map).toEntity());
    } catch (e) {
      return Error(DatabaseFailure('Failed to load payment: $e'));
    }
  }

  @override
  Future<Result<List<Payment>>> getByDebtId(String debtId) async {
    try {
      final maps = await _dataSource.getByDebtId(debtId);
      final payments =
          maps.map((m) => PaymentModel.fromMap(m).toEntity()).toList();
      return Success(payments);
    } catch (e) {
      return Error(DatabaseFailure('Failed to load payments: $e'));
    }
  }

  @override
  Future<Result<Payment>> update(Payment payment) async {
    try {
      late final Payment updatedPayment;
      await _db.transaction((txn) async {
        final results = await txn.query(
          tablePayments,
          where: '$columnId = ? AND $columnDeletedAt IS NULL',
          whereArgs: [payment.id],
        );
        if (results.isEmpty) {
          throw _RepoException(NotFoundFailure('Payment not found'));
        }
        final existingPayment =
            PaymentModel.fromMap(results.first).toEntity();

        final debtMap =
            await _debtDataSource.getById(existingPayment.debtId, txn);
        if (debtMap == null) {
          throw _RepoException(NotFoundFailure('Debt not found'));
        }

        final balance = (debtMap[columnBalance] as num).toDouble();
        // Remaining allowance includes this payment's previous amount.
        final allowed = balance + existingPayment.amount;
        if (DebtCalculator.exceedsBalance(
          amount: payment.amount,
          remainingBalance: allowed,
        )) {
          throw _RepoException(
            ValidationFailure(
              'Amount cannot be more than remaining balance',
            ),
          );
        }

        updatedPayment = existingPayment.copyWith(
          amount: payment.amount,
          paymentDate: payment.paymentDate,
          paymentMethod: payment.paymentMethod,
          notes: payment.notes,
          clearNotes: payment.notes == null,
        );

        final model = PaymentModel.fromEntity(updatedPayment);
        await _dataSource.update(model.toMap(), txn);
        await _debtDataSource.recalculateTotals(updatedPayment.debtId, txn);
      });
      return Success(updatedPayment);
    } on _RepoException catch (e) {
      return Error(e.failure);
    } catch (e) {
      return Error(DatabaseFailure('Failed to update payment: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _db.transaction((txn) async {
        final results = await txn.query(
          tablePayments,
          where: '$columnId = ? AND $columnDeletedAt IS NULL',
          whereArgs: [id],
        );
        if (results.isEmpty) {
          throw _RepoException(NotFoundFailure('Payment not found'));
        }
        final existingPayment =
            PaymentModel.fromMap(results.first).toEntity();

        final now = DateTimeHelper.updatedAt().toUtc().toIso8601String();
        await _dataSource.delete(id, now, txn);
        await _debtDataSource.recalculateTotals(existingPayment.debtId, txn);
      });
      return const Success(null);
    } on _RepoException catch (e) {
      return Error(e.failure);
    } catch (e) {
      return Error(DatabaseFailure('Failed to delete payment: $e'));
    }
  }
}

class _RepoException implements Exception {
  final Failure failure;
  _RepoException(this.failure);
}
