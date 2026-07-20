import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/features/payments/domain/entities/payment.dart';
import 'package:utang_tracker/features/payments/domain/repositories/payment_repository.dart';

class GetPayments {
  const GetPayments(this._repository);
  final PaymentRepository _repository;
  Future<List<Payment>> call() => _repository.getAll();
}

class GetPaymentsByDebt {
  const GetPaymentsByDebt(this._repository);
  final PaymentRepository _repository;
  Future<List<Payment>> call(String debtId) => _repository.getByDebt(debtId);
}

class GetPaymentsByCustomer {
  const GetPaymentsByCustomer(this._repository);
  final PaymentRepository _repository;
  Future<List<Payment>> call(String customerId) =>
      _repository.getByCustomer(customerId);
}

class RecordPayment {
  const RecordPayment(this._repository);
  final PaymentRepository _repository;
  Future<Payment> call({
    required String debtId,
    required Money amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? notes,
  }) {
    if (!amount.isPositive) {
      throw const ValidationException('Payment amount must be greater than zero.');
    }
    if (paymentMethod.trim().isEmpty) {
      throw const ValidationException('Payment method is required.');
    }
    return _repository.recordPayment(
      debtId: debtId,
      amount: amount,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      notes: notes,
    );
  }
}
