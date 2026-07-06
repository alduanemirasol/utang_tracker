import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

const _philippineLocation = 'Asia/Manila';

class DateTimeHelper {
  static late tz.Location _philippines;

  static void initialize() {
    tz.initializeTimeZones();
    _philippines = tz.getLocation(_philippineLocation);
  }

  static DateTime now() => DateTime.now().toUtc();

  static DateTime nowPH() => tz.TZDateTime.now(_philippines);

  static DateTime createdAt() => now();

  static DateTime updatedAt() => now();

  static String toIso(DateTime dt) => dt.toUtc().toIso8601String();

  static DateTime? fromIso(String? iso) =>
      iso != null ? DateTime.parse(iso).toLocal() : null;

  static DateTime toPH(DateTime dt) =>
      tz.TZDateTime.from(dt.toUtc(), _philippines);

  static String formatDate(DateTime dt) =>
      DateFormat('MMM d, yyyy').format(toPH(dt));

  static String formatDateTime(DateTime dt) =>
      DateFormat('MMM d, yyyy, h:mm a').format(toPH(dt));

  static String formatShortDate(DateTime dt) =>
      DateFormat('MM/dd/yyyy').format(toPH(dt));

  static String formatTime(DateTime dt) =>
      DateFormat('h:mm a').format(toPH(dt));

  static String formatMonthDay(DateTime dt) =>
      DateFormat('MMM d').format(toPH(dt));
}
