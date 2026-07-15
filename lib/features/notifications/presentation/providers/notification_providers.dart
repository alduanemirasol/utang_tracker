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
