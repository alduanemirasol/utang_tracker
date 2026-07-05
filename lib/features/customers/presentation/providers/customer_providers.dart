import 'package:riverpod/riverpod.dart';
import 'package:utang_tracker/core/presentation/providers/database_provider.dart';
import 'package:utang_tracker/core/presentation/providers/data_source_providers.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/customers/domain/customer.dart';
import 'package:utang_tracker/features/customers/domain/customer_repository.dart';
import 'package:utang_tracker/features/customers/infrastructure/customer_repository_impl.dart';
import 'package:utang_tracker/features/customers/application/create_customer_use_case.dart';
import 'package:utang_tracker/features/customers/application/get_customers_use_case.dart';
import 'package:utang_tracker/features/customers/application/get_customer_use_case.dart';
import 'package:utang_tracker/features/customers/application/get_customer_summary_use_case.dart';
import 'package:utang_tracker/features/customers/application/update_customer_use_case.dart';
import 'package:utang_tracker/features/customers/application/delete_customer_use_case.dart';


final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl(
    ref.read(customerDataSourceProvider),
    ref.read(debtDataSourceProvider),
    ref.read(debtItemDataSourceProvider),
    ref.read(paymentDataSourceProvider),
    ref.read(databaseProvider),
  );
});


final createCustomerUseCaseProvider = Provider<CreateCustomerUseCase>((ref) {
  return CreateCustomerUseCase(ref.read(customerRepositoryProvider));
});

final getCustomersUseCaseProvider = Provider<GetCustomersUseCase>((ref) {
  return GetCustomersUseCase(ref.read(customerRepositoryProvider));
});

final getCustomerUseCaseProvider = Provider<GetCustomerUseCase>((ref) {
  return GetCustomerUseCase(ref.read(customerRepositoryProvider));
});

final getCustomerSummaryUseCaseProvider = Provider<GetCustomerSummaryUseCase>((ref) {
  return GetCustomerSummaryUseCase(ref.read(customerRepositoryProvider));
});

final updateCustomerUseCaseProvider = Provider<UpdateCustomerUseCase>((ref) {
  return UpdateCustomerUseCase(ref.read(customerRepositoryProvider));
});

final deleteCustomerUseCaseProvider = Provider<DeleteCustomerUseCase>((ref) {
  return DeleteCustomerUseCase(ref.read(customerRepositoryProvider));
});


class CustomerListNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    final result = await ref.read(getCustomersUseCaseProvider).execute();
    return switch (result) {
      Success(data: final customers) => customers,
      Error(failure: final f) => throw f,
    };
  }

  Future<void> search(String query) async {
    final result = await ref.read(getCustomersUseCaseProvider).execute(query: query);
    state = switch (result) {
      Success(data: final customers) => AsyncData(customers),
      Error(failure: final f) => AsyncError(f, StackTrace.current),
    };
  }

  Future<void> refresh() async => _reload();

  Future<void> delete(String id) async {
    final result = await ref.read(deleteCustomerUseCaseProvider).execute(id);
    if (result is Success) {
      await _reload();
    } else if (result is Error) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(getCustomersUseCaseProvider).execute();
      return switch (result) {
        Success(data: final customers) => customers,
        Error(failure: final f) => throw f,
      };
    });
  }
}

final customerListProvider = AsyncNotifierProvider<CustomerListNotifier, List<Customer>>(
  CustomerListNotifier.new,
);
