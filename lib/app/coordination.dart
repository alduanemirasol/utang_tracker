import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';
import 'package:utang_tracker/features/notifications/presentation/providers/notification_providers.dart';
import 'package:utang_tracker/features/notifications/domain/repositories/reminder_scheduler.dart';
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
  syncDebtReminders(ref);
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

void syncDebtReminders(WidgetRef ref) {
  final scheduler = ref.read(reminderSchedulerProvider);
  unawaited(_syncDebtReminders(ref, scheduler));
}

Future<void> _syncDebtReminders(
  WidgetRef ref,
  ReminderScheduler scheduler,
) async {
  try {
    final enabled = await ref.read(reminderEnabledProvider.future);
    if (!enabled) {
      await scheduler.cancelAll();
      return;
    }
    final reminders = await ref.read(buildDebtRemindersProvider)();
    await scheduler.rescheduleAll(reminders);
  } catch (_) {}
}
