import 'package:utang_tracker/features/notifications/domain/entities/debt_reminder.dart';

abstract class ReminderScheduler {
  Future<void> initialize();

  Future<void> rescheduleAll(List<DebtReminder> reminders);

  Future<void> cancelAll();
}