import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/presentation/app_async_views.dart';
import 'package:utang_tracker/core/presentation/app_button.dart';
import 'package:utang_tracker/core/presentation/app_confirm_dialog.dart';
import 'package:utang_tracker/core/presentation/app_page_body.dart';
import 'package:utang_tracker/core/utils/app_responsive.dart';
import 'package:utang_tracker/core/utils/snackbar_helper.dart';
import 'package:utang_tracker/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:utang_tracker/features/debt_items/presentation/providers/debt_item_providers.dart';
import 'package:utang_tracker/features/debt_items/presentation/widgets/debt_item_fields.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  String _unit = 'pc';
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;

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
        _unit = item.unit;
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
        _invalidateRelated();
        context.showSuccessSnackBar(
          widget.isEditing ? 'Item updated successfully' : 'Item added successfully',
        );
        context.pop();
      case Error(failure: final f):
        context.showErrorSnackBar(f.message);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Item',
      message: 'This will permanently remove this item from the debt.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    final result =
        await ref.read(deleteDebtItemUseCaseProvider).execute(widget.itemId!);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    switch (result) {
      case Success():
        _invalidateRelated();
        context.showSuccessSnackBar('Item deleted');
        context.pop();
      case Error(failure: final f):
        context.showErrorSnackBar(f.message);
    }
  }

  void _invalidateRelated() {
    ref.invalidate(debtDetailProvider(widget.debtId));
    ref.invalidate(debtListProvider);
    ref.invalidate(allDebtsProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(debtItemListProvider(widget.debtId));
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Item' : 'Add Item'),
      ),
      body: _isLoading
          ? const AppLoadingView()
          : SingleChildScrollView(
              padding: AppResponsive.of(context).scrollPadding(),
              child: AppConstrainedWidth(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DebtItemFields(
                        nameController: _nameController,
                        qtyController: _qtyController,
                        priceController: _priceController,
                        unit: _unit,
                        onUnitChanged: (value) => setState(() => _unit = value),
                      ),
                      const SizedBox(height: AppSpacing.space10),
                      AppPrimaryButton(
                        label: widget.isEditing ? 'Save' : 'Add item',
                        onPressed: _save,
                        isLoading: _isSaving,
                      ),
                      if (widget.isEditing) ...[
                        const SizedBox(height: AppSpacing.space5),
                        AppDestructiveButton(
                          label: 'Delete item',
                          onPressed: _isDeleting ? null : _confirmDelete,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
