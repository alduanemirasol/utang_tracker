import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:utang_tracker/features/notifications/domain/entities/debt_reminder.dart';
import 'package:utang_tracker/features/notifications/domain/repositories/reminder_scheduler.dart';

const int _reminderHour = 9;

class FlutterLocalNotificationsReminderScheduler implements ReminderScheduler {
  FlutterLocalNotificationsReminderScheduler({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'debt_reminders';
  static const String _channelName = 'Utang reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  tz.Location? _manila;
  bool _initialized = false;

  tz.Location get manila => _manila ??= tz.getLocation('Asia/Manila');

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  @override
  Future<void> requestNotificationsPermission() async {
    await initialize();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> rescheduleAll(List<DebtReminder> reminders) async {
    await initialize();
    await cancelAll();
    for (final reminder in reminders) {
      await _schedule(reminder);
    }
  }

  Future<void> _schedule(DebtReminder reminder) async {
    final date = reminder.scheduledDate;
    final firstFire = tz.TZDateTime(
      manila,
      date.year,
      date.month,
      date.day,
      _reminderHour,
    );
    await _plugin.zonedSchedule(
      id: _notificationId(reminder.debtId),
      title: reminder.title,
      body: reminder.body,
      scheduledDate: firstFire,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders for due and overdue utang',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  int _notificationId(String debtId) => debtId.hashCode & 0x7fffffff;

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}