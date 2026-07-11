import 'package:flutter/material.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/update/app_update_checker.dart';
import 'package:utang_tracker/core/update/app_version.dart';
import 'package:utang_tracker/core/update/github_release_service.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';

/// Non-dismissible force-update UI. Downloads APK in-app and opens installer.
Future<void> showForceUpdateDialog({
  required BuildContext context,
  required AppVersion currentVersion,
  required GithubReleaseUpdate update,
  AppUpdateChecker? checker,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return PopScope(
        canPop: false,
        child: _ForceUpdateDialog(
          currentVersion: currentVersion,
          update: update,
          // Dialog always disposes the checker when closed.
          checker: checker ?? AppUpdateChecker(),
        ),
      );
    },
  );
}

class _ForceUpdateDialog extends StatefulWidget {
  const _ForceUpdateDialog({
    required this.currentVersion,
    required this.update,
    required this.checker,
  });

  final AppVersion currentVersion;
  final GithubReleaseUpdate update;
  final AppUpdateChecker checker;

  @override
  State<_ForceUpdateDialog> createState() => _ForceUpdateDialogState();
}

class _ForceUpdateDialogState extends State<_ForceUpdateDialog> {
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
      setState(() {
        _downloading = false;
        _progress = 1;
      });
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

    return AlertDialog(
      title: const Text('Update required'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'A new version of Utang Tracker is available. '
              'Please update to continue.',
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
          label: _error != null ? 'Retry download' : 'Download update',
          icon: Icons.download_outlined,
          onPressed: _downloading ? null : _download,
          isLoading: _downloading,
        ),
      ],
    );
  }
}
