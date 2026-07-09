import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';
import 'package:utang_tracker/core/utils/app_responsive.dart';

class AppSectionHeader extends StatelessWidget {
  final String label;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppSectionHeader({
    super.key,
    required this.label,
    this.count,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final title = count != null ? '$label ($count)' : label;
    final compact = AppResponsive.of(context).isCompact;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.textStyle(
              fontSize: AppFontSizes.xl,
              fontWeight: AppFontWeights.semibold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: AppFontSizes.iconSm),
            label: Text(
              actionLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(
                AppSpacing.minTouchTarget,
                AppSpacing.minTouchTarget,
              ),
              // On narrow screens keep label but allow it to shrink.
              visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
              textStyle: AppTheme.textStyle(
                fontSize: AppFontSizes.md,
                fontWeight: AppFontWeights.semibold,
              ),
            ),
          ),
      ],
    );
  }
}
