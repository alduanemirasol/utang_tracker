import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/data_sources/debt_data_source.dart';
import 'package:utang_tracker/core/database/data_sources/payment_data_source.dart';
import 'package:utang_tracker/core/domain/debt_calculator.dart';
import 'package:utang_tracker/core/domain/payment.dart';
import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/infrastructure/models/payment_model.dart';
import 'package:utang_tracker/features/payments/domain/payment_repository.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentDataSource _dataSource;
  final DebtDataSource _debtDataSource;
  final Database _db;

  PaymentRepositoryImpl(this._dataSource, this._debtDataSource, this._db);

  @override
  Future<Result<Payment>> create(Payment payment) async {
    try {
      await _db.transaction((txn) async {
        final model = PaymentModel.fromEntity(payment);
        await _dataSource.insert(model.toMap(), txn);
        await _recalculateDebtTotals(payment.debtId, txn);
      });
      return Success(payment);
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
      final payments = maps
          .map((m) => PaymentModel.fromMap(m).toEntity())
          .toList();
      return Success(payments);
    } catch (e) {
      return Error(DatabaseFailure('Failed to load payments: $e'));
    }
  }

  @override
  Future<Result<Payment>> update(Payment payment) async {
    try {
      final existingMap = await _dataSource.getById(payment.id);
      if (existingMap == null) {
        return Error(NotFoundFailure('Payment not found'));
      }
      final existingPayment = PaymentModel.fromMap(existingMap).toEntity();

      final updatedPayment = payment.copyWith(debtId: existingPayment.debtId);

      await _db.transaction((txn) async {
        final model = PaymentModel.fromEntity(updatedPayment);
        await _dataSource.update(model.toMap(), txn);
        await _recalculateDebtTotals(updatedPayment.debtId, txn);
      });
      return Success(updatedPayment);
    } catch (e) {
      return Error(DatabaseFailure('Failed to update payment: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final existingMap = await _dataSource.getById(id);
      if (existingMap == null) {
        return Error(NotFoundFailure('Payment not found'));
      }
      final existingPayment = PaymentModel.fromMap(existingMap).toEntity();

      final now = DateTimeHelper.updatedAt().toUtc().toIso8601String();
      await _db.transaction((txn) async {
        await _dataSource.delete(id, now, txn);
        await _recalculateDebtTotals(existingPayment.debtId, txn);
      });
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Failed to delete payment: $e'));
    }
  }

  Future<void> _recalculateDebtTotals(String debtId, Transaction txn) async {
    final totalAmount = await _debtDataSource.getTotalAmount(debtId);
    final paidAmount = await _debtDataSource.sumPaymentAmountsByDebtId(
      debtId,
      txn,
    );
    final balance = DebtCalculator.calculateBalance(
      totalAmount: totalAmount,
      paidAmount: paidAmount,
    );
    final status = DebtCalculator.calculateStatus(
      totalAmount: totalAmount,
      paidAmount: paidAmount,
    );
    final now = DateTimeHelper.updatedAt().toUtc().toIso8601String();
    await _debtDataSource.updateDebtTotals(
      debtId: debtId,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      balance: balance,
      status: status,
      updatedAt: now,
      txn: txn,
    );
  }
}
