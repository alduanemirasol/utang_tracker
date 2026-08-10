import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer.dart';
import 'package:utang_tracker/features/customers/domain/usecases/get_customer_detail.dart';

class CustomerSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

final customerSearchQueryProvider =
    NotifierProvider<CustomerSearchQuery, String>(CustomerSearchQuery.new);

final customersListProvider =
    AsyncNotifierProvider<CustomersListNotifier, List<Customer>>(
      CustomersListNotifier.new,
    );

class CustomersListNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    final query = ref.watch(customerSearchQueryProvider);
    final repo = ref.watch(customerRepositoryProvider);
    if (query.trim().isEmpty) {
      return repo.getAll();
    }
    return repo.search(query);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final query = ref.read(customerSearchQueryProvider);
      final repo = ref.read(customerRepositoryProvider);
      if (query.trim().isEmpty) {
        return repo.getAll();
      }
      return repo.search(query);
    });
  }
}

final getCustomerDetailProvider = Provider((ref) {
  return GetCustomerDetail(
    customers: ref.watch(customerRepositoryProvider),
    debts: ref.watch(debtRepositoryProvider),
    payments: ref.watch(paymentRepositoryProvider),
  );
});

final customerDetailProvider =
    FutureProvider.family<CustomerDetailData?, String>((ref, id) async {
      return ref.watch(getCustomerDetailProvider)(id);
    });
