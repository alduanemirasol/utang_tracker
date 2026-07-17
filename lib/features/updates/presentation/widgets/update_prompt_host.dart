import 'dart:io';

import 'package:flutter/material.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_snackbar.dart';
import 'package:utang_tracker/features/updates/data/app_update_service.dart';
import 'package:utang_tracker/features/updates/domain/entities/app_update.dart';

class UpdatePromptHost extends StatefulWidget {
  const UpdatePromptHost({super.key, required this.child});

  final Widget child;

  @override
  State<UpdatePromptHost> createState() => _UpdatePromptHostState();
}

class _UpdatePromptHostState extends State<UpdatePromptHost> {
  final AppUpdateService _service = AppUpdateService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    try {
      final update = await _service.checkForUpdate();
      if (update == null || !mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: !update.isRequired,
        enableDrag: !update.isRequired,
        useSafeArea: true,
        builder: (_) => _UpdateSheet(update: update, service: _service),
      );
    } catch (_) {
      // Startup update checks stay quiet when the device is offline.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _UpdateSheet extends StatefulWidget {
  const _UpdateSheet({required this.update, required this.service});

  final AppUpdate update;
  final AppUpdateService service;

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  File? _apk;
  double _progress = 0;
  bool _isWorking = false;

  Future<void> _startUpdate() async {
    setState(() => _isWorking = true);
    try {
      final apk =
          _apk ??
          await widget.service.download(
            widget.update,
            onProgress: (progress) {
              if (mounted) setState(() => _progress = progress);
            },
          );
      _apk = apk;
      final result = await widget.service.install(apk);
      if (!mounted) return;
      if (result == InstallResult.permissionRequired) {
        AppSnackBar.info(context, 'Allow installs, then tap Update again.');
      }
      setState(() => _isWorking = false);
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        error is UpdateException ? error.message : 'Update failed. Try again.',
      );
      setState(() {
        _isWorking = false;
        _progress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.system_update_alt_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Update available',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Version ${widget.update.versionName} is ready.'),
          if (widget.update.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.update.releaseNotes,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          if (_isWorking) ...[
            const SizedBox(height: AppSpacing.lg),
            LinearProgressIndicator(value: _progress == 0 ? null : _progress),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _progress == 0
                  ? 'Starting download...'
                  : 'Downloading ${(_progress * 100).round()}%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              if (!widget.update.isRequired) ...[
                Expanded(
                  child: AppButton(
                    label: 'Later',
                    variant: AppButtonVariant.secondary,
                    onPressed: _isWorking ? null : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: AppButton(
                  label: _apk == null ? 'Update' : 'Install',
                  icon: Icons.download_rounded,
                  isLoading: _isWorking,
                  onPressed: _startUpdate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
