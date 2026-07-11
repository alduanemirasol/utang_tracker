import 'package:flutter/material.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.secondary
                  ? AppColors.primary
                  : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(onPressed: effectiveOnPressed, child: child);
      case AppButtonVariant.secondary:
        button = OutlinedButton(onPressed: effectiveOnPressed, child: child);
      case AppButtonVariant.danger:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          child: child,
        );
    }

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
