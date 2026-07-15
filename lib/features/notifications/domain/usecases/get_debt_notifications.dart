import 'package:utang_tracker/features/debts/domain/repositories/debt_repository.dart';
import 'package:utang_tracker/features/notifications/domain/entities/debt_notification.dart';

class GetDebtNotifications {
  const GetDebtNotifications(this._debts);

  final DebtRepository _debts;

  Future<DebtNotificationFeed> call({DateTime? now}) async {
    final debts = await _debts.getAll();
    return DebtNotificationFeed.fromDebts(debts, now: now ?? DateTime.now());
  }
}
