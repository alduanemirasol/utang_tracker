import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/app/coordination.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/app_snackbar.dart';
import 'package:utang_tracker/core/widgets/confirmation_dialog.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_history_entry.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_meta.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_status.dart';
import 'package:utang_tracker/features/backup/presentation/providers/backup_providers.dart';
import 'package:utang_tracker/features/backup/utils/backup_error_mapper.dart';

class BackupBrowsePage extends ConsumerStatefulWidget {
  const BackupBrowsePage({super.key});

  @override
  ConsumerState<BackupBrowsePage> createState() => _BackupBrowsePageState();
}

class _BackupBrowsePageState extends ConsumerState<BackupBrowsePage> {
  double _progress = 0;
  String? _activeId;
  bool _isRestoring = false;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _restore(BackupMeta meta) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Restore backup?',
      message: 'This will overwrite your current data. Are you sure? A pre-restore backup will be created before restoring.',
      confirmLabel: 'Restore',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    if (!confirmed) return;
    setState(() {
      _isRestoring = true;
      _activeId = meta.id;
      _progress = 0;
    });
    try {
      final repo = ref.read(backupRepositoryProvider);
      await repo.restoreBackup(meta.id, confirmed: true, onProgress: (progress) {
        if (mounted) setState(() => _progress = progress);
      });
      if (mounted) {
        invalidateBusinessData(ref);
        ref.invalidate(backupHistoryProvider);
        ref.invalidate(backupAuditLogProvider);
        AppSnackBar.success(context, 'Backup restored successfully!');
      }
    } catch (caughtError) {
      final msg = BackupErrorMapper.toTaglish(caughtError);
      if (mounted) AppSnackBar.error(context, msg);
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
          _activeId = null;
          _progress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(backupConnectionDetailsProvider);
    final list = ref.watch(backupListProvider);
    final history = ref.watch(backupHistoryProvider);
    final isSignedIn = connection.value?.status == BackupConnectionStatus.signedIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Backups')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(backupListProvider);
          await ref.read(backupListProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            if (_isRestoring) ...[
              _buildRestoreProgress(),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (isSignedIn)
              _buildDriveBackupsList(list)
            else
              _buildSignedOutPlaceholder(),
            const SizedBox(height: AppSpacing.xl),
            _buildLocalHistorySection(history),
          ],
        ),
      ),
    );
  }

  Widget _buildSignedOutPlaceholder() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.lg,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Mag-sign in muna para makita ang Google Drive backups',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Mag-sign in',
              variant: AppButtonVariant.secondary,
              icon: Icons.login_rounded,
              onPressed: () async {
                final auth = ref.read(googleAuthDatasourceProvider);
                final acc = await auth.signIn();
                ref.invalidate(backupConnectionDetailsProvider);
                if (!mounted) return;
                if (acc != null) {
                  AppSnackBar.success(context, 'Signed in: ${acc.email}');
                } else {
                  AppSnackBar.info(context, 'Sign-in not completed');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreProgress() {
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
              Expanded(
                child: Text(
                  'Restoring... ${(_progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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

  Widget _buildDriveBackupsList(AsyncValue<List<BackupMeta>> list) {
    return list.when(
      data: (metas) {
        if (metas.isEmpty) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 36,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No backups on Drive',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Create your first backup with Backup Now',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Google Drive backups',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...metas.map((backupMeta) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.insert_drive_file_rounded,
                          size: 20,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              backupMeta.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormatters.backupDisplay(backupMeta.createdTime)} • ${_formatBytes(backupMeta.sizeBytes)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _buildRestoreButton(backupMeta),
                    ],
                  ),
                ),
              ),
            )),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LinearProgressIndicator(),
      ),
      error: (error, stackTrace) => AppCard(
        color: AppColors.unpaidBg,
        borderColor: AppColors.unpaid.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not load backups',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.unpaid,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                BackupErrorMapper.toTaglish(error),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Try again',
                variant: AppButtonVariant.secondary,
                onPressed: () => ref.invalidate(backupListProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton(BackupMeta backupMeta) {
    final isActive = _activeId == backupMeta.id && _isRestoring;
    return SizedBox(
      height: AppSpacing.minTapTarget,
      child: OutlinedButton(
        onPressed: _isRestoring ? null : () => _restore(backupMeta),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          side: const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isActive
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Restore',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
      ),
    );
  }

  Widget _buildLocalHistorySection(
    AsyncValue<List<BackupHistoryEntry>> history,
  ) {
    return history.when(
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Local history',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...entries.map((backupEntry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  leading: Icon(
                    backupEntry.status == BackupStatus.success
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: backupEntry.status == BackupStatus.success
                        ? AppColors.paid
                        : AppColors.unpaid,
                    size: 22,
                  ),
                  title: Text(
                    backupEntry.backupName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    '${DateFormatters.backupDisplay(backupEntry.createdTime)} • ${_formatBytes(backupEntry.sizeBytes)}',
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
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
