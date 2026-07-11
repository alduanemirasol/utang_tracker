import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/database/database_backup.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/invalidate_helpers.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/app_logo.dart';
import 'package:utang_tracker/core/widgets/app_snackbar.dart';
import 'package:utang_tracker/core/widgets/confirmation_dialog.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _exporting = false;
  bool _importing = false;

  Future<void> _exportDatabase() async {
    if (_exporting || _importing) return;
    setState(() => _exporting = true);
    try {
      final db = ref.read(databaseProvider);
      await DatabaseBackup.exportAndShare(db);
      if (!mounted) return;
      AppSnackBar.success(context, 'Backup ready to share or save.');
    } on AppException catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importDatabase() async {
    if (_exporting || _importing) return;

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Import database?',
      message:
          'This replaces all current data on this device with the selected backup. This cannot be undone.',
      confirmLabel: 'Import',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['sqlite', 'db'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not read the selected file path.');
      return;
    }

    setState(() => _importing = true);
    try {
      final db = ref.read(databaseProvider);
      final livePath = await DatabaseBackup.resolveDatabasePath(db);
      await db.close();

      await DatabaseBackup.replaceDatabaseFile(
        livePath: livePath,
        importPath: path,
      );

      // Re-open DB and refresh all screens.
      ref.invalidate(databaseProvider);
      invalidateBusinessData(ref);

      if (!mounted) return;
      AppSnackBar.success(context, 'Database imported successfully.');
    } on AppException catch (e) {
      // Ensure a live connection even if import failed after close.
      ref.invalidate(databaseProvider);
      if (!mounted) return;
      AppSnackBar.error(context, e.message);
    } catch (e) {
      ref.invalidate(databaseProvider);
      if (!mounted) return;
      AppSnackBar.error(context, 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppLogo(size: 56, borderRadius: 12),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'Built to help Perly Store track customer utang, payments, and balances on this device.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Export a full backup of customers, debts, and payments, or import a previous backup to restore this device.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Export database',
                  icon: Icons.upload_file_outlined,
                  onPressed: _exporting || _importing ? null : _exportDatabase,
                  isLoading: _exporting,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Import database',
                  icon: Icons.download_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: _exporting || _importing ? null : _importDatabase,
                  isLoading: _importing,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to use',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                _tip('1. Add customers from the Customers tab.'),
                _tip('2. Record utang under Debts with item lines.'),
                _tip('3. Log payments when customers pay.'),
                _tip('4. Check the Dashboard for store balances.'),
                _tip('5. Export a backup from Settings regularly.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text),
    );
  }
}
