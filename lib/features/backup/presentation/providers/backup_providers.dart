import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_prefs_keys.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_queue_entry.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_interval.dart';
import 'package:utang_tracker/features/backup/utils/backup_error_mapper.dart';

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
    final prefs = await SharedPreferences.getInstance();
    state = BackupIntervalX.fromName(prefs.getString(BackupPrefsKeys.interval));
  }

  Future<void> setInterval(BackupInterval value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(BackupPrefsKeys.interval, value.name);
    if (value == BackupInterval.off) {
      await prefs.remove(BackupPrefsKeys.nextScheduledTime);
    } else {
      final lastMs = prefs.getInt(BackupPrefsKeys.lastBackupTime);
      if (lastMs != null) {
        final last = DateTime.fromMillisecondsSinceEpoch(lastMs, isUtc: true);
        final next = last.add(value.duration!);
        await prefs.setInt(BackupPrefsKeys.nextScheduledTime, next.millisecondsSinceEpoch);
      }
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
  final prefs = await SharedPreferences.getInstance();
  final milliseconds = prefs.getInt(BackupPrefsKeys.lastBackupTime);
  if (milliseconds == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
});

final backupNextScheduledProvider = FutureProvider<DateTime?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final milliseconds = prefs.getInt(BackupPrefsKeys.nextScheduledTime);
  if (milliseconds != null) {
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }
  final lastMs = prefs.getInt(BackupPrefsKeys.lastBackupTime);
  final interval = BackupIntervalX.fromName(prefs.getString(BackupPrefsKeys.interval));
  if (lastMs == null || interval == BackupInterval.off) return null;
  final last = DateTime.fromMillisecondsSinceEpoch(lastMs, isUtc: true);
  return last.add(interval.duration!);
});

final backupLastErrorProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(BackupPrefsKeys.lastError);
  if (raw == null || raw.isEmpty) return null;
  return BackupErrorMapper.toTaglish(raw);
});

final backupQueueCountProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(BackupPrefsKeys.queue);
  if (raw == null || raw.isEmpty) return 0;
  return BackupQueueEntry.decodeList(raw).length;
});

final backupHasQueuedProvider = FutureProvider<bool>((ref) async {
  final count = await ref.watch(backupQueueCountProvider.future);
  return count > 0;
});

final backupQueueEntriesProvider = FutureProvider<List<BackupQueueEntry>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(BackupPrefsKeys.queue);
  if (raw == null || raw.isEmpty) return [];
  return BackupQueueEntry.decodeList(raw);
});

final backupConnectionDetailsProvider = FutureProvider<BackupConnectionDetails>((ref) async {
  final auth = ref.watch(googleAuthDatasourceProvider);
  final signedIn = await auth.isSignedIn();
  if (!signedIn) {
    return const BackupConnectionDetails(status: BackupConnectionStatus.signedOut);
  }
  try {
    await auth.getAuthHeaders();
    final email = auth.currentUser?.email ?? 'Signed in';
    return BackupConnectionDetails(status: BackupConnectionStatus.signedIn, email: email);
  } catch (caughtError) {
    final msg = caughtError.toString().toLowerCase();
    if (msg.contains('auth') || msg.contains('401')) {
      return const BackupConnectionDetails(status: BackupConnectionStatus.expired);
    }
    return BackupConnectionDetails(status: BackupConnectionStatus.signedIn, email: auth.currentUser?.email);
  }
});

enum BackupConnectionStatus { signedIn, signedOut, expired }

class BackupConnectionDetails {
  const BackupConnectionDetails({required this.status, this.email});
  final BackupConnectionStatus status;
  final String? email;
}

final backupAutoStatusProvider = FutureProvider<BackupAutoStatus>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final interval = BackupIntervalX.fromName(prefs.getString(BackupPrefsKeys.interval));
  if (interval == BackupInterval.off) {
    return const BackupAutoStatus(enabled: false);
  }
  final nextMs = prefs.getInt(BackupPrefsKeys.nextScheduledTime);
  DateTime? next;
  if (nextMs != null) {
    next = DateTime.fromMillisecondsSinceEpoch(nextMs, isUtc: true);
  } else {
    final lastMs = prefs.getInt(BackupPrefsKeys.lastBackupTime);
    if (lastMs != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs, isUtc: true);
      next = last.add(interval.duration!);
    }
  }
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

