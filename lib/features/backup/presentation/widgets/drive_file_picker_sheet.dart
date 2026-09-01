import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/features/backup/domain/entities/drive_backup_file.dart';
import 'package:utang_tracker/features/backup/presentation/providers/drive_backup_providers.dart';

class DriveFilePickerSheet extends ConsumerWidget {
  const DriveFilePickerSheet({super.key});

  static Future<DriveBackupFile?> show(BuildContext context) {
    return showModalBottomSheet<DriveBackupFile>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const DriveFilePickerSheet(),
    );
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormatters.smartTimestamp(
      date,
      relativeTo: DateTime.now(),
      locale: 'en_US',
      use24HourFormat: false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(driveBackupsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Choose Drive backup',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: backupsAsync.when(
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 40,
                          color: AppColors.danger,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: 'Retry',
                          expanded: false,
                          onPressed: () =>
                              ref.invalidate(driveBackupsProvider),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (files) {
                  if (files.isEmpty) {
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_outlined,
                              size: 40,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'No Drive backups found',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Upload a backup to Drive first.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppButton(
                              label: 'Retry',
                              expanded: false,
                              onPressed: () =>
                                  ref.invalidate(driveBackupsProvider),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: files.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final subtitleParts = <String>[];
                        final dateStr = _formatDate(
                          file.modifiedTime ?? file.createdTime,
                        );
                        if (dateStr.isNotEmpty) subtitleParts.add(dateStr);
                        final sizeStr = _formatBytes(file.sizeBytes);
                        if (sizeStr.isNotEmpty) subtitleParts.add(sizeStr);
                        return ListTile(
                          leading: const Icon(
                            Icons.insert_drive_file_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: subtitleParts.isEmpty
                              ? null
                              : Text(subtitleParts.join(' • ')),
                          trailing: const Icon(Icons.download_outlined),
                          onTap: () => Navigator.of(context).pop(file),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
