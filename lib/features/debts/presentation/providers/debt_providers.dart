import 'package:riverpod/riverpod.dart';
import 'package:utang_tracker/core/domain/debt.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/presentation/providers/database_provider.dart';
import 'package:utang_tracker/core/presentation/providers/data_source_providers.dart';
import 'package:utang_tracker/features/debts/domain/debt_detail.dart';
import 'package:utang_tracker/features/debts/domain/debt_repository.dart';
import 'package:utang_tracker/features/debts/infrastructure/debt_repository_impl.dart';
import 'package:utang_tracker/features/debts/application/create_debt_use_case.dart';
import 'package:utang_tracker/features/debts/application/get_debts_use_case.dart';
import 'package:utang_tracker/features/debts/application/get_debt_use_case.dart';
import 'package:utang_tracker/features/debts/application/get_debt_detail_use_case.dart';
import 'package:utang_tracker/features/debts/application/update_debt_use_case.dart';
import 'package:utang_tracker/features/debts/application/delete_debt_use_case.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(
    ref.read(debtDataSourceProvider),
    ref.read(debtItemDataSourceProvider),
    ref.read(paymentDataSourceProvider),
    ref.read(databaseProvider),
  );
});

final createDebtUseCaseProvider = Provider<CreateDebtUseCase>((ref) {
  return CreateDebtUseCase(ref.read(debtRepositoryProvider));
});

final getDebtsUseCaseProvider = Provider<GetDebtsUseCase>((ref) {
  return GetDebtsUseCase(ref.read(debtRepositoryProvider));
});

final getDebtUseCaseProvider = Provider<GetDebtUseCase>((ref) {
  return GetDebtUseCase(ref.read(debtRepositoryProvider));
});

final getDebtDetailUseCaseProvider = Provider<GetDebtDetailUseCase>((ref) {
  return GetDebtDetailUseCase(ref.read(debtRepositoryProvider));
});

final updateDebtUseCaseProvider = Provider<UpdateDebtUseCase>((ref) {
  return UpdateDebtUseCase(ref.read(debtRepositoryProvider));
});

final deleteDebtUseCaseProvider = Provider<DeleteDebtUseCase>((ref) {
  return DeleteDebtUseCase(ref.read(debtRepositoryProvider));
});

class DebtListNotifier extends AsyncNotifier<List<Debt>> {
  String? _customerId;
  DebtStatus? _status;

  @override
  Future<List<Debt>> build() async {
    final result = await ref.read(getDebtsUseCaseProvider).execute(
          customerId: _customerId,
          status: _status,
        );
    return switch (result) {
      Success(data: final debts) => debts,
      Error(failure: final f) => throw f,
    };
  }

  Future<void> filter({String? customerId, DebtStatus? status}) async {
    _customerId = customerId;
    _status = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(getDebtsUseCaseProvider).execute(
            customerId: _customerId,
            status: _status,
          );
      return switch (result) {
        Success(data: final debts) => debts,
        Error(failure: final f) => throw f,
      };
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(getDebtsUseCaseProvider).execute(
            customerId: _customerId,
            status: _status,
          );
      return switch (result) {
        Success(data: final debts) => debts,
        Error(failure: final f) => throw f,
      };
    });
  }
}

final debtListProvider = AsyncNotifierProvider<DebtListNotifier, List<Debt>>(
  DebtListNotifier.new,
);

/// Unfiltered debt list for cross-screen aggregates (customer balances, etc.).
final allDebtsProvider = FutureProvider<List<Debt>>((ref) async {
  final result = await ref.read(getDebtsUseCaseProvider).execute();
  return switch (result) {
    Success(data: final debts) => debts,
    Error(failure: final f) => throw f,
  };
});

final debtDetailProvider =
    FutureProvider.family<DebtDetail, String>((ref, id) async {
  final result = await ref.read(getDebtDetailUseCaseProvider).execute(id);
  return switch (result) {
    Success(data: final detail) => detail,
    Error(failure: final f) => throw f,
  };
});
