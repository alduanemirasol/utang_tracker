import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';

class AppDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool isRequired;
  final String placeholder;

  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
    this.isRequired = false,
    this.placeholder = 'Select date',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSpacing.space56),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space7,
                vertical: AppSpacing.space5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: AppFontSizes.iconSm,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.space5),
                  Expanded(
                    child: Text(
                      value != null
                          ? DateTimeHelper.formatDate(value!)
                          : placeholder,
                      style: TextStyle(
                        fontSize: AppFontSizes.md,
                        fontWeight: AppFontWeights.medium,
                        color: value != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (onClear != null)
                    IconButton(
                      tooltip: 'Clear date',
                      onPressed: onClear,
                      icon: const Icon(
                        Icons.close,
                        size: AppFontSizes.iconSm,
                        color: AppColors.textSecondary,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: AppSpacing.space48,
                        minHeight: AppSpacing.space48,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
