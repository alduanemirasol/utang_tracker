enum BackupInterval {
  off,
  daily,
  threeDays,
  weekly,
}

extension BackupIntervalX on BackupInterval {
  Duration? get duration {
    switch (this) {
      case BackupInterval.off:
        return null;
      case BackupInterval.daily:
        return const Duration(days: 1);
      case BackupInterval.threeDays:
        return const Duration(days: 3);
      case BackupInterval.weekly:
        return const Duration(days: 7);
    }
  }

  String get label {
    switch (this) {
      case BackupInterval.off:
        return 'Off';
      case BackupInterval.daily:
        return 'Daily';
      case BackupInterval.threeDays:
        return '3 days';
      case BackupInterval.weekly:
        return 'Weekly';
    }
  }

  static BackupInterval fromName(String? name) {
    if (name == null) return BackupInterval.off;
    if (name == 'monthly') return BackupInterval.weekly;
    return BackupInterval.values.firstWhere(
      (interval) => interval.name == name,
      orElse: () => BackupInterval.off,
    );
  }
}
