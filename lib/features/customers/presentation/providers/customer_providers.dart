import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer_sort_order.dart';
import 'package:utang_tracker/features/customers/domain/usecases/customer_usecases.dart';
import 'package:utang_tracker/features/customers/domain/usecases/get_customer_detail.dart';

final getCustomersProvider = Provider((ref) {
  return GetCustomers(ref.watch(customerRepositoryProvider));
});

final searchCustomersProvider = Provider((ref) {
  return SearchCustomers(ref.watch(customerRepositoryProvider));
});

final getCustomerByIdProvider = Provider((ref) {
  return GetCustomerById(ref.watch(customerRepositoryProvider));
});

final createCustomerProvider = Provider((ref) {
  return CreateCustomer(ref.watch(customerRepositoryProvider));
});

final updateCustomerProvider = Provider((ref) {
  return UpdateCustomer(ref.watch(customerRepositoryProvider));
});

final deleteCustomerProvider = Provider((ref) {
  return DeleteCustomer(ref.watch(customerRepositoryProvider));
});

class CustomerSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

final customerSearchQueryProvider =
    NotifierProvider<CustomerSearchQuery, String>(CustomerSearchQuery.new);

class CustomerSortFilter extends Notifier<CustomerSortOrder> {
  @override
  CustomerSortOrder build() => CustomerSortOrder.nameAsc;

  void setSort(CustomerSortOrder order) => state = order;
}

final customerSortOrderProvider =
    NotifierProvider<CustomerSortFilter, CustomerSortOrder>(
      CustomerSortFilter.new,
    );

final customersListProvider =
    AsyncNotifierProvider<CustomersListNotifier, List<Customer>>(
      CustomersListNotifier.new,
    );

class CustomersListNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    final query = ref.watch(customerSearchQueryProvider);
    final sort = ref.watch(customerSortOrderProvider);
    final customers = query.trim().isEmpty
        ? await ref.watch(getCustomersProvider)()
        : await ref.watch(searchCustomersProvider)(query);
    return applyCustomerSort(customers, sort);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final query = ref.read(customerSearchQueryProvider);
      final sort = ref.read(customerSortOrderProvider);
      final customers = query.trim().isEmpty
          ? await ref.read(getCustomersProvider)()
          : await ref.read(searchCustomersProvider)(query);
      return applyCustomerSort(customers, sort);
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
