import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';
import 'package:utang_tracker/core/utils/app_responsive.dart';

class AppConfirmDialog {
  AppConfirmDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final maxWidth = AppResponsive.of(ctx).isCompact
            ? double.infinity
            : AppSpacing.contentMaxWidth * 0.6;

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: AppResponsive.of(ctx).horizontalPadding,
            vertical: AppSpacing.space8,
          ),
          title: Text(
            title,
            style: AppTheme.textStyle(
              fontSize: AppFontSizes.x2l,
              fontWeight: AppFontWeights.semibold,
              color: AppColors.textPrimary,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Text(
                message,
                style: AppTheme.textStyle(
                  fontSize: AppFontSizes.md,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsOverflowButtonSpacing: AppSpacing.space3,
          actions: [
            TextButton(
              onPressed: () => ctx.pop(false),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  AppSpacing.minTouchTarget,
                  AppSpacing.minTouchTarget,
                ),
              ),
              child: Text(
                cancelLabel,
                style: AppTheme.textStyle(
                  fontSize: AppFontSizes.md,
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => ctx.pop(true),
              style: TextButton.styleFrom(
                foregroundColor:
                    isDestructive ? AppColors.error : AppColors.primary,
                minimumSize: const Size(
                  AppSpacing.minTouchTarget,
                  AppSpacing.minTouchTarget,
                ),
              ),
              child: Text(
                confirmLabel,
                style: AppTheme.textStyle(
                  fontSize: AppFontSizes.md,
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
            ),
          ],
        );
      },
    );
    return result == true;
  }
}
