import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/features/backup/presentation/providers/backup_providers.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';
import 'package:utang_tracker/features/notifications/presentation/providers/notification_providers.dart';
import 'package:utang_tracker/features/payments/presentation/providers/payment_providers.dart';

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
  ref.invalidate(backupHistoryProvider);
  ref.invalidate(backupAuditLogProvider);
  ref.invalidate(backupListProvider);
  if (customerId != null) {
    ref.invalidate(customerDetailProvider(customerId));
  }
  if (debtId != null) {
    ref.invalidate(debtDetailProvider(debtId));
  }
}

void invalidateBackupData(WidgetRef ref) {
  ref.invalidate(backupHistoryProvider);
  ref.invalidate(backupAuditLogProvider);
  ref.invalidate(backupListProvider);
  ref.invalidate(backupStorageQuotaProvider);
  ref.invalidate(backupLastSuccessfulProvider);
  ref.invalidate(backupNextScheduledProvider);
  ref.invalidate(backupLastErrorProvider);
  ref.invalidate(backupQueueCountProvider);
  ref.invalidate(backupConnectionDetailsProvider);
  ref.invalidate(backupAutoStatusProvider);
}
