import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/payments/domain/entities/payment.dart';
import 'package:utang_tracker/features/payments/domain/usecases/payment_usecases.dart';

final getPaymentsProvider = Provider((ref) {
  return GetPayments(ref.watch(paymentRepositoryProvider));
});

final recordPaymentUseCaseProvider = Provider((ref) {
  return RecordPayment(ref.watch(paymentRepositoryProvider));
});

final paymentsListProvider =
    AsyncNotifierProvider<PaymentsListNotifier, List<Payment>>(
  PaymentsListNotifier.new,
);

class PaymentsListNotifier extends AsyncNotifier<List<Payment>> {
  @override
  Future<List<Payment>> build() {
    return ref.watch(getPaymentsProvider)();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(getPaymentsProvider)());
  }
}
