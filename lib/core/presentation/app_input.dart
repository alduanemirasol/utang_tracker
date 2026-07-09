import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utang_tracker/core/constants/app_border_widths.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/utils/text_input_formatters.dart';

class AppInput extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final bool isRequired;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? helperText;
  final bool enabled;

  const AppInput({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.isRequired = false,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.helperText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSizes.md,
                fontWeight: AppFontWeights.semibold,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: AppFontSizes.md,
                  fontWeight: AppFontWeights.semibold,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(
            fontSize: AppFontSizes.md,
            fontWeight: AppFontWeights.medium,
            color: AppColors.textPrimary,
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: [...?inputFormatters, NoEmojiInputFormatter()],
          validator: (value) {
            if (validator != null) {
              final result = validator!(value);
              if (result != null) return result;
            }
            if (value != null &&
                RegExp(r'[<>{}\[\]\\^`~|]').hasMatch(value)) {
              return 'Contains invalid characters';
            }
            return null;
          },
          onChanged: onChanged,
          decoration: AppInputDecoration.textField(
            hintText: hintText,
            helperText: helperText,
          ),
        ),
      ],
    );
  }
}

class AppInputDecoration {
  AppInputDecoration._();

  static InputDecoration textField({
    String? hintText,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      helperText: helperText,
      helperStyle: const TextStyle(
        fontSize: AppFontSizes.sm,
        color: AppColors.textSecondary,
      ),
      hintStyle: const TextStyle(
        fontSize: AppFontSizes.md,
        fontWeight: AppFontWeights.regular,
        color: AppColors.textSecondary,
      ),
      filled: true,
      fillColor: AppColors.surface,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space7,
        vertical: AppSpacing.space5,
      ),
    );
  }
}
