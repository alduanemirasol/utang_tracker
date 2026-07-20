import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer.dart';
import 'package:utang_tracker/features/customers/domain/repositories/customer_repository.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/debts/domain/repositories/debt_repository.dart';
import 'package:utang_tracker/features/payments/domain/entities/payment.dart';
import 'package:utang_tracker/features/payments/domain/repositories/payment_repository.dart';

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

class GetCustomerDetail {
  const GetCustomerDetail({
    required this.customers,
    required this.debts,
    required this.payments,
  });

  final CustomerRepository customers;
  final DebtRepository debts;
  final PaymentRepository payments;

  Future<CustomerDetailData?> call(String id) async {
    final customer = await customers.getById(id);
    if (customer == null) return null;

    final debtList = await debts.getByCustomer(id);
    final paymentList = await payments.getByCustomer(id);

    var outstanding = Money.zero();
    for (final d in debtList) {
      outstanding = outstanding + d.balance;
    }

    return CustomerDetailData(
      customer: customer,
      debts: debtList,
      payments: paymentList,
      outstandingBalance: outstanding,
    );
  }
}
