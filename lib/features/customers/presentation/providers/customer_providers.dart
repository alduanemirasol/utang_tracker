import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer.dart';
import 'package:utang_tracker/features/customers/domain/usecases/customer_usecases.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/debts/domain/usecases/debt_usecases.dart';
import 'package:utang_tracker/features/payments/domain/entities/payment.dart';
import 'package:utang_tracker/features/payments/domain/usecases/payment_usecases.dart';

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

final customersListProvider =
    AsyncNotifierProvider<CustomersListNotifier, List<Customer>>(
  CustomersListNotifier.new,
);

class CustomersListNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    final query = ref.watch(customerSearchQueryProvider);
    if (query.trim().isEmpty) {
      return ref.watch(getCustomersProvider)();
    }
    return ref.watch(searchCustomersProvider)(query);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final query = ref.read(customerSearchQueryProvider);
      if (query.trim().isEmpty) {
        return ref.read(getCustomersProvider)();
      }
      return ref.read(searchCustomersProvider)(query);
    });
  }
}

class CustomerDetailData {
  const CustomerDetailData({
    required this.customer,
    required this.debts,
    required this.payments,
    required this.outstandingBalance,
  });

  final Customer customer;
  final List<Debt> debts;
  final List<Payment> payments;
  final Money outstandingBalance;
}

final customerDetailProvider = FutureProvider.family<CustomerDetailData?, String>(
  (ref, id) async {
    final customer = await ref.watch(getCustomerByIdProvider)(id);
    if (customer == null) return null;

    final debts = await GetDebtsByCustomer(ref.watch(debtRepositoryProvider))(id);
    final payments =
        await GetPaymentsByCustomer(ref.watch(paymentRepositoryProvider))(id);

    var outstanding = Money.zero();
    for (final d in debts) {
      outstanding = outstanding + d.balance;
    }

    return CustomerDetailData(
      customer: customer,
      debts: debts,
      payments: payments,
      outstandingBalance: outstanding,
    );
  },
);
