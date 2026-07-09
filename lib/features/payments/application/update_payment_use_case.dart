import 'package:utang_tracker/core/domain/payment.dart';
import 'package:utang_tracker/core/domain/payment_method.dart';
import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/payments/domain/payment_repository.dart';

class UpdatePaymentUseCase {
  final PaymentRepository _repository;

  UpdatePaymentUseCase(this._repository);

  Future<Result<Payment>> execute({
    required String id,
    required double amount,
    required DateTime paymentDate,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    if (amount <= 0) {
      return Error(ValidationFailure('Amount must be greater than 0'));
    }

    // debtId and createdAt are preserved inside the repository.
    final payment = Payment(
      id: id,
      debtId: '',
      amount: amount,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    return _repository.update(payment);
  }
}
