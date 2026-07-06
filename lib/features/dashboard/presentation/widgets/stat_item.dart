import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';

class StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const StatItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: AppFontSizes.x2l),
        const SizedBox(height: AppSpacing.space1),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppFontSizes.x2l,
            fontWeight: AppFontWeights.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.space05),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSizes.sm,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
