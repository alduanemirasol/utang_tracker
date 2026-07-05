import 'package:riverpod/riverpod.dart';
import 'package:utang_tracker/core/presentation/providers/database_provider.dart';
import 'package:utang_tracker/core/presentation/providers/data_source_providers.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item_repository.dart';
import 'package:utang_tracker/features/debt_items/infrastructure/debt_item_repository_impl.dart';
import 'package:utang_tracker/features/debt_items/application/create_debt_item_use_case.dart';
import 'package:utang_tracker/features/debt_items/application/get_debt_items_use_case.dart';
import 'package:utang_tracker/features/debt_items/application/get_debt_item_use_case.dart';
import 'package:utang_tracker/features/debt_items/application/update_debt_item_use_case.dart';
import 'package:utang_tracker/features/debt_items/application/delete_debt_item_use_case.dart';


final debtItemRepositoryProvider = Provider<DebtItemRepository>((ref) {
  return DebtItemRepositoryImpl(
    ref.read(debtItemDataSourceProvider),
    ref.read(debtDataSourceProvider),
    ref.read(databaseProvider),
  );
});


final createDebtItemUseCaseProvider = Provider<CreateDebtItemUseCase>((ref) {
  return CreateDebtItemUseCase(ref.read(debtItemRepositoryProvider));
});

final getDebtItemsUseCaseProvider = Provider<GetDebtItemsUseCase>((ref) {
  return GetDebtItemsUseCase(ref.read(debtItemRepositoryProvider));
});

final getDebtItemUseCaseProvider = Provider<GetDebtItemUseCase>((ref) {
  return GetDebtItemUseCase(ref.read(debtItemRepositoryProvider));
});

final updateDebtItemUseCaseProvider = Provider<UpdateDebtItemUseCase>((ref) {
  return UpdateDebtItemUseCase(ref.read(debtItemRepositoryProvider));
});

final deleteDebtItemUseCaseProvider = Provider<DeleteDebtItemUseCase>((ref) {
  return DeleteDebtItemUseCase(ref.read(debtItemRepositoryProvider));
});


final debtItemListProvider = FutureProvider.family<List<DebtItem>, String>((ref, debtId) async {
  final result = await ref.read(getDebtItemsUseCaseProvider).execute(debtId);
  return switch (result) {
    Success(data: final items) => items,
    Error(failure: final f) => throw f,
  };
});
