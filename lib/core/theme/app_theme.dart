import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_border_widths.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Poppins';

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      error: AppColors.error,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme(AppColors.textPrimary, AppColors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: AppFontSizes.x2l,
          fontWeight: AppFontWeights.semibold,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppFontSizes.iconMd,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.onPrimary,
          minimumSize: const Size(double.infinity, AppSpacing.space56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space7,
            vertical: AppSpacing.space5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: AppFontSizes.lg,
            fontWeight: AppFontWeights.semibold,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, AppSpacing.space56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space7,
            vertical: AppSpacing.space5,
          ),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: AppFontSizes.lg,
            fontWeight: AppFontWeights.semibold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(AppSpacing.space48, AppSpacing.space48),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: AppFontSizes.md,
            fontWeight: AppFontWeights.semibold,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        extendedTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: AppFontSizes.md,
          fontWeight: AppFontWeights.semibold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: AppFontSizes.sm,
          fontWeight: AppFontWeights.semibold,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: AppFontSizes.sm,
          fontWeight: AppFontWeights.medium,
        ),
        showUnselectedLabels: true,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: AppFontSizes.md,
          fontWeight: AppFontWeights.regular,
          color: AppColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space7,
          vertical: AppSpacing.space5,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: AppBorderWidths.thick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: AppFontSizes.md,
          fontWeight: AppFontWeights.medium,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: AppFontSizes.x2l,
          fontWeight: AppFontWeights.semibold,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: AppFontSizes.md,
          fontWeight: AppFontWeights.regular,
          color: AppColors.textPrimary,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        modalBackgroundColor: AppColors.surface,
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surface),
          surfaceTintColor: WidgetStatePropertyAll(AppColors.transparent),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: AppBorderWidths.regular,
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.darkOnPrimary,
      error: AppColors.error,
      surface: AppColors.darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _textTheme(
        AppColors.darkTextPrimary,
        AppColors.darkTextSecondary,
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: AppFontSizes.display,
        fontWeight: AppFontWeights.bold,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: AppFontSizes.x3l,
        fontWeight: AppFontWeights.bold,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: AppFontSizes.x2l,
        fontWeight: AppFontWeights.semibold,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: AppFontSizes.xl,
        fontWeight: AppFontWeights.semibold,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: AppFontSizes.lg,
        fontWeight: AppFontWeights.semibold,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: AppFontSizes.md,
        fontWeight: AppFontWeights.regular,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: AppFontSizes.sm,
        fontWeight: AppFontWeights.regular,
        color: primary,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: AppFontSizes.xs,
        fontWeight: AppFontWeights.regular,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: AppFontSizes.md,
        fontWeight: AppFontWeights.semibold,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: AppFontSizes.sm,
        fontWeight: AppFontWeights.medium,
        color: secondary,
      ),
    );
  }
}
