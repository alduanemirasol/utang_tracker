import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/presentation/app_async_views.dart';
import 'package:utang_tracker/core/presentation/app_button.dart';
import 'package:utang_tracker/core/presentation/app_dropdown_field.dart';
import 'package:utang_tracker/core/presentation/app_input.dart';
import 'package:utang_tracker/core/utils/snackbar_helper.dart';
import 'package:utang_tracker/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:utang_tracker/features/debt_items/presentation/providers/debt_item_providers.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';

class DebtItemFormScreen extends ConsumerStatefulWidget {
  final String debtId;
  final String? itemId;

  const DebtItemFormScreen({super.key, required this.debtId, this.itemId});

  bool get isEditing => itemId != null;

  @override
  ConsumerState<DebtItemFormScreen> createState() => _DebtItemFormScreenState();
}

class _DebtItemFormScreenState extends ConsumerState<DebtItemFormScreen> {
  static const _units = ['pc', 'kg', 'g', 'L', 'ml', 'pack', 'box', 'set'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  String _unit = 'pc';
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result =
        await ref.read(getDebtItemUseCaseProvider).execute(widget.itemId!);
    switch (result) {
      case Success(data: final item):
        _nameController.text = item.productName;
        _qtyController.text = item.quantity == item.quantity.roundToDouble()
            ? item.quantity.toInt().toString()
            : item.quantity.toString();
        _priceController.text = item.unitPrice == item.unitPrice.roundToDouble()
            ? item.unitPrice.toInt().toString()
            : item.unitPrice.toStringAsFixed(2);
        _unit = _units.contains(item.unit) ? item.unit : item.unit;
        if (!_units.contains(_unit)) {
          // Keep custom unit as selected value by using free text in unit list
        }
      case Error():
        if (mounted) {
          context.showErrorSnackBar('Failed to load item');
          context.pop();
        }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.tryParse(_qtyController.text.trim());
    final unitPrice = double.tryParse(_priceController.text.trim());
    if (quantity == null || unitPrice == null) {
      context.showErrorSnackBar('Enter valid numbers');
      return;
    }

    setState(() => _isSaving = true);

    final Result result;
    if (widget.isEditing) {
      result = await ref.read(updateDebtItemUseCaseProvider).execute(
            id: widget.itemId!,
            productName: _nameController.text,
            quantity: quantity,
            unit: _unit,
            unitPrice: unitPrice,
          );
    } else {
      result = await ref.read(createDebtItemUseCaseProvider).execute(
            debtId: widget.debtId,
            productName: _nameController.text,
            quantity: quantity,
            unit: _unit,
            unitPrice: unitPrice,
          );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    switch (result) {
      case Success():
        ref.invalidate(debtDetailProvider(widget.debtId));
        ref.invalidate(debtListProvider);
        ref.invalidate(allDebtsProvider);
        ref.invalidate(dashboardProvider);
        ref.invalidate(debtItemListProvider(widget.debtId));
        context.showSuccessSnackBar(
          widget.isEditing ? 'Item updated successfully' : 'Item added successfully',
        );
        context.pop();
      case Error(failure: final f):
        context.showErrorSnackBar(f.message);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitItems = {
      ..._units,
      if (!_units.contains(_unit) && _unit.isNotEmpty) _unit,
    }.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Item' : 'Add Item'),
      ),
      body: _isLoading
          ? const AppLoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space7),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppInput(
                      label: 'Product Name',
                      controller: _nameController,
                      hintText: 'Enter product name',
                      isRequired: true,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.space7),
                    AppInput(
                      label: 'Quantity',
                      controller: _qtyController,
                      hintText: '0',
                      isRequired: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                      value: unitItems.contains(_unit) ? _unit : unitItems.first,
                      isRequired: true,
                      items: unitItems
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _unit = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.space7),
                    AppInput(
                      label: 'Unit Price',
                      controller: _priceController,
                      hintText: '0.00',
                      isRequired: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = double.tryParse(v.trim());
                        if (n == null || n < 0) return 'Invalid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.space10),
                    AppPrimaryButton(
                      label: widget.isEditing ? 'Update item' : 'Add item',
                      onPressed: _save,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
