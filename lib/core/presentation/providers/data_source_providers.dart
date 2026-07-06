import 'package:riverpod/riverpod.dart';
import 'package:utang_tracker/core/database/data_sources/debt_data_source.dart';
import 'package:utang_tracker/core/database/data_sources/debt_item_data_source.dart';
import 'package:utang_tracker/core/database/data_sources/payment_data_source.dart';
import 'package:utang_tracker/core/presentation/providers/database_provider.dart';
import 'package:utang_tracker/features/customers/infrastructure/customer_data_source.dart';
import 'package:utang_tracker/features/dashboard/infrastructure/dashboard_data_source.dart';

final customerDataSourceProvider = Provider<CustomerDataSource>((ref) {
  return CustomerDataSource(ref.read(databaseProvider));
});

final dashboardDataSourceProvider = Provider<DashboardDataSource>((ref) {
  return DashboardDataSource(ref.read(databaseProvider));
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
