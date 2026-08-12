import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer.dart';
import 'package:utang_tracker/features/customers/domain/usecases/get_customer_detail.dart';

enum CustomerSortOrder {
  nameAsc('Name A-Z'),
  nameDesc('Name Z-A'),
  newest('Newest'),
  oldest('Oldest');

  const CustomerSortOrder(this.label);

  final String label;
}

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
    final repo = ref.watch(customerRepositoryProvider);
    final customers = query.trim().isEmpty
        ? await repo.getAll()
        : await repo.search(query);
    return applyCustomerSort(customers, sort);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final query = ref.read(customerSearchQueryProvider);
      final sort = ref.read(customerSortOrderProvider);
      final repo = ref.read(customerRepositoryProvider);
      final customers = query.trim().isEmpty
          ? await repo.getAll()
          : await repo.search(query);
      return applyCustomerSort(customers, sort);
    });
  }
}

List<Customer> applyCustomerSort(
  List<Customer> customers,
  CustomerSortOrder sort,
) {
  final sorted = List<Customer>.from(customers);
  switch (sort) {
    case CustomerSortOrder.nameAsc:
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    case CustomerSortOrder.nameDesc:
      sorted.sort(
        (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      );
    case CustomerSortOrder.newest:
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case CustomerSortOrder.oldest:
      sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
  return sorted;
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
