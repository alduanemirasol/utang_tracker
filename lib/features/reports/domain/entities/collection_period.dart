enum CollectionPeriod {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month');

  const CollectionPeriod(this.label);

  final String label;

  (DateTime, DateTime) localRange(DateTime now) {
    final local = now.toLocal();
    final start = switch (this) {
      CollectionPeriod.today => DateTime(local.year, local.month, local.day),
      CollectionPeriod.thisWeek => _startOfWeek(local),
      CollectionPeriod.thisMonth => DateTime(local.year, local.month, 1),
    };
    final end = DateTime(local.year, local.month, local.day, 23, 59, 59, 999);
    return (start, end);
  }

  static DateTime _startOfWeek(DateTime local) {
    final today = DateTime(local.year, local.month, local.day);
    return today.subtract(Duration(days: today.weekday - DateTime.monday));
  }
}