import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/presentation/app_dropdown_field.dart';
import 'package:utang_tracker/core/presentation/app_input.dart';

/// Shared product line-item fields for create sheet and item form.
class DebtItemFields extends StatelessWidget {
  static const units = ['pc', 'kg', 'g', 'L', 'ml', 'pack', 'box', 'set'];

  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  final String unit;
  final ValueChanged<String> onUnitChanged;

  const DebtItemFields({
    super.key,
    required this.nameController,
    required this.qtyController,
    required this.priceController,
    required this.unit,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final unitItems = {
      ...units,
      if (!units.contains(unit) && unit.isNotEmpty) unit,
    }.toList();
    final selectedUnit =
        unitItems.contains(unit) ? unit : unitItems.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput(
          label: 'Product Name',
          controller: nameController,
          hintText: 'Enter product name',
          isRequired: true,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: AppSpacing.space7),
        AppInput(
          label: 'Quantity',
          controller: qtyController,
          hintText: '0',
          isRequired: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            final n = double.tryParse(v.trim());
            if (n == null || n <= 0) return 'Must be greater than 0';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.space7),
        AppDropdownField<String>(
          label: 'Unit',
          value: selectedUnit,
          isRequired: true,
          items: unitItems
              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
              .toList(),
          onChanged: (value) {
            if (value != null) onUnitChanged(value);
          },
        ),
        const SizedBox(height: AppSpacing.space7),
        AppInput(
          label: 'Unit Price',
          controller: priceController,
          hintText: '0.00',
          isRequired: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            final n = double.tryParse(v.trim());
            if (n == null || n < 0) return 'Invalid price';
            return null;
          },
        ),
      ],
    );
  }
}
