import 'package:flutter/material.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';

class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.primaryDark,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
      ),
      backgroundColor: AppColors.surfaceCard,
      side: BorderSide(
        color: selected ? AppColors.primaryDark : AppColors.outline,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
