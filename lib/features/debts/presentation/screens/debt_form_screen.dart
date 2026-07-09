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
import 'package:utang_tracker/core/presentation/app_async_views.dart';
import 'package:utang_tracker/core/presentation/app_button.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/core/presentation/app_date_field.dart';
import 'package:utang_tracker/core/presentation/app_dropdown_field.dart';
import 'package:utang_tracker/core/presentation/app_inline_empty.dart';
import 'package:utang_tracker/core/presentation/app_input.dart';
import 'package:utang_tracker/core/presentation/app_section_header.dart';
import 'package:utang_tracker/core/utils/number_formatter.dart';
import 'package:utang_tracker/core/utils/snackbar_helper.dart';
import 'package:utang_tracker/features/customers/domain/customer.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:utang_tracker/features/debt_items/presentation/providers/debt_item_providers.dart';
import 'package:utang_tracker/features/debt_items/presentation/widgets/debt_item_fields.dart';
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
    } else if (widget.customerId != null) {
      _selectedCustomer = Customer(
        id: widget.customerId!,
        name: '',
        createdAt: DateTimeHelper.now(),
        updatedAt: DateTimeHelper.now(),
      );
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
    final result = await showModalBottomSheet<_TempItemData>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sm)),
      ),
      builder: (ctx) => const _AddDebtItemSheet(),
    );

    if (result != null && mounted) {
      setState(() {
        _itemIdCounter++;
        _items.add(_TempItemData(
          id: 'temp_$_itemIdCounter',
          productName: result.productName,
          quantity: result.quantity,
          unit: result.unit,
          unitPrice: result.unitPrice,
        ));
      });
    }
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
            ref.invalidate(allDebtsProvider);
            ref.invalidate(dashboardProvider);
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
            ref.invalidate(allDebtsProvider);
            ref.invalidate(dashboardProvider);
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
        appBar: AppBar(title: const Text('Edit Debt Details')),
        body: const AppLoadingView(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Debt Details' : 'New Debt'),
      ),
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
              AppDateField(
                label: 'Transaction Date',
                value: _transactionDate,
                isRequired: true,
                onTap: () => _pickDate(false),
              ),
              const SizedBox(height: AppSpacing.space7),
              AppDateField(
                label: 'Due Date',
                value: _dueDate,
                placeholder: 'Optional due date',
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
              if (widget.isEditing) ...[
                const SizedBox(height: AppSpacing.space5),
                const Text(
                  'Manage products from the debt screen.',
                  style: TextStyle(
                    fontSize: AppFontSizes.md,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (!widget.isEditing) ...[
                const SizedBox(height: AppSpacing.space8),
                _buildItemsSection(),
              ],
              const SizedBox(height: AppSpacing.space10),
              AppPrimaryButton(
                label: widget.isEditing ? 'Save' : 'Create debt',
                onPressed: _save,
                isLoading: _isSaving,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          label: 'Items',
          count: _items.length,
          actionLabel: 'Add item',
          onAction: _showAddItemSheet,
        ),
        const SizedBox(height: AppSpacing.space5),
        if (_items.isEmpty)
          const AppInlineEmpty(
            icon: Icons.shopping_cart_outlined,
            title: 'No items yet',
            subtitle: 'Add products to this debt',
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._items.map(
                (item) => AppCard(
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
                                fontSize: AppFontSizes.md,
                                fontWeight: AppFontWeights.semibold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space1),
                            Text(
                              '${formatQuantity(item.quantity)} ${item.unit} × ${formatPeso(item.unitPrice)}',
                              style: const TextStyle(
                                fontSize: AppFontSizes.sm,
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
                            fontSize: AppFontSizes.md,
                            fontWeight: AppFontWeights.semibold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove item',
                        onPressed: () => _removeItem(item.id),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.error,
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
            ],
          ),
      ],
    );
  }

  Widget _buildCustomerSelector(AsyncValue<List<Customer>> asyncCustomers) {
    return asyncCustomers.when(
      loading: () => const AppLoadingView(),
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedCustomer = match.first);
            });
          }
        }

        Customer? dropdownValue;
        if (_selectedCustomer != null) {
          final match =
              customers.where((c) => c.id == _selectedCustomer!.id);
          dropdownValue = match.isNotEmpty ? match.first : null;
        }

        return AppDropdownField<Customer>(
          label: 'Customer',
          value: dropdownValue,
          isRequired: true,
          hintText: 'Select a customer',
          items: customers
              .map(
                (customer) => DropdownMenuItem(
                  value: customer,
                  child: Text(customer.name),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedCustomer = value),
        );
      },
    );
  }
}

/// Owns sheet controllers so they are disposed only when the sheet is gone.
class _AddDebtItemSheet extends StatefulWidget {
  const _AddDebtItemSheet();

  @override
  State<_AddDebtItemSheet> createState() => _AddDebtItemSheetState();
}

class _AddDebtItemSheetState extends State<_AddDebtItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  String _unit = 'pc';

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Use Navigator.pop so go_router does not pop the parent DebtFormScreen.
    Navigator.of(context).pop(
      _TempItemData(
        id: '',
        productName: _nameController.text.trim(),
        quantity: double.parse(_qtyController.text.trim()),
        unit: _unit,
        unitPrice: double.parse(_priceController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.space7,
          AppSpacing.space7,
          AppSpacing.space7,
          AppSpacing.space7 + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                DebtItemFields(
                  nameController: _nameController,
                  qtyController: _qtyController,
                  priceController: _priceController,
                  unit: _unit,
                  onUnitChanged: (value) => setState(() => _unit = value),
                ),
                const SizedBox(height: AppSpacing.space8),
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Cancel',
                        foregroundColor: AppColors.textSecondary,
                        borderColor: AppColors.border,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space5),
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Add',
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
