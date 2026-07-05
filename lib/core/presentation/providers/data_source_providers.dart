import 'package:riverpod/riverpod.dart';
import 'package:utang_tracker/core/presentation/providers/database_provider.dart';
import 'package:utang_tracker/features/customers/infrastructure/customer_data_source.dart';
import 'package:utang_tracker/features/debts/infrastructure/debt_data_source.dart';
import 'package:utang_tracker/features/debt_items/infrastructure/debt_item_data_source.dart';
import 'package:utang_tracker/features/payments/infrastructure/payment_data_source.dart';

final customerDataSourceProvider = Provider<CustomerDataSource>((ref) {
  return CustomerDataSource(ref.read(databaseProvider));
});

final debtDataSourceProvider = Provider<DebtDataSource>((ref) {
  return DebtDataSource(ref.read(databaseProvider));
});

final debtItemDataSourceProvider = Provider<DebtItemDataSource>((ref) {
  return DebtItemDataSource(ref.read(databaseProvider));
});

final paymentDataSourceProvider = Provider<PaymentDataSource>((ref) {
  return PaymentDataSource(ref.read(databaseProvider));
});
