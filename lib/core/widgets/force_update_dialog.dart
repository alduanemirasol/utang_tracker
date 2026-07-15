import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/update/app_update_checker.dart';
import 'package:utang_tracker/core/update/app_version.dart';
import 'package:utang_tracker/core/update/github_release_service.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';

/// Optional update prompt. Downloads the APK in-app and opens the installer.
Future<void> showUpdateDialog({
  required BuildContext context,
  required AppVersion currentVersion,
  required GithubReleaseUpdate update,
  AppUpdateChecker? checker,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return _UpdateDialog(
        currentVersion: currentVersion,
        update: update,
        // Dialog always disposes the checker when closed.
        checker: checker ?? AppUpdateChecker(),
      );
    },
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({
    required this.currentVersion,
    required this.update,
    required this.checker,
  });

  final AppVersion currentVersion;
  final GithubReleaseUpdate update;
  final AppUpdateChecker checker;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double? _progress;
  String? _error;

  @override
  void dispose() {
    widget.checker.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    try {
      await widget.checker.downloadAndInstall(
        widget.update,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _progress = p);
        },
      );
      if (!mounted) return;

      // The Android installer has opened in its own task. Close this app so the
      // installed version starts from a clean launch after the update.
      await SystemNavigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.update.releaseNotes;
    final shortNotes = notes == null
        ? null
        : (notes.length > 280 ? '${notes.substring(0, 280)}…' : notes);

    return PopScope(
      // Keep the prompt optional, but do not interrupt an active APK download.
      canPop: !_downloading,
      child: AlertDialog(
        title: const Text('Update available'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'A new version is available. Update now?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Current: ${widget.currentVersion}\n'
                'New: ${widget.update.version} (${widget.update.tagName})',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (shortNotes != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  shortNotes,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
              if (_downloading) ...[
                const SizedBox(height: AppSpacing.lg),
                LinearProgressIndicator(
                  value: _progress,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primaryLight,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _progress == null
                      ? 'Downloading…'
                      : 'Downloading… ${(_progress! * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        actions: [
          AppButton(
            label: 'Later',
            variant: AppButtonVariant.secondary,
            expanded: false,
            onPressed: _downloading ? null : () => Navigator.pop(context),
          ),
          AppButton(
            label: _error != null ? 'Retry update' : 'Update now',
            icon: Icons.download_outlined,
            expanded: false,
            onPressed: _downloading ? null : _download,
            isLoading: _downloading,
          ),
        ],
      ),
    );
  }
}
