import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_connection_details.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_interval.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_queue_entry.dart';
import 'package:utang_tracker/core/error/backup_error_mapper.dart';

final backupAuditLogProvider = FutureProvider((ref) async {
  return ref.watch(auditLogRepositoryProvider).getEntries();
});

final backupHistoryProvider = FutureProvider((ref) async {
  return ref.watch(backupHistoryRepositoryProvider).getEntries();
});

final backupListProvider = FutureProvider((ref) async {
  return ref.watch(backupRepositoryProvider).browseBackups();
});

final backupConnectionProvider = FutureProvider<bool>((ref) async {
  return ref.watch(backupConnectionStatusProvider.future);
});

final backupStorageQuotaProvider = FutureProvider((ref) async {
  return ref.watch(backupQuotaProvider.future);
});

final backupIsLowStorageProvider = FutureProvider<bool>((ref) async {
  return ref.watch(backupRepositoryProvider).isLowStorage();
});

final backupIntervalProvider = NotifierProvider<BackupIntervalNotifier, BackupInterval>(BackupIntervalNotifier.new);

class BackupIntervalNotifier extends Notifier<BackupInterval> {
  @override
  BackupInterval build() {
    _load();
    return BackupInterval.off;
  }

  Future<void> _load() async {
    final prefs = ref.read(backupPrefsRepositoryProvider);
    state = await prefs.getInterval();
  }

  Future<void> setInterval(BackupInterval value) async {
    state = value;
    final prefs = ref.read(backupPrefsRepositoryProvider);
    await prefs.setInterval(value);
    final last = await prefs.getLastSuccessful();
    if (last != null) {
      await prefs.updateLastSuccessful(last);
    }
    ref.invalidate(backupAutoEnabledProvider);
    ref.invalidate(backupNextScheduledProvider);
    ref.invalidate(backupAutoStatusProvider);
  }
}

final backupAutoEnabledProvider = Provider<bool>((ref) {
  return ref.watch(backupIntervalProvider) != BackupInterval.off;
});

final backupLastSuccessfulProvider = FutureProvider<DateTime?>((ref) async {
  final prefs = ref.watch(backupPrefsRepositoryProvider);
  return prefs.getLastSuccessful();
});

final backupNextScheduledProvider = FutureProvider<DateTime?>((ref) async {
  final prefs = ref.watch(backupPrefsRepositoryProvider);
  return prefs.getNextScheduled();
});

final backupLastErrorProvider = FutureProvider<String?>((ref) async {
  final prefs = ref.watch(backupPrefsRepositoryProvider);
  final raw = await prefs.getLastError();
  if (raw == null || raw.isEmpty) return null;
  return BackupErrorMapper.toEnglish(raw);
});

final backupQueueCountProvider = FutureProvider<int>((ref) async {
  final queue = ref.watch(backupQueueRepositoryProvider);
  return queue.getQueueCount();
});

final backupHasQueuedProvider = FutureProvider<bool>((ref) async {
  final queue = ref.watch(backupQueueRepositoryProvider);
  return queue.hasQueued();
});

final backupQueueEntriesProvider = FutureProvider<List<BackupQueueEntry>>((ref) async {
  final queue = ref.watch(backupQueueRepositoryProvider);
  return queue.getQueue();
});

final backupConnectionDetailsProvider = FutureProvider<BackupConnectionDetails>((ref) async {
  final connection = ref.watch(getConnectionDetailsProvider);
  return connection.call();
});

final backupAutoStatusProvider = FutureProvider<BackupAutoStatus>((ref) async {
  final prefs = ref.watch(backupPrefsRepositoryProvider);
  final interval = await prefs.getInterval();
  if (interval == BackupInterval.off) {
    return const BackupAutoStatus(enabled: false);
  }
  final next = await prefs.getNextScheduled();
  return BackupAutoStatus(enabled: true, nextRun: next, interval: interval);
});

class BackupAutoStatus {
  const BackupAutoStatus({required this.enabled, this.nextRun, this.interval});
  final bool enabled;
  final DateTime? nextRun;
  final BackupInterval? interval;
}

final formattedLastBackupProvider = FutureProvider<String?>((ref) async {
  final selectedDate = await ref.watch(backupLastSuccessfulProvider.future);
  if (selectedDate == null) return null;
  return DateFormatters.backupDisplay(selectedDate);
});

final formattedNextBackupProvider = FutureProvider<String?>((ref) async {
  final selectedDate = await ref.watch(backupNextScheduledProvider.future);
  if (selectedDate == null) return null;
  return DateFormatters.backupDisplay(selectedDate);
});

final connectivityStatusProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});
