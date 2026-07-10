import 'package:intl/intl.dart';

class DateFormatters {
  DateFormatters._();

  static final _display = DateFormat('MMM d, yyyy');
  static final _displayWithTime = DateFormat('MMM d, yyyy · h:mm a');
  static final _dayKey = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime date) => _display.format(date.toLocal());

  static String formatDateTime(DateTime date) =>
      _displayWithTime.format(date.toLocal());

  static String dayKey(DateTime date) => _dayKey.format(date.toLocal());

  static bool isSameLocalDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  static DateTime startOfLocalDay(DateTime date) {
    final l = date.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  static DateTime endOfLocalDay(DateTime date) {
    final l = date.toLocal();
    return DateTime(l.year, l.month, l.day, 23, 59, 59, 999);
  }
}
