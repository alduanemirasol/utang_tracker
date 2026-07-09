import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.chipHeight),
      child: FilterChip(
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.textStyle(
            fontSize: AppFontSizes.md,
            fontWeight: AppFontWeights.semibold,
            height: 1.2,
            color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap?.call(),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        checkmarkColor: AppColors.onPrimary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
        visualDensity: const VisualDensity(horizontal: 0, vertical: 1),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        showCheckmark: false,
      ),
    );
  }
}
