import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/presentation/app_button.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppFontSizes.iconL,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.space7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppFontSizes.xl,
                fontWeight: AppFontWeights.semibold,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppFontSizes.md,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.space8),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.emptyActionMaxWidth,
                ),
                child: AppPrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
