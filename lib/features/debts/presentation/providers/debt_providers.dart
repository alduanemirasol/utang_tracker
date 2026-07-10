import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_status.dart';
import 'package:utang_tracker/features/debts/domain/repositories/debt_repository.dart';
import 'package:utang_tracker/features/debts/domain/usecases/debt_usecases.dart';
import 'package:utang_tracker/features/payments/domain/entities/payment.dart';
import 'package:utang_tracker/features/payments/domain/usecases/payment_usecases.dart';

final getDebtsProvider = Provider((ref) {
  return GetDebts(ref.watch(debtRepositoryProvider));
});

final getDebtDetailProvider = Provider((ref) {
  return GetDebtDetail(ref.watch(debtRepositoryProvider));
});

final createDebtProvider = Provider((ref) {
  return CreateDebt(ref.watch(debtRepositoryProvider));
});

final updateDebtProvider = Provider((ref) {
  return UpdateDebt(ref.watch(debtRepositoryProvider));
});

class DebtStatusFilter extends Notifier<DebtStatus?> {
  @override
  DebtStatus? build() => null;

  void setFilter(DebtStatus? status) => state = status;
}

final debtStatusFilterProvider =
    NotifierProvider<DebtStatusFilter, DebtStatus?>(DebtStatusFilter.new);

final debtsListProvider = AsyncNotifierProvider<DebtsListNotifier, List<Debt>>(
  DebtsListNotifier.new,
);

class DebtsListNotifier extends AsyncNotifier<List<Debt>> {
  @override
  Future<List<Debt>> build() async {
    final status = ref.watch(debtStatusFilterProvider);
    return ref.watch(getDebtsProvider)(status: status);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final status = ref.read(debtStatusFilterProvider);
      return ref.read(getDebtsProvider)(status: status);
    });
  }
}

class DebtDetailViewData {
  const DebtDetailViewData({
    required this.detail,
    required this.payments,
  });

  final DebtDetail detail;
  final List<Payment> payments;
}

final debtDetailProvider =
    FutureProvider.family<DebtDetailViewData?, String>((ref, id) async {
  final detail = await ref.watch(getDebtDetailProvider)(id);
  if (detail == null) return null;
  final payments =
      await GetPaymentsByDebt(ref.watch(paymentRepositoryProvider))(id);
  return DebtDetailViewData(detail: detail, payments: payments);
});
