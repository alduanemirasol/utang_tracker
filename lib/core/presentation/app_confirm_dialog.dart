import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';

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
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: AppFontSizes.md,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(
              cancelLabel,
              style: const TextStyle(
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
            ),
            child: Text(
              confirmLabel,
              style: const TextStyle(
                fontSize: AppFontSizes.md,
                fontWeight: AppFontWeights.semibold,
              ),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }
}
