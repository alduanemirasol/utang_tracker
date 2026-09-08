import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:utang_tracker/app.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_prefs_keys.dart';
import 'package:utang_tracker/features/backup/data/services/backup_queue_service.dart';
import 'package:utang_tracker/features/backup/data/services/backup_scheduler.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_interval.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  try {
    // ignore: deprecated_member_use
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    final prefs = await SharedPreferences.getInstance();
    final interval = BackupIntervalX.fromName(prefs.getString(BackupPrefsKeys.interval));
    await BackupScheduler().register(interval);
  } catch (_) {}
  try {
    final queue = BackupQueueService();
    Connectivity().onConnectivityChanged.listen((results) async {
      final isOffline = results.contains(ConnectivityResult.none) || results.isEmpty;
      if (!isOffline) {
        final queuedEntries = await queue.loadQueue();
        if (queuedEntries.isEmpty) return;
        for (final entry in List.from(queuedEntries)) {
          if (entry.retryCount >= 3) {
            await queue.dequeue();
            continue;
          }
          final backoff = queue.backoffFor(entry.retryCount);
          final due = entry.timestamp.add(backoff);
          if (DateTime.now().toUtc().isBefore(due)) continue;
        }
      }
    });
  } catch (_) {}
  runApp(const ProviderScope(child: UtangTrackerApp()));
}
