import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';

/// Icon + label row used on detail cards.
class AppInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final CrossAxisAlignment crossAxisAlignment;

  const AppInfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Icon(icon, size: AppFontSizes.iconSm, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.space5),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSizes.md,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
