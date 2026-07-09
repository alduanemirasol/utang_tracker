import 'package:uuid/uuid.dart';
import 'package:utang_tracker/core/domain/payment.dart';
import 'package:utang_tracker/core/domain/payment_method.dart';
import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/payments/domain/payment_repository.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';

const _uuid = Uuid();

class CreatePaymentUseCase {
  final PaymentRepository _repository;

  CreatePaymentUseCase(this._repository);

  Future<Result<Payment>> execute({
    required String debtId,
    required double amount,
    required DateTime paymentDate,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    if (amount <= 0) {
      return Error(ValidationFailure('Amount must be greater than 0'));
    }
    if (debtId.trim().isEmpty) {
      return Error(ValidationFailure('Debt is required'));
    }

    final now = DateTimeHelper.createdAt();
    final trimmedNotes = notes?.trim();
    final payment = Payment(
      id: _uuid.v4(),
      debtId: debtId,
      amount: amount,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      notes: trimmedNotes == null || trimmedNotes.isEmpty ? null : trimmedNotes,
      createdAt: now,
    );

    return _repository.create(payment);
  }
}
