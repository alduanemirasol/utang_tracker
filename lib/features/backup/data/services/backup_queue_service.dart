import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_prefs_keys.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_queue_entry.dart';
import 'package:utang_tracker/features/backup/domain/entities/audit_action.dart';
import 'package:utang_tracker/features/backup/domain/entities/audit_log_entry.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_status.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_local_datasource.dart';

class BackupQueueService {
  BackupQueueService({
    SharedPreferences? prefs,
    Connectivity? connectivity,
    BackupLocalDatasource? localDatasource,
  })  : _prefsOverride = prefs,
        _connectivity = connectivity ?? Connectivity(),
        _localDatasource = localDatasource ?? BackupLocalDatasource();

  final SharedPreferences? _prefsOverride;
  final Connectivity _connectivity;
  final BackupLocalDatasource _localDatasource;

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Future<void> Function()? _onDrain;

  Future<SharedPreferences> _getPrefs() async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  Future<List<BackupQueueEntry>> loadQueue() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(BackupPrefsKeys.queue);
    if (raw == null || raw.isEmpty) return [];
    return BackupQueueEntry.decodeList(raw);
  }

  Future<void> saveQueue(List<BackupQueueEntry> entries) async {
    final prefs = await _getPrefs();
    final trimmed =
        entries.length > 20 ? entries.sublist(entries.length - 20) : entries;
    await prefs.setString(BackupPrefsKeys.queue, BackupQueueEntry.encodeList(trimmed));
    await prefs.setBool(BackupPrefsKeys.queuedBackup, trimmed.isNotEmpty);
  }

  Future<void> enqueue(String type) async {
    final queue = await loadQueue();
    final now = DateTime.now().toUtc();
    if (queue.isNotEmpty) {
      final last = queue.last;
      if (last.type == type &&
          now.difference(last.timestamp).inMinutes < 5) {
        return;
      }
    }
    if (queue.any((queueEntry) => queueEntry.type == type && queueEntry.retryCount == 0)) {
      return;
    }
    queue.add(BackupQueueEntry(type: type, timestamp: now, retryCount: 0));
    final deduped = _deduplicate(queue);
    await saveQueue(deduped);
    await _localDatasource.appendAuditLog(
      AuditLogEntry(
        timestamp: DateTime.now(),
        action: AuditAction.failure,
        backupName: 'queued:$type',
        status: BackupStatus.failed,
        error: 'Queued for retry',
      ),
    );
  }

  List<BackupQueueEntry> _deduplicate(List<BackupQueueEntry> entries) {
    final seen = <String>{};
    final result = <BackupQueueEntry>[];
    for (final entry in entries) {
      final key = '${entry.type}_${entry.timestamp.millisecondsSinceEpoch}';
      if (seen.contains(key)) continue;
      seen.add(key);
      result.add(entry);
    }
    if (result.length > 20) return result.sublist(result.length - 20);
    return result;
  }

  Future<BackupQueueEntry?> peek() async {
    final queue = await loadQueue();
    return queue.isEmpty ? null : queue.first;
  }

  Future<void> dequeue() async {
    final queue = await loadQueue();
    if (queue.isEmpty) return;
    queue.removeAt(0);
    await saveQueue(queue);
  }

  Future<void> incrementRetry() async {
    final queue = await loadQueue();
    if (queue.isEmpty) return;
    final entry = queue.first;
    final nextCount = entry.retryCount + 1;
    if (nextCount >= 3) {
      queue.removeAt(0);
      await _localDatasource.appendAuditLog(
        AuditLogEntry(
          timestamp: DateTime.now(),
          action: AuditAction.failure,
          backupName: entry.type,
          status: BackupStatus.failed,
          error: 'Max retries exceeded',
        ),
      );
    } else {
      queue[0] = entry.copyWith(retryCount: nextCount);
    }
    await saveQueue(queue);
  }

  Duration backoffFor(int retryCount) {
    switch (retryCount) {
      case 0:
        return const Duration(minutes: 1);
      case 1:
        return const Duration(minutes: 5);
      case 2:
        return const Duration(minutes: 30);
      default:
        return const Duration(minutes: 30);
    }
  }

  void startListening(Future<void> Function() onDrain) {
    _onDrain = onDrain;
    _sub?.cancel();
    _sub = _connectivity.onConnectivityChanged.listen((results) async {
      final isOffline = results.contains(ConnectivityResult.none) || results.isEmpty;
      if (!isOffline) {
        await drain();
      }
    });
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> drain() async {
    if (_onDrain != null) {
      await _onDrain!.call();
    }
  }

  Future<bool> hasQueued() async {
    final queue = await loadQueue();
    return queue.isNotEmpty;
  }

  Future<int> queuedCount() async {
    final queue = await loadQueue();
    return queue.length;
  }
}
