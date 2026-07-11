import 'package:flutter/material.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';

/// Typed snackbars so success / error states share consistent colors.
enum AppSnackBarKind {
  success,
  error,
  info,
}

class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    AppSnackBarKind kind = AppSnackBarKind.info,
  }) {
    final (background, foreground) = switch (kind) {
      AppSnackBarKind.success => (AppColors.success, Colors.white),
      AppSnackBarKind.error => (AppColors.danger, Colors.white),
      AppSnackBarKind.info => (AppColors.primaryDark, Colors.white),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: background,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  static void success(BuildContext context, String message) {
    show(context, message, kind: AppSnackBarKind.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message, kind: AppSnackBarKind.error);
  }

  static void info(BuildContext context, String message) {
    show(context, message, kind: AppSnackBarKind.info);
  }
}
