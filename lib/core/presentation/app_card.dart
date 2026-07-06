import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Widget? header;
  final List<Widget>? actions;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.header,
    this.actions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppRadius.sm);

    return Container(
      margin: margin ??
          const EdgeInsets.only(bottom: AppSpacing.space5),
      child: Material(
        type: MaterialType.card,
        elevation: elevation ?? 1,
        borderRadius: effectiveRadius,
        color: backgroundColor ?? AppColors.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.space7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (header case final h?)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.space3),
                    child: h,
                  ),
                ?child,
                if (actions case final acts? when acts.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: AppSpacing.space5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: acts,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
