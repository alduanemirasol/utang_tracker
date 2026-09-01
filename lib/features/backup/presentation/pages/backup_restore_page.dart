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
import 'package:utang_tracker/features/backup/domain/exceptions/drive_exception.dart';
import 'package:utang_tracker/features/backup/presentation/providers/drive_backup_providers.dart';
import 'package:utang_tracker/features/backup/presentation/widgets/drive_file_picker_sheet.dart';

class BackupRestorePage extends ConsumerStatefulWidget {
  const BackupRestorePage({super.key});

  @override
  ConsumerState<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends ConsumerState<BackupRestorePage> {
  bool _isDriveExporting = false;
  bool _isDriveImporting = false;
  bool _isSigningIn = false;

  bool get _isAnyBusy =>
      _isDriveExporting || _isDriveImporting || _isSigningIn;

  Future<void> _signInWithGoogle() async {
    setState(() => _isSigningIn = true);
    try {
      final account =
          await ref.read(googleAuthDataSourceProvider).signIn();
      if (!mounted) return;
      if (account == null) return;
      _showMessage('Signed in as ${account.email}');
      ref.invalidate(authenticatedClientProvider);
      ref.invalidate(driveBackupsProvider);
    } catch (error) {
      final mapped = error is DriveException
          ? error
          : DriveErrorMapper.fromError(error);
      if (mounted) _showMessage(mapped.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSigningIn = true);
    try {
      await ref.read(googleAuthDataSourceProvider).signOut();
      if (!mounted) return;
      _showMessage('Signed out from Google Drive.');
      ref.invalidate(authenticatedClientProvider);
      ref.invalidate(driveBackupsProvider);
    } catch (error) {
      final mapped = error is DriveException
          ? error
          : DriveErrorMapper.fromError(error);
      if (mounted) _showMessage(mapped.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _exportToDrive() async {
    setState(() => _isDriveExporting = true);
    File? snapshot;
    try {
      snapshot = await ref
          .read(databaseBackupServiceProvider)
          .createExportSnapshot();
      final fileName = p.basename(snapshot.path);
      final repo = await ref.read(driveBackupRepositoryProvider.future);
      if (repo == null) {
        throw const DriveException('Not signed in to Google Drive.');
      }
      await repo.uploadBackup(snapshot, fileName);
      if (!mounted) return;
      _showMessage('Backup exported to Drive.');
      ref.invalidate(driveBackupsProvider);
    } catch (error) {
      final mapped = error is DriveException
          ? error
          : DriveErrorMapper.fromError(error);
      if (mounted) _showMessage(mapped.toString(), isError: true);
    } finally {
      if (snapshot != null && await snapshot.exists()) {
        await snapshot.delete();
      }
      if (mounted) setState(() => _isDriveExporting = false);
    }
  }

  Future<void> _importFromDrive() async {
    final selected = await DriveFilePickerSheet.show(context);
    if (selected == null || !mounted) return;

    setState(() => _isDriveImporting = true);
    File? downloaded;
    PreparedRestore? prepared;
    try {
      final repo = await ref.read(driveBackupRepositoryProvider.future);
      if (repo == null) {
        throw const DriveException('Not signed in to Google Drive.');
      }
      downloaded = await repo.downloadBackup(selected);
      prepared = await ref
          .read(databaseBackupServiceProvider)
          .prepareRestore(downloaded);
      if (!mounted) return;
      final migrationNote = prepared.wasMigrated
          ? ' Its schema will be upgraded from version ${prepared.originalSchemaVersion} to ${prepared.schemaVersion}.'
          : '';
      final confirmed = await showConfirmationDialog(
        context: context,
        title: 'Replace current data?',
        message:
            'Restoring ${selected.name} from Drive will replace all current customers, utang, items, and payments.$migrationNote A rollback backup will be created automatically.',
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
            ? 'Drive backup restored and migrated successfully.'
            : 'Drive backup restored successfully.',
      );
    } catch (error) {
      refreshAfterDatabaseRestore(ref);
      final mapped = error is DriveException
          ? error
          : DriveErrorMapper.fromError(error);
      // Preserve BackupException messages as-is for corrupt file cases
      final message = error.toString().contains('BackupException') ||
              error.toString().toLowerCase().contains('backup')
          ? error.toString()
          : mapped.toString();
      if (mounted) _showMessage(message, isError: true);
    } finally {
      if (downloaded != null && await downloaded.exists()) {
        await downloaded.delete();
      }
      if (mounted) setState(() => _isDriveImporting = false);
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
    final authAsync = ref.watch(googleAuthNotifierProvider);
    final authDataSource = ref.watch(googleAuthDataSourceProvider);
    // Fallback to currentUser when stream hasn't emitted yet
    final currentUser = authAsync.value ?? authDataSource.currentUser;
    final isSignedIn = currentUser != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ActionHeader(title: 'Google Drive'),
                const SizedBox(height: AppSpacing.md),
                authAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        error.toString(),
                        style: const TextStyle(color: AppColors.danger),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Sign in with Google',
                        icon: Icons.login,
                        isLoading: _isSigningIn,
                        onPressed: _isAnyBusy ? null : _signInWithGoogle,
                      ),
                    ],
                  ),
                  data: (_) {
                    if (!isSignedIn) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connect Google Drive to back up and restore your data in the cloud.',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: 'Sign in with Google',
                            icon: Icons.login,
                            isLoading: _isSigningIn,
                            onPressed: _isAnyBusy ? null : _signInWithGoogle,
                          ),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: currentUser.photoUrl != null
                                  ? NetworkImage(currentUser.photoUrl!)
                                  : null,
                              child: currentUser.photoUrl == null
                                  ? Builder(
                                      builder: (context) {
                                        final raw =
                                            currentUser.displayName ??
                                                currentUser.email;
                                        final initial = raw.isNotEmpty
                                            ? raw.substring(0, 1).toUpperCase()
                                            : '?';
                                        return Text(
                                          initial,
                                          style: const TextStyle(
                                            color: AppColors.primaryDark,
                                          ),
                                        );
                                      },
                                    )
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentUser.displayName ?? 'Google User',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    currentUser.email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _isAnyBusy ? null : _signOut,
                              child: const Text('Sign out'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: 'Export to Drive',
                          icon: Icons.cloud_upload_outlined,
                          isLoading: _isDriveExporting,
                          onPressed: _isAnyBusy ? null : _exportToDrive,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: 'Import from Drive',
                          icon: Icons.cloud_download_outlined,
                          variant: AppButtonVariant.secondary,
                          isLoading: _isDriveImporting,
                          onPressed: _isAnyBusy ? null : _importFromDrive,
                        ),
                      ],
                    );
                  },
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
  const _ActionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}
