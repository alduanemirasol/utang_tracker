import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_snackbar.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_prefs_keys.dart';
import 'package:utang_tracker/features/backup/data/services/backup_queue_service.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_interval.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_status.dart';
import 'package:utang_tracker/features/backup/presentation/providers/backup_providers.dart';
import 'package:utang_tracker/features/backup/utils/backup_error_mapper.dart';

class BackupSettingsPage extends ConsumerStatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  ConsumerState<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends ConsumerState<BackupSettingsPage> {
  double _progress = 0;
  bool _isBackingUp = false;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _doBackupNow() async {
    setState(() {
      _isBackingUp = true;
      _progress = 0;
    });
    try {
      final repo = ref.read(backupRepositoryProvider);
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty;
      if (isOffline) {
        final queue = BackupQueueService();
        await queue.enqueue('manual');
        ref.invalidate(backupQueueCountProvider);
        ref.invalidate(backupHasQueuedProvider);
        if (mounted) AppSnackBar.info(context, 'Walang internet. Na-queue ang backup.');
        return;
      }
      int attempts = 0;
      while (attempts < 3) {
        try {
          await repo.createBackup();
          break;
        } catch (e) {
          final msg = e.toString().toLowerCase();
          if (msg.contains('network') || msg.contains('socket')) {
            attempts++;
            if (attempts >= 3) rethrow;
            final delay = [const Duration(minutes: 1), const Duration(minutes: 5), const Duration(minutes: 30)][attempts - 1];
            await Future.delayed(delay);
            continue;
          }
          rethrow;
        }
      }
      if (mounted) AppSnackBar.success(context, 'Backup natapos na!');
      ref.invalidate(backupLastSuccessfulProvider);
      ref.invalidate(backupNextScheduledProvider);
      ref.invalidate(backupHistoryProvider);
      ref.invalidate(backupAuditLogProvider);
      ref.invalidate(backupLastErrorProvider);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(BackupPrefsKeys.lastError);
    } catch (e) {
      final msg = BackupErrorMapper.toTaglish(e);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(BackupPrefsKeys.lastError, e.toString());
      ref.invalidate(backupLastErrorProvider);
      if (e.toString().toLowerCase().contains('duplicate')) {
        if (mounted) AppSnackBar.info(context, msg);
      } else {
        if (mounted) AppSnackBar.error(context, msg);
      }
      if (e.toString().toLowerCase().contains('network')) {
        final queue = BackupQueueService();
        await queue.enqueue('manual');
        ref.invalidate(backupQueueCountProvider);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
          _progress = 0;
        });
      }
    }
  }

  Future<void> _handleIntervalChange(BackupInterval value) async {
    await ref.read(backupIntervalProvider.notifier).setInterval(value);
    final scheduler = ref.read(backupSchedulerProvider);
    await scheduler.register(value);
    ref.invalidate(backupAutoStatusProvider);
    ref.invalidate(backupNextScheduledProvider);
    if (mounted) {
      AppSnackBar.info(context, value == BackupInterval.off ? 'Auto backup naka-off' : 'Auto backup: ${value.label}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final interval = ref.watch(backupIntervalProvider);
    final connection = ref.watch(backupConnectionDetailsProvider);
    final autoStatus = ref.watch(backupAutoStatusProvider);
    final lastBackup = ref.watch(backupLastSuccessfulProvider);
    final nextBackup = ref.watch(backupNextScheduledProvider);
    final lastError = ref.watch(backupLastErrorProvider);
    final hasQueued = ref.watch(backupHasQueuedProvider);
    final queueCount = ref.watch(backupQueueCountProvider);
    final quota = ref.watch(backupQuotaProvider);
    final isLow = ref.watch(backupIsLowStorageProvider);
    final history = ref.watch(backupHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          connection.when(
            data: (details) {
              final String title;
              final String subtitle;
              final IconData icon;
              final Color color;
              switch (details.status) {
                case BackupConnectionStatus.signedIn:
                  title = 'Naka-connect sa Google Drive';
                  subtitle = details.email ?? 'Naka-sign in';
                  icon = Icons.cloud_done_rounded;
                  color = AppColors.paid;
                  break;
                case BackupConnectionStatus.expired:
                  title = 'Expired ang Google sign-in';
                  subtitle = 'Mag-sign in ulit para mag-backup';
                  icon = Icons.cloud_off_rounded;
                  color = AppColors.partial;
                  break;
                case BackupConnectionStatus.signedOut:
                  title = 'Hindi naka-connect';
                  subtitle = 'Mag-sign in sa Google Drive';
                  icon = Icons.cloud_off_rounded;
                  color = AppColors.unpaid;
                  break;
              }
              return Card(
                color: AppColors.surfaceCard,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.outline)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 28),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        ]),
                      ),
                      TextButton(
                        onPressed: () async {
                          final auth = ref.read(googleAuthDatasourceProvider);
                          if (details.status == BackupConnectionStatus.signedIn) {
                            await auth.signOut();
                            ref.invalidate(backupConnectionDetailsProvider);
                            if (context.mounted) AppSnackBar.info(context, 'Nag-sign out sa Google Drive');
                          } else {
                            final acc = await auth.signIn();
                            ref.invalidate(backupConnectionDetailsProvider);
                            if (context.mounted) {
                              if (acc != null) {
                                AppSnackBar.success(context, 'Naka-sign in: ${acc.email}');
                              } else {
                                AppSnackBar.error(context, 'Hindi natapos ang sign-in');
                              }
                            }
                          }
                        },
                        child: Text(details.status == BackupConnectionStatus.signedIn ? 'Sign out' : 'Sign in'),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: AppSpacing.md),
          autoStatus.when(
            data: (s) {
              final String text;
              if (!s.enabled) {
                text = 'Auto backup naka-off';
              } else if (s.nextRun != null) {
                text = 'Susunod na backup: ${DateFormatters.backupDisplay(s.nextRun!)}';
              } else {
                text = 'Auto backup naka-on (${s.interval?.label ?? ''})';
              }
              return Card(
                color: AppColors.surfaceCard,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.outline)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Icon(s.enabled ? Icons.schedule_rounded : Icons.schedule_outlined, color: s.enabled ? AppColors.primaryDark : AppColors.textMuted),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
                      if (s.enabled) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.paidBg, borderRadius: BorderRadius.circular(12)), child: const Text('Enabled', style: TextStyle(color: AppColors.paid))),
                      if (!s.enabled) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.unpaidBg, borderRadius: BorderRadius.circular(12)), child: const Text('Disabled', style: TextStyle(color: AppColors.unpaid))),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            color: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.outline)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Auto backup interval', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<BackupInterval>(
                  initialValue: interval,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                  items: BackupInterval.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
                  onChanged: (v) {
                    if (v != null) _handleIntervalChange(v);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                lastBackup.when(
                  data: (dt) => Row(children: [const Icon(Icons.check_circle_outline, size: 16, color: AppColors.textMuted), const SizedBox(width: 6), Expanded(child: Text(dt == null ? 'Huling backup: Wala pa' : 'Huling backup: ${DateFormatters.backupDisplay(dt)}', style: Theme.of(context).textTheme.bodySmall))]),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 4),
                if (interval != BackupInterval.off)
                  nextBackup.when(
                    data: (dt) => Row(children: [const Icon(Icons.timer_outlined, size: 16, color: AppColors.textMuted), const SizedBox(width: 6), Expanded(child: Text(dt == null ? 'Susunod: --' : 'Susunod: ${DateFormatters.backupDisplay(dt)}', style: Theme.of(context).textTheme.bodySmall))]),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => Text('Error: $e'),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          lastError.when(
            data: (err) {
              if (err == null) return const SizedBox.shrink();
              return Card(
                color: AppColors.unpaidBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.unpaid)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.unpaid),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(err, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.unpaid))),
                      TextButton(onPressed: _doBackupNow, child: const Text('Retry')),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),
          hasQueued.when(
            data: (has) {
              if (!has) return const SizedBox.shrink();
              return Card(
                color: AppColors.partialBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.partial)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_outlined, color: AppColors.partial),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: queueCount.when(
                          data: (c) => Text('May $c naka-queue na backup', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.partial)),
                          loading: () => const Text('May naka-queue'),
                          error: (e, _) => const Text('May naka-queue'),
                        ),
                      ),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.partial, borderRadius: BorderRadius.circular(12)), child: const Text('Queued', style: TextStyle(color: AppColors.textOnPrimary))),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),
          quota.when(
            data: (q) {
              final used = q.usedBytes;
              final total = q.totalBytes;
              final available = q.availableBytes;
              final double pct = total != null && total > 0 ? (used / total).clamp(0, 1).toDouble() : 0;
              return Card(
                color: AppColors.surfaceCard,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.outline)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [const Icon(Icons.storage_rounded, size: 20, color: AppColors.primaryDark), const SizedBox(width: 8), Text('Google Drive storage', style: Theme.of(context).textTheme.titleSmall)]),
                    const SizedBox(height: AppSpacing.sm),
                    LinearProgressIndicator(value: pct, backgroundColor: AppColors.outline, color: pct > 0.8 ? AppColors.unpaid : AppColors.primary),
                    const SizedBox(height: 8),
                    Text(total == null ? '${_formatBytes(used)} used' : '${_formatBytes(used)} / ${_formatBytes(total)} used • ${_formatBytes(available ?? 0)} free', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    isLow.when(
                      data: (low) => low ? Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.unpaid), const SizedBox(width: 6), Expanded(child: Text('Puno na ang storage! Magbura ng lumang backup.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.unpaid))) ])) : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                  ]),
                ),
              );
            },
            loading: () => const Card(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LinearProgressIndicator())),
            error: (e, _) => Card(
              color: AppColors.surfaceCard,
              child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text('Hindi makuha ang storage: ${BackupErrorMapper.toTaglish(e)}', style: Theme.of(context).textTheme.bodySmall)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isBackingUp) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(children: [
                  Row(children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 12), Text('Nagba-backup... ${( _progress * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodyMedium)]),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _progress == 0 ? null : _progress),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppButton(label: _isBackingUp ? 'Nagba-backup...' : 'Backup Now', icon: Icons.cloud_upload_rounded, isLoading: _isBackingUp, onPressed: _isBackingUp ? null : _doBackupNow),
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: 'Browse & Restore', variant: AppButtonVariant.secondary, icon: Icons.folder_open_rounded, onPressed: () => context.push('/settings/backup/browse')),
          const SizedBox(height: AppSpacing.lg),
          Text('Backup history', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          history.when(
            data: (entries) {
              if (entries.isEmpty) {
                return Card(
                  color: AppColors.surfaceCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.outline)),
                  child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Row(children: [const Icon(Icons.history_rounded, color: AppColors.textMuted), const SizedBox(width: 12), Text('Wala pang backup history', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))])),
                );
              }
              return Column(
                children: entries.map((e) {
                  return Card(
                    color: AppColors.surfaceCard,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.outline)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(e.status == BackupStatus.success ? Icons.check_circle_rounded : Icons.error_rounded, color: e.status == BackupStatus.success ? AppColors.paid : AppColors.unpaid),
                      title: Text(e.backupName, style: Theme.of(context).textTheme.bodyMedium),
                      subtitle: Text('${DateFormatters.backupDisplay(e.createdTime)} • ${_formatBytes(e.sizeBytes)} • ${e.source.name} • ${e.status.name}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: AppSpacing.lg),
          ref.watch(backupAuditLogProvider).when(
            data: (logs) {
              if (logs.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audit log', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  ...logs.reversed.take(20).map((l) => Card(
                        color: AppColors.surfaceCard,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.outline)),
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          title: Text('${l.action.name} • ${l.status.name}', style: Theme.of(context).textTheme.bodySmall),
                          subtitle: Text('${DateFormatters.backupDisplay(l.timestamp)} • ${l.backupName}${l.error != null ? " • ${l.error}" : ""}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        ),
                      )),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
