import 'package:flutter/material.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/widgets/app_text_field.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.initialValue,
    required this.items,
    required this.onChanged,
  });

  final String? label;
  final String? hint;
  final String? errorText;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          AppTextField.buildLabel(context, label!),
          const SizedBox(height: AppSpacing.sm),
        ],
        DropdownButtonFormField<T>(
          initialValue: initialValue,
          style: AppTextField.inputStyle(context),
          dropdownColor: AppColors.surfaceCard,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
