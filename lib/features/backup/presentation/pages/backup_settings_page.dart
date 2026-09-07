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
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/app_snackbar.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_prefs_keys.dart';
import 'package:utang_tracker/features/backup/data/services/backup_queue_service.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_history_entry.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_interval.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_status.dart';
import 'package:utang_tracker/features/backup/domain/entities/storage_quota.dart';
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
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
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
      final isOffline =
          connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty;
      if (isOffline) {
        final queue = BackupQueueService();
        await queue.enqueue('manual');
        ref.invalidate(backupQueueCountProvider);
        ref.invalidate(backupHasQueuedProvider);
        if (mounted) {
          AppSnackBar.info(context, 'No internet connection. Backup queued.');
        }
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
            final delay = [
              const Duration(minutes: 1),
              const Duration(minutes: 5),
              const Duration(minutes: 30),
            ][attempts - 1];
            await Future.delayed(delay);
            continue;
          }
          rethrow;
        }
      }
      if (mounted) AppSnackBar.success(context, 'Backup completed!');
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
      AppSnackBar.info(
        context,
        value == BackupInterval.off
            ? 'Auto backup is off'
            : 'Auto backup: ${value.label}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final interval = ref.watch(backupIntervalProvider);
    final connection = ref.watch(backupConnectionDetailsProvider);
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
          _buildConnectionCard(connection),
          const SizedBox(height: AppSpacing.lg),
          _buildAutoBackupCard(interval, lastBackup, nextBackup),
          const SizedBox(height: AppSpacing.lg),
          _buildLastErrorBanner(lastError),
          _buildQueuedBanner(hasQueued, queueCount),
          const SizedBox(height: AppSpacing.lg),
          _buildStorageCard(quota, isLow),
          const SizedBox(height: AppSpacing.lg),
          if (_isBackingUp) ...[
            _buildBackupProgress(),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppButton(
            label: _isBackingUp ? 'Backing up...' : 'Backup Now',
            icon: Icons.cloud_upload_rounded,
            isLoading: _isBackingUp,
            onPressed: _isBackingUp ? null : _doBackupNow,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Browse & Restore',
            variant: AppButtonVariant.secondary,
            icon: Icons.folder_open_rounded,
            onPressed: () => context.push('/settings/backup/browse'),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildHistorySection(history),
          const SizedBox(height: AppSpacing.xl),
          _buildAuditSection(),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(AsyncValue<BackupConnectionDetails> connection) {
    return connection.when(
      data: (details) {
        final String title;
        final String subtitle;
        final IconData icon;
        final Color color;
        switch (details.status) {
          case BackupConnectionStatus.signedIn:
            title = 'Connected to Google Drive';
            subtitle = details.email ?? 'Signed in';
            icon = Icons.cloud_done_rounded;
            color = AppColors.paid;
          case BackupConnectionStatus.expired:
            title = 'Google sign-in expired';
            subtitle = 'Please sign in again to back up';
            icon = Icons.cloud_off_rounded;
            color = AppColors.partial;
          case BackupConnectionStatus.signedOut:
            title = 'Not connected';
            subtitle = 'Sign in to Google Drive';
            icon = Icons.cloud_off_rounded;
            color = AppColors.unpaid;
        }
        return AppCard(
          borderColor: color.withValues(alpha: 0.3),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  final auth = ref.read(googleAuthDatasourceProvider);
                  if (details.status == BackupConnectionStatus.signedIn) {
                    await auth.signOut();
                    ref.invalidate(backupConnectionDetailsProvider);
                    if (!mounted) return;
                    AppSnackBar.info(context, 'Signed out of Google Drive');
                  } else {
                    final acc = await auth.signIn();
                    ref.invalidate(backupConnectionDetailsProvider);
                    if (!mounted) return;
                    if (acc != null) {
                      AppSnackBar.success(context, 'Signed in: ${acc.email}');
                    } else {
                      AppSnackBar.error(context, 'Sign-in not completed');
                    }
                  }
                },
                child: Text(
                  details.status == BackupConnectionStatus.signedIn
                      ? 'Sign out'
                      : 'Sign in',
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildAutoBackupCard(
    BackupInterval interval,
    AsyncValue<DateTime?> lastBackup,
    AsyncValue<DateTime?> nextBackup,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 20,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Auto backup',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<BackupInterval>(
            initialValue: interval,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 14,
              ),
            ),
            items: BackupInterval.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) _handleIntervalChange(v);
            },
          ),
          if (interval != BackupInterval.off) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            lastBackup.when(
              data: (dt) => _buildInfoRow(
                'Last backup',
                dt == null ? 'No backups yet' : DateFormatters.backupDisplay(dt),
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: AppSpacing.xs),
            nextBackup.when(
              data: (dt) => _buildInfoRow(
                'Next backup',
                dt == null ? '--' : DateFormatters.backupDisplay(dt),
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLastErrorBanner(AsyncValue<String?> lastError) {
    return lastError.when(
      data: (err) {
        if (err == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            color: AppColors.unpaidBg,
            borderColor: AppColors.unpaid.withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.unpaid,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    err,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.unpaid,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _doBackupNow,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildQueuedBanner(
    AsyncValue<bool> hasQueued,
    AsyncValue<int> queueCount,
  ) {
    return hasQueued.when(
      data: (has) {
        if (!has) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            color: AppColors.partialBg,
            borderColor: AppColors.partial.withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(
                  Icons.pending_outlined,
                  color: AppColors.partial,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: queueCount.when(
                    data: (c) => Text(
                      '$c backup(s) queued',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.partial,
                      ),
                    ),
                    loading: () => const Text('Backup queued'),
                    error: (e, _) => const Text('Backup queued'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildStorageCard(
    AsyncValue<StorageQuota> quota,
    AsyncValue<bool> isLow,
  ) {
    return quota.when(
      data: (q) {
        final used = q.usedBytes;
        final total = q.totalBytes;
        final available = q.availableBytes;
        final double pct =
            total != null && total > 0 ? (used / total).clamp(0, 1).toDouble() : 0;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.storage_rounded,
                    size: 20,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Google Drive storage',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: AppColors.outline,
                  color: pct > 0.8 ? AppColors.unpaid : AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                total == null
                    ? '${_formatBytes(used)} used'
                    : '${_formatBytes(used)} / ${_formatBytes(total)} used',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (total != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${_formatBytes(available ?? 0)} available',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              isLow.when(
                data: (low) => low
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: AppColors.unpaid,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Storage is full! Delete old backups to free up space.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.unpaid,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
      loading: () => const AppCard(
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => AppCard(
        child: Text(
          'Could not load storage: ${BackupErrorMapper.toTaglish(e)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildBackupProgress() {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Backing up... ${(_progress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: _progress == 0 ? null : _progress,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(AsyncValue<List<BackupHistoryEntry>> history) {
    return history.when(
      data: (entries) {
        if (entries.isEmpty) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'No backup history yet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup history',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  leading: Icon(
                    e.status == BackupStatus.success
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: e.status == BackupStatus.success
                        ? AppColors.paid
                        : AppColors.unpaid,
                    size: 22,
                  ),
                  title: Text(
                    e.backupName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    '${DateFormatters.backupDisplay(e.createdTime)} • ${_formatBytes(e.sizeBytes)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            )),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildAuditSection() {
    return ref.watch(backupAuditLogProvider).when(
      data: (logs) {
        if (logs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit log',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...logs.reversed.take(20).map((l) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  title: Text(
                    '${l.action.name} • ${l.status.name}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  subtitle: Text(
                    '${DateFormatters.backupDisplay(l.timestamp)}${l.error != null ? " • ${l.error}" : ""}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            )),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
