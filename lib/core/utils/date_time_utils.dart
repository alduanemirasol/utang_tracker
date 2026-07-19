class DateTimeUtils {
  DateTimeUtils._();

  /// Combines the local calendar day from [date] with the local clock time
  /// from [time].
  static DateTime combineLocalDateAndTime(DateTime date, DateTime time) {
    final localDate = date.toLocal();
    final localTime = time.toLocal();

    return DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      localTime.hour,
      localTime.minute,
      localTime.second,
      localTime.millisecond,
      localTime.microsecond,
    );
  }
}
