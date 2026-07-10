import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_sort_order.dart';
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

class DebtSortFilter extends Notifier<DebtSortOrder> {
  @override
  DebtSortOrder build() => DebtSortOrder.newest;

  void setSort(DebtSortOrder order) => state = order;
}

final debtSortOrderProvider =
    NotifierProvider<DebtSortFilter, DebtSortOrder>(DebtSortFilter.new);

final debtsListProvider = AsyncNotifierProvider<DebtsListNotifier, List<Debt>>(
  DebtsListNotifier.new,
);

class DebtsListNotifier extends AsyncNotifier<List<Debt>> {
  @override
  Future<List<Debt>> build() async {
    final status = ref.watch(debtStatusFilterProvider);
    final sort = ref.watch(debtSortOrderProvider);
    final debts = await ref.watch(getDebtsProvider)(status: status);
    return _applySort(debts, sort);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final status = ref.read(debtStatusFilterProvider);
      final sort = ref.read(debtSortOrderProvider);
      final debts = await ref.read(getDebtsProvider)(status: status);
      return _applySort(debts, sort);
    });
  }

  List<Debt> _applySort(List<Debt> debts, DebtSortOrder sort) {
    final sorted = List<Debt>.from(debts);
    switch (sort) {
      case DebtSortOrder.newest:
        sorted.sort(
          (a, b) => b.transactionDate.compareTo(a.transactionDate),
        );
      case DebtSortOrder.highestBalance:
        sorted.sort(
          (a, b) => b.balance.centavos.compareTo(a.balance.centavos),
        );
      case DebtSortOrder.lowestBalance:
        sorted.sort(
          (a, b) => a.balance.centavos.compareTo(b.balance.centavos),
        );
    }
    return sorted;
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
