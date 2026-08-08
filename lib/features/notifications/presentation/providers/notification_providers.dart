import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/notifications/domain/entities/debt_notification.dart';
import 'package:utang_tracker/features/notifications/domain/usecases/get_debt_notifications.dart';

final getDebtNotificationsProvider = Provider((ref) {
  return GetDebtNotifications(ref.watch(debtRepositoryProvider));
});

final debtNotificationsProvider =
    AsyncNotifierProvider<DebtNotificationsNotifier, DebtNotificationFeed>(
      DebtNotificationsNotifier.new,
    );

class DebtNotificationsNotifier extends AsyncNotifier<DebtNotificationFeed> {
  @override
  Future<DebtNotificationFeed> build() {
    return ref.watch(getDebtNotificationsProvider)();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(getDebtNotificationsProvider)(),
    );
  }
}

class ReminderEnabled extends AsyncNotifier<bool> {
  static const String _key = 'reminders_enabled';

  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, value);
    state = AsyncData(value);
  }
}

final reminderEnabledProvider = AsyncNotifierProvider<ReminderEnabled, bool>(
  ReminderEnabled.new,
);
