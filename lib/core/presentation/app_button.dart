import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: AppSpacing.space8,
            height: AppSpacing.space8,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.onPrimary,
            ),
          )
        : _ButtonLabel(label: label, icon: icon);

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: Size(
          fullWidth ? double.infinity : 0,
          AppSpacing.space56,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: const TextStyle(
          fontSize: AppFontSizes.lg,
          fontWeight: AppFontWeights.semibold,
        ),
      ),
      child: child,
    );

    return fullWidth ? button : button;
  }
}

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final Color? foregroundColor;
  final Color? borderColor;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.foregroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? AppColors.primary;
    final child = isLoading
        ? SizedBox(
            width: AppSpacing.space8,
            height: AppSpacing.space8,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color,
            ),
          )
        : _ButtonLabel(label: label, icon: icon, color: color);

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: Size(
          fullWidth ? double.infinity : 0,
          AppSpacing.space56,
        ),
        side: BorderSide(color: borderColor ?? color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: const TextStyle(
          fontSize: AppFontSizes.lg,
          fontWeight: AppFontWeights.semibold,
        ),
      ),
      child: child,
    );
  }
}

class AppDestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;

  const AppDestructiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        minimumSize: Size(
          fullWidth ? double.infinity : 0,
          AppSpacing.space56,
        ),
        side: const BorderSide(color: AppColors.error),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: const TextStyle(
          fontSize: AppFontSizes.lg,
          fontWeight: AppFontWeights.semibold,
        ),
      ),
      child: Text(label),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const _ButtonLabel({
    required this.label,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Text(label, style: color != null ? TextStyle(color: color) : null);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppFontSizes.iconSm, color: color),
        const SizedBox(width: AppSpacing.space3),
        Text(label, style: color != null ? TextStyle(color: color) : null),
      ],
    );
  }
}
