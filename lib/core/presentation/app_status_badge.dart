import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';

class AppStatusBadge extends StatelessWidget {
  final DebtStatus status;

  const AppStatusBadge({super.key, required this.status});

  static String labelFor(DebtStatus status) {
    return switch (status) {
      DebtStatus.unpaid => 'Unpaid',
      DebtStatus.partial => 'Partial',
      DebtStatus.paid => 'Paid',
    };
  }

  static Color colorFor(DebtStatus status) {
    return switch (status) {
      DebtStatus.unpaid => AppColors.error,
      DebtStatus.partial => AppColors.warning,
      DebtStatus.paid => AppColors.success,
    };
  }

  /// Text color with better contrast for partial (warning yellow).
  static Color textColorFor(DebtStatus status) {
    return switch (status) {
      DebtStatus.unpaid => AppColors.error,
      DebtStatus.partial => AppColors.textPrimary,
      DebtStatus.paid => AppColors.success,
    };
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = colorFor(status);
    final textColor = textColorFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space5,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        labelFor(status),
        style: AppTheme.textStyle(
          fontSize: AppFontSizes.sm,
          fontWeight: AppFontWeights.semibold,
          color: textColor,
        ),
      ),
    );
  }
}
