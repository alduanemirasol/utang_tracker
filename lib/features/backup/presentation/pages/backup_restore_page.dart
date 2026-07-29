import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:utang_tracker/app/coordination.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/confirmation_dialog.dart';
import 'package:utang_tracker/features/backup/domain/backup_models.dart';

class BackupRestorePage extends ConsumerStatefulWidget {
  const BackupRestorePage({super.key});

  @override
  ConsumerState<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends ConsumerState<BackupRestorePage> {
  bool _isExporting = false;
  bool _isRestoring = false;

  bool get _isBusy => _isExporting || _isRestoring;

  Future<void> _createBackup() async {
    setState(() => _isExporting = true);
    File? snapshot;
    try {
      snapshot = await ref
          .read(databaseBackupServiceProvider)
          .createExportSnapshot();
      final saved = await ref
          .read(backupFileGatewayProvider)
          .save(snapshot, p.basename(snapshot.path));
      if (!mounted || !saved) return;
      _showMessage('Backup saved successfully.');
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    } finally {
      if (snapshot != null && await snapshot.exists()) await snapshot.delete();
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _restoreBackup() async {
    final selected = await ref.read(backupFileGatewayProvider).pick();
    if (selected == null || !mounted) return;
    final path = selected.path;

    setState(() => _isRestoring = true);
    PreparedRestore? prepared;
    try {
      prepared = await ref
          .read(databaseBackupServiceProvider)
          .prepareRestore(File(path));
      if (!mounted) return;
      final migrationNote = prepared.wasMigrated
          ? ' Its schema will be upgraded from version ${prepared.originalSchemaVersion} to ${prepared.schemaVersion}.'
          : '';
      final confirmed = await showConfirmationDialog(
        context: context,
        title: 'Replace current data?',
        message:
            'Restoring ${p.basename(path)} will replace all current customers, utang, items, and payments.$migrationNote A rollback backup will be created automatically.',
        confirmLabel: 'Restore backup',
        isDestructive: true,
      );
      if (!confirmed) {
        if (await prepared.file.exists()) await prepared.file.delete();
        return;
      }

      final result = await ref
          .read(databaseBackupServiceProvider)
          .restore(prepared);
      if (!mounted) return;
      refreshAfterDatabaseRestore(ref);
      _showMessage(
        result.wasMigrated
            ? 'Backup restored and migrated successfully.'
            : 'Backup restored successfully.',
      );
    } catch (error) {
      refreshAfterDatabaseRestore(ref);
      if (mounted) _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textOnPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ActionHeader(
                  icon: Icons.cloud_download_outlined,
                  title: 'Create a backup',
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Save backup',
                  icon: Icons.save_alt_rounded,
                  isLoading: _isExporting,
                  onPressed: _isBusy ? null : _createBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ActionHeader(
                  icon: Icons.restore_rounded,
                  title: 'Restore a backup',
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Restore replaces current data. A rollback backup is created first.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Choose backup to restore',
                  icon: Icons.folder_open_rounded,
                  variant: AppButtonVariant.danger,
                  isLoading: _isRestoring,
                  onPressed: _isBusy ? null : _restoreBackup,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionHeader extends StatelessWidget {
  const _ActionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryDark, size: 28),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}
