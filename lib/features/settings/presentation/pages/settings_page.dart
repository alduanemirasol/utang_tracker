import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/database/database_backup.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/update/app_update_checker.dart';
import 'package:utang_tracker/core/utils/invalidate_helpers.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/app_logo.dart';
import 'package:utang_tracker/core/widgets/app_snackbar.dart';
import 'package:utang_tracker/core/widgets/confirmation_dialog.dart';
import 'package:utang_tracker/core/widgets/force_update_dialog.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _exporting = false;
  bool _importing = false;
  bool _checkingUpdate = false;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = info.version);
    } catch (_) {
      // Leave version null; UI falls back to a generic label.
    }
  }

  bool get _busy => _exporting || _importing || _checkingUpdate;

  Future<void> _checkForUpdates() async {
    if (_busy) return;
    setState(() => _checkingUpdate = true);
    final checker = AppUpdateChecker();
    try {
      final result = await checker.checkForUpdate();
      if (!mounted) {
        checker.dispose();
        return;
      }
      if (!result.isUpdateAvailable || result.update == null) {
        checker.dispose();
        AppSnackBar.success(
          context,
          'You are on the latest version (${result.currentVersion}).',
        );
        return;
      }
      await showForceUpdateDialog(
        context: context,
        currentVersion: result.currentVersion,
        update: result.update!,
        checker: checker,
      );
    } on AppException catch (e) {
      checker.dispose();
      if (mounted) AppSnackBar.error(context, e.message);
    } catch (_) {
      checker.dispose();
      if (mounted) {
        AppSnackBar.error(
          context,
          'Could not check for updates. Try again later.',
        );
      }
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _exportDatabase() async {
    if (_busy) return;
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

  /// Resolve a readable local path for the picked backup.
  ///
  /// Android does not map `.sqlite` / `.db` to MIME types, so the picker uses
  /// [FileType.any] there. Some picks only expose bytes (no filesystem path).
  Future<String> _resolveImportPath(PlatformFile file) async {
    final displayName = file.name;
    if (displayName.isNotEmpty &&
        !DatabaseBackup.hasAllowedExtension(displayName)) {
      throw const AppException(
        'Only .sqlite or .db backup files can be imported.',
      );
    }

    final path = file.path;
    if (path != null && path.isNotEmpty) {
      if (!DatabaseBackup.hasAllowedExtension(path)) {
        throw const AppException(
          'Only .sqlite or .db backup files can be imported.',
        );
      }
      return path;
    }

    final bytes = file.bytes ?? await file.xFile.readAsBytes();
    if (bytes.isEmpty) {
      throw const AppException('Selected file is empty or unreadable.');
    }

    final tempDir = await getTemporaryDirectory();
    final name = displayName.isNotEmpty ? displayName : 'import_backup.sqlite';
    if (!DatabaseBackup.hasAllowedExtension(name)) {
      throw const AppException(
        'Only .sqlite or .db backup files can be imported.',
      );
    }
    final dest = File(p.join(tempDir.path, 'utang_import_$name'));
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  }

  Future<void> _importDatabase() async {
    if (_busy) return;

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Import database?',
      message:
          'This replaces all current data on this device with the selected backup. This cannot be undone.\n\nOnly .sqlite or .db files are accepted.',
      confirmLabel: 'Import',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    // Android: FileType.custom + sqlite/db fails (unknown MIME types).
    // Desktop: extension filter works and improves UX.
    final useExtensionFilter = !Platform.isAndroid;
    final result = await FilePicker.platform.pickFiles(
      type: useExtensionFilter ? FileType.custom : FileType.any,
      allowedExtensions: useExtensionFilter ? const ['sqlite', 'db'] : null,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _importing = true);
    try {
      final importPath = await _resolveImportPath(result.files.single);

      final db = ref.read(databaseProvider);
      final livePath = await DatabaseBackup.resolveDatabasePath(db);
      await db.close();

      await DatabaseBackup.replaceDatabaseFile(
        livePath: livePath,
        importPath: importPath,
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
                Text(
                  _appVersion == null ? 'Version' : 'Version $_appVersion',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Check for updates',
                  icon: Icons.system_update_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: _busy ? null : _checkForUpdates,
                  isLoading: _checkingUpdate,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Export a full backup of customers, debts, and payments, or import a previous .sqlite backup to restore this device.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Export database',
                  icon: Icons.upload_file_outlined,
                  onPressed: _busy ? null : _exportDatabase,
                  isLoading: _exporting,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Import database',
                  icon: Icons.download_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: _busy ? null : _importDatabase,
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
