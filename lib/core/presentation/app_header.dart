import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';

class AppHeader extends StatelessWidget {
  final String label;
  final Widget? center;
  final IconData? rightIcon;
  final VoidCallback? onRightTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const AppHeader({
    super.key,
    required this.label,
    this.center,
    this.rightIcon,
    this.onRightTap,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasBg = backgroundColor != null;

    return Container(
      color: backgroundColor,
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSizes.x3l,
              fontWeight: AppFontWeights.bold,
              color: hasBg ? AppColors.onPrimary : AppColors.textPrimary,
            ),
          ),
          ?center,
          if (rightIcon != null)
            IconButton(
              icon: Icon(rightIcon,
                  color: hasBg ? AppColors.onPrimary : null),
              onPressed: onRightTap,
            ),
        ],
      ),
    );
  }
}
