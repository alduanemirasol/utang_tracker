import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/payments/domain/payment.dart';
import 'package:utang_tracker/features/payments/domain/payment_repository.dart';
import 'package:utang_tracker/features/payments/infrastructure/payment_data_source.dart';
import 'package:utang_tracker/features/payments/infrastructure/payment_model.dart';
import 'package:utang_tracker/features/debts/infrastructure/debt_data_source.dart';

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
        await _debtDataSource.recalculateFromPayments(payment.debtId, txn);
      });
      return Success(payment);
    } catch (e) {
      return Error(DatabaseFailure('Failed to create payment: $e'));
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
      final existingMap = await _dataSource.getById(payment.id);
      if (existingMap == null) {
        return Error(NotFoundFailure('Payment not found'));
      }
      final existingPayment = PaymentModel.fromMap(existingMap).toEntity();

      final updatedPayment = payment.copyWith(debtId: existingPayment.debtId);

      await _db.transaction((txn) async {
        final model = PaymentModel.fromEntity(updatedPayment);
        await _dataSource.update(model.toMap(), txn);
        await _debtDataSource.recalculateFromPayments(
          updatedPayment.debtId,
          txn,
        );
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

      await _db.transaction((txn) async {
        await _dataSource.delete(id, txn);
        await _debtDataSource.recalculateFromPayments(
          existingPayment.debtId,
          txn,
        );
      });
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Failed to delete payment: $e'));
    }
  }
}
