import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/core/presentation/app_input.dart';
import 'package:utang_tracker/core/utils/number_formatter.dart';
import 'package:utang_tracker/core/utils/snackbar_helper.dart';
import 'package:utang_tracker/features/customers/domain/customer.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/debt_items/presentation/providers/debt_item_providers.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';

class _TempItemData {
  final String id;
  final String productName;
  final double quantity;
  final String unit;
  final double unitPrice;

  _TempItemData({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  double get subtotal => quantity * unitPrice;
}

class DebtFormScreen extends ConsumerStatefulWidget {
  final String? debtId;
  final String? customerId;

  const DebtFormScreen({super.key, this.debtId, this.customerId});

  bool get isEditing => debtId != null;

  @override
  ConsumerState<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends ConsumerState<DebtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Customer? _selectedCustomer;
  DateTime _transactionDate = DateTimeHelper.now();
  DateTime? _dueDate;
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isInitialized = false;
  final List<_TempItemData> _items = [];
  int _itemIdCounter = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadDebt();
    }
  }

  Future<void> _loadDebt() async {
    setState(() => _isLoading = true);
    final result =
        await ref.read(getDebtUseCaseProvider).execute(widget.debtId!);
    switch (result) {
      case Success(data: final debt):
        if (mounted) {
          ref.read(customerListProvider.notifier).refresh();
        }
        _transactionDate = debt.transactionDate;
        _dueDate = debt.dueDate;
        _notesController.text = debt.notes ?? '';
        _selectedCustomer = Customer(
          id: debt.customerId,
          name: '',
          createdAt: DateTimeHelper.now(),
          updatedAt: DateTimeHelper.now(),
        );
      case Error():
        if (mounted) {
          context.showErrorSnackBar('Failed to load debt');
          context.pop();
        }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickDate(bool isDueDate) async {
    final now = DateTimeHelper.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isDueDate
          ? (_dueDate ?? now.add(const Duration(days: 30)))
          : _transactionDate,
      firstDate: isDueDate ? now : DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _transactionDate = picked;
        }
      });
    }
  }

  void _removeItem(String id) {
    setState(() => _items.removeWhere((i) => i.id == id));
  }

  Future<void> _showAddItemSheet() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'pc');
    final priceCtrl = TextEditingController();
    final sheetFormKey = GlobalKey<FormState>();

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sm)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.space7,
            right: AppSpacing.space7,
            top: AppSpacing.space7,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.space7,
          ),
          child: Form(
            key: sheetFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.space5),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Add Item',
                  style: TextStyle(
                    fontSize: AppFontSizes.x2l,
                    fontWeight: AppFontWeights.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                AppInput(
                  label: 'Product Name',
                  controller: nameCtrl,
                  hintText: 'Enter product name',
                  isRequired: true,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.space7),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppInput(
                        label: 'Quantity',
                        controller: qtyCtrl,
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        isRequired: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final n = double.tryParse(v);
                          if (n == null || n <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space5),
                    Expanded(
                      flex: 1,
                      child: AppInput(
                        label: 'Unit',
                        controller: unitCtrl,
                        hintText: 'pc',
                        isRequired: true,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space7),
                AppInput(
                  label: 'Unit Price',
                  controller: priceCtrl,
                  hintText: '0.00',
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = double.tryParse(v);
                    if (n == null || n < 0) return 'Invalid price';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.space6,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space5),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (!sheetFormKey.currentState!.validate()) return;
                          context.pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.space6,
                          ),
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (added == true && mounted) {
      setState(() {
        _itemIdCounter++;
        _items.add(_TempItemData(
          id: 'temp_$_itemIdCounter',
          productName: nameCtrl.text.trim(),
          quantity: double.parse(qtyCtrl.text.trim()),
          unit: unitCtrl.text.trim(),
          unitPrice: double.parse(priceCtrl.text.trim()),
        ));
      });
    }

    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    priceCtrl.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      context.showErrorSnackBar('Please select a customer');
      return;
    }

    setState(() => _isSaving = true);

    if (widget.isEditing) {
      final result = await ref.read(updateDebtUseCaseProvider).execute(
            id: widget.debtId!,
            transactionDate: _transactionDate,
            dueDate: _dueDate,
            notes: _notesController.text.isEmpty
                ? null
                : _notesController.text,
            clearDueDate: _dueDate == null && widget.isEditing,
            clearNotes: _notesController.text.isEmpty && widget.isEditing,
          );

      if (mounted) {
        setState(() => _isSaving = false);
        switch (result) {
          case Success():
            ref.invalidate(debtListProvider);
            context.showSuccessSnackBar('Debt updated successfully');
            context.pop();
          case Error(failure: final f):
            context.showErrorSnackBar(f.message);
        }
      }
    } else {
      final result = await ref.read(createDebtUseCaseProvider).execute(
            customerId: _selectedCustomer!.id,
            transactionDate: _transactionDate,
            dueDate: _dueDate,
            notes: _notesController.text.isEmpty
                ? null
                : _notesController.text,
          );

      if (!mounted) return;

      switch (result) {
        case Success(data: final createdDebt):
          for (final item in _items) {
            final itemResult =
                await ref.read(createDebtItemUseCaseProvider).execute(
                      debtId: createdDebt.id,
                      productName: item.productName,
                      quantity: item.quantity,
                      unit: item.unit,
                      unitPrice: item.unitPrice,
                    );
            if (itemResult case Error(failure: final f)) {
              if (mounted) {
                setState(() => _isSaving = false);
                context.showErrorSnackBar(
                    'Failed to create item: ${f.message}');
              }
              return;
            }
          }
          if (mounted) {
            setState(() => _isSaving = false);
            ref.invalidate(debtListProvider);
            context.showSuccessSnackBar('Debt created successfully');
            context.pushReplacementNamed(
              'debtDetail',
              pathParameters: {'id': createdDebt.id},
            );
          }
        case Error(failure: final f):
          if (mounted) {
            setState(() => _isSaving = false);
            context.showErrorSnackBar(f.message);
          }
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCustomers = ref.watch(customerListProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Edit Debt')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          AppBar(title: Text(widget.isEditing ? 'Edit Debt' : 'New Debt')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space7),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.isEditing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerSelector(asyncCustomers),
                    const SizedBox(height: AppSpacing.space7),
                  ],
                ),
              _DatePickerField(
                label: 'Transaction Date',
                value: _transactionDate,
                isDueDate: false,
                onTap: () => _pickDate(false),
              ),
              const SizedBox(height: AppSpacing.space7),
              _DatePickerField(
                label: 'Due Date (optional)',
                value: _dueDate,
                isDueDate: true,
                onTap: () => _pickDate(true),
                onClear: _dueDate != null
                    ? () => setState(() => _dueDate = null)
                    : null,
              ),
              const SizedBox(height: AppSpacing.space7),
              AppInput(
                label: 'Notes',
                controller: _notesController,
                hintText: 'Optional notes',
                maxLines: 3,
              ),
              if (!widget.isEditing) ...[
                const SizedBox(height: AppSpacing.space8),
                _buildItemsSection(),
              ],
              const SizedBox(height: AppSpacing.space10),
              SizedBox(
                height: AppSpacing.space56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    textStyle: const TextStyle(
                      fontSize: AppFontSizes.lg,
                      fontWeight: AppFontWeights.semibold,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: AppSpacing.space8,
                          height: AppSpacing.space8,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Text(widget.isEditing ? 'Update' : 'Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    final total = _items.fold(0.0, (sum, i) => sum + i.subtotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Items (${_items.length})',
              style: const TextStyle(
                fontSize: AppFontSizes.lg,
                fontWeight: AppFontWeights.semibold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _showAddItemSheet,
              icon: const Icon(Icons.add, size: AppFontSizes.iconSm),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
            ),
          ],
        ),
        if (_items.isEmpty)
          AppCard(
            child: Column(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppColors.textSecondary,
                  size: AppFontSizes.x2l,
                ),
                const SizedBox(height: AppSpacing.space3),
                const Text(
                  'No items yet',
                  style: TextStyle(
                    fontSize: AppFontSizes.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),
                TextButton(
                  onPressed: _showAddItemSheet,
                  child: const Text('Add Item'),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              ..._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.space5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: AppFontSizes.sm,
                                  fontWeight: AppFontWeights.semibold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.space1),
                              Text(
                                '${formatQuantity(item.quantity)} ${item.unit} × ${formatPeso(item.unitPrice)}',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.xs,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.space3),
                          child: Text(
                            formatPeso(item.subtotal),
                            style: const TextStyle(
                              fontSize: AppFontSizes.sm,
                              fontWeight: AppFontWeights.semibold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _removeItem(item.id),
                          child: const Icon(
                            Icons.close,
                            size: AppFontSizes.iconSm,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: AppFontSizes.md,
                        fontWeight: AppFontWeights.semibold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      formatPeso(total),
                      style: const TextStyle(
                        fontSize: AppFontSizes.lg,
                        fontWeight: AppFontWeights.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showAddItemSheet,
                    icon: const Icon(Icons.add, size: AppFontSizes.iconSm),
                    label: const Text('Add Another Item'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space5,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildCustomerSelector(AsyncValue<List<Customer>> asyncCustomers) {
    return asyncCustomers.when(
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const Text(
        'Failed to load customers',
        style: TextStyle(color: AppColors.error),
      ),
      data: (customers) {
        if (_selectedCustomer != null && !_isInitialized) {
          _isInitialized = true;
          final match = customers.where(
            (c) => c.id == _selectedCustomer!.id,
          );
          if (match.isNotEmpty) {
            _selectedCustomer = match.first;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Customer',
                  style: TextStyle(
                    fontSize: AppFontSizes.sm,
                    fontWeight: AppFontWeights.semibold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: AppFontSizes.sm,
                    fontWeight: AppFontWeights.semibold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space7,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Customer>(
                  value: _selectedCustomer,
                  isExpanded: true,
                  hint: const Text(
                    'Select a customer',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  items: customers.map((customer) {
                    return DropdownMenuItem(
                      value: customer,
                      child: Text(
                        customer.name,
                        style: const TextStyle(
                          fontWeight: AppFontWeights.medium,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCustomer = value),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool isDueDate;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.isDueDate,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSizes.sm,
            fontWeight: AppFontWeights.semibold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space7,
              vertical: AppSpacing.space4,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
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
                        : 'Select date',
                    style: TextStyle(
                      fontSize: AppFontSizes.sm,
                      fontWeight: AppFontWeights.medium,
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(
                      Icons.close,
                      size: AppFontSizes.iconSm,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
