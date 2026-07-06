import 'package:riverpod/riverpod.dart';
import 'package:utang_tracker/core/domain/payment.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/presentation/providers/database_provider.dart';
import 'package:utang_tracker/core/presentation/providers/data_source_providers.dart';
import 'package:utang_tracker/features/payments/domain/payment_repository.dart';
import 'package:utang_tracker/features/payments/infrastructure/payment_repository_impl.dart';
import 'package:utang_tracker/features/payments/application/create_payment_use_case.dart';
import 'package:utang_tracker/features/payments/application/get_payments_use_case.dart';
import 'package:utang_tracker/features/payments/application/get_payment_use_case.dart';
import 'package:utang_tracker/features/payments/application/update_payment_use_case.dart';
import 'package:utang_tracker/features/payments/application/delete_payment_use_case.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    ref.read(paymentDataSourceProvider),
    ref.read(debtDataSourceProvider),
    ref.read(databaseProvider),
  );
});

final createPaymentUseCaseProvider = Provider<CreatePaymentUseCase>((ref) {
  return CreatePaymentUseCase(ref.read(paymentRepositoryProvider));
});

final getPaymentsUseCaseProvider = Provider<GetPaymentsUseCase>((ref) {
  return GetPaymentsUseCase(ref.read(paymentRepositoryProvider));
});

final getPaymentUseCaseProvider = Provider<GetPaymentUseCase>((ref) {
  return GetPaymentUseCase(ref.read(paymentRepositoryProvider));
});

final updatePaymentUseCaseProvider = Provider<UpdatePaymentUseCase>((ref) {
  return UpdatePaymentUseCase(ref.read(paymentRepositoryProvider));
});

final deletePaymentUseCaseProvider = Provider<DeletePaymentUseCase>((ref) {
  return DeletePaymentUseCase(ref.read(paymentRepositoryProvider));
});

final paymentListProvider =
    FutureProvider.family<List<Payment>, String>((ref, debtId) async {
  final result = await ref.read(getPaymentsUseCaseProvider).execute(debtId);
  return switch (result) {
    Success(data: final payments) => payments,
    Error(failure: final f) => throw f,
  };
});
