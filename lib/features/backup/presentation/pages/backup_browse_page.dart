import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/app/coordination.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_snackbar.dart';
import 'package:utang_tracker/core/widgets/confirmation_dialog.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_meta.dart';
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
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _restore(BackupMeta meta) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'I-restore ang backup?',
      message: 'Mao-overwrite ang kasalukuyang data. Sigurado ka? Gagawa ng pre-restore backup bago mag-restore.',
      confirmLabel: 'I-restore',
      cancelLabel: 'Kansela',
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
      await repo.restoreBackup(meta.id, confirmed: true, onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (mounted) {
        invalidateBusinessData(ref);
        ref.invalidate(backupHistoryProvider);
        ref.invalidate(backupAuditLogProvider);
        AppSnackBar.success(context, 'Na-restore na ang backup!');
      }
    } catch (e) {
      final msg = BackupErrorMapper.toTaglish(e);
      if (mounted) AppSnackBar.error(context, msg);
    } finally {
      if (mounted) setState(() {_isRestoring = false; _activeId = null; _progress = 0;});
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(backupListProvider);
    final history = ref.watch(backupHistoryProvider);

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
            if (_isRestoring)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(children: [
                    Row(children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 12), Expanded(child: Text('Nagre-restore... ${(_progress * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodyMedium))]),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: _progress == 0 ? null : _progress),
                  ]),
                ),
              ),
            list.when(
              data: (metas) {
                if (metas.isEmpty) {
                  return Card(
                    color: AppColors.surfaceCard,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.outline)),
                    child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(children: [const Icon(Icons.cloud_off_outlined, size: 32, color: AppColors.textMuted), const SizedBox(height: 8), Text('Walang backup sa Drive', style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 4), Text('Gumawa ng unang backup gamit ang Backup Now', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))])),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Google Drive backups', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    ...metas.map((m) => Card(
                          color: AppColors.surfaceCard,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.outline)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [const Icon(Icons.insert_drive_file_rounded, size: 20, color: AppColors.primaryDark), const SizedBox(width: 8), Expanded(child: Text(m.name, style: Theme.of(context).textTheme.bodyMedium)), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.paidBg, borderRadius: BorderRadius.circular(8)), child: Text(m.status.name, style: const TextStyle(color: AppColors.paid)))]),
                              const SizedBox(height: 6),
                              Text('${DateFormatters.backupDisplay(m.createdTime)} • ${_formatBytes(m.sizeBytes)} • ${m.source.name}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 10),
                              AppButton(label: _activeId == m.id && _isRestoring ? 'Nagre-restore...' : 'I-restore', icon: Icons.restore_rounded, isLoading: _activeId == m.id && _isRestoring, onPressed: _isRestoring ? null : () => _restore(m)),
                            ]),
                          ),
                        )),
                  ],
                );
              },
              loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LinearProgressIndicator()),
              error: (e, _) => Card(
                color: AppColors.unpaidBg,
                child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hindi makuha ang backups', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.unpaid)), const SizedBox(height: 6), Text(BackupErrorMapper.toTaglish(e), style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 12), AppButton(label: 'Subukan ulit', variant: AppButtonVariant.secondary, onPressed: () => ref.invalidate(backupListProvider)) ])),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            history.when(
              data: (entries) {
                if (entries.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lokal na history', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    ...entries.map((e) => Card(
                          color: AppColors.surfaceCard,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.outline)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(e.status.name == 'success' ? Icons.history_rounded : Icons.error_outline, color: AppColors.textMuted),
                            title: Text(e.backupName, style: Theme.of(context).textTheme.bodyMedium),
                            subtitle: Text('${DateFormatters.backupDisplay(e.createdTime)} • ${_formatBytes(e.sizeBytes)} • ${e.source.name} • ${e.status.name}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
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
      ),
    );
  }
}
