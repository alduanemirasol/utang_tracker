import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';

class AppHeader extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const AppHeader({
    super.key,
    required this.label,
    this.subtitle,
    this.trailing,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasBg = backgroundColor != null;
    final titleColor = hasBg ? AppColors.onPrimary : AppColors.textPrimary;
    final subtitleColor =
        hasBg ? AppColors.onPrimaryLow : AppColors.textSecondary;

    return Container(
      color: backgroundColor,
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFontSizes.x3l,
                    fontWeight: AppFontWeights.bold,
                    color: titleColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: AppFontSizes.md,
                      fontWeight: AppFontWeights.regular,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
