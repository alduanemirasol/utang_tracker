import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';
import 'package:utang_tracker/features/notifications/presentation/providers/notification_providers.dart';
import 'package:utang_tracker/features/payments/presentation/providers/payment_providers.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_period.dart';
import 'package:utang_tracker/features/reports/presentation/providers/report_providers.dart';

void invalidateBusinessData(
  WidgetRef ref, {
  String? customerId,
  String? debtId,
}) {
  ref.invalidate(customersListProvider);
  ref.invalidate(debtsListProvider);
  ref.invalidate(paymentsListProvider);
  ref.invalidate(paymentFilterOptionsProvider);
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(debtNotificationsProvider);
  for (final period in CollectionPeriod.values) {
    ref.invalidate(collectionReportProvider(period));
  }
  if (customerId != null) {
    ref.invalidate(customerDetailProvider(customerId));
  }
  if (debtId != null) {
    ref.invalidate(debtDetailProvider(debtId));
  }
}

void refreshAfterDatabaseRestore(WidgetRef ref) {
  ref.invalidate(databaseProvider);
  ref.invalidate(customerRepositoryProvider);
  ref.invalidate(debtRepositoryProvider);
  ref.invalidate(paymentRepositoryProvider);
  ref.invalidate(dashboardRepositoryProvider);
  invalidateBusinessData(ref);
}
