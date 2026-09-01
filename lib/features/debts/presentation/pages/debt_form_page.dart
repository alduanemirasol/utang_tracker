import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_time_display.dart';
import 'package:utang_tracker/core/utils/debt_math.dart';
import 'package:utang_tracker/app/coordination.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/app_modal_bottom_sheet.dart';
import 'package:utang_tracker/core/widgets/app_search_bar.dart';
import 'package:utang_tracker/core/widgets/app_snackbar.dart';
import 'package:utang_tracker/core/widgets/app_text_field.dart';
import 'package:utang_tracker/core/widgets/confirmation_dialog.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item_unit.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';

class DebtFormPage extends ConsumerStatefulWidget {
  const DebtFormPage({super.key, this.debtId, this.initialCustomerId});

  final String? debtId;
  final String? initialCustomerId;

  bool get isEditing => debtId != null;

  @override
  ConsumerState<DebtFormPage> createState() => _DebtFormPageState();
}

class _DebtFormPageState extends ConsumerState<DebtFormPage> {
  bool _isDirty = false;
  final _customerFieldKey = GlobalKey();
  String? _customerId;
  String? _customerName;
  DateTime _transactionDate = DateTime.now();
  DateTime? _dueDate;
  final _notesController = TextEditingController();
  bool _notesExpanded = false;
  final List<DebtItemInput> _items = [];
  bool _saving = false;
  bool _loaded = false;
  String? _customerError;
  String? _error;

  @override
  void initState() {
    super.initState();
    _customerId = widget.initialCustomerId;
    if (widget.initialCustomerId != null && !widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveCustomerName(widget.initialCustomerId!);
      });
    }
  }

  Future<void> _resolveCustomerName(String id) async {
    final customer = await ref.read(customerRepositoryProvider).getById(id);
    if (!mounted || customer == null) return;
    if (_customerId != id) return;
    setState(() => _customerName = customer.name);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _confirmBack() async {
    if (_saving) return;
    if (await confirmDiscardChanges(context) && mounted) context.pop();
  }

  Future<void> _pickCustomer() async {
    final selected = await showAppModalBottomSheet<Customer>(
      context: context,
      builder: (context) =>
          _CustomerPickerSheet(selectedCustomerId: _customerId),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _customerId = selected.id;
      _customerName = selected.name;
      _customerError = null;
    });
    _markDirty();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Money get _total {
    return computeTotal(_items.map((e) => e.price));
  }

  Future<void> _pickDate({required bool due}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialRaw = due ? (_dueDate ?? _transactionDate) : _transactionDate;
    final initial = due && initialRaw.isBefore(today) ? today : initialRaw;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: due ? today : DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (due) {
        _dueDate = picked;
      } else {
        _transactionDate = picked;
      }
    });
    _markDirty();
  }

  Future<void> _showItemDialog({int? index}) async {
    final existing = index != null ? _items[index] : null;
    final result = await showAppModalBottomSheet<dynamic>(
      context: context,
      builder: (context) => _ItemBottomSheet(existing: existing),
    );
    if (result == null) return;
    if (!mounted) return;
    if (result is DebtItemInput) {
      setState(() {
        if (index != null) {
          _items[index] = result;
        } else {
          _items.add(result);
        }
        _error = null;
      });
      _markDirty();
    } else if (result == true) {
      if (index != null) {
        setState(() {
          _items.removeAt(index);
          _error = null;
        });
        _markDirty();
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _customerError = _customerId == null ? 'Select a customer.' : null;
    });
    if (_customerError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFirstError();
      });
      return;
    }
    if (_items.isEmpty) {
      setState(() => _error = 'Add at least one item');
      return;
    }
    if (_dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day);
      if (dueDay.isBefore(today)) {
        setState(() => _error = 'Due date cannot be in the past');
        return;
      }
    }
    final items = _items.toList();

    // Prepare formatted strings BEFORE showing dialog to avoid async gap context issues.
    final customerLabel = _customerName ?? 'No customer';
    final dateLabel = context.smartDate(_transactionDate);
    final dueLabel = _dueDate == null
        ? 'No due date'
        : context.smartDate(_dueDate!);
    final totalLabel = _total.format();
    final notesText = _notesController.text.trim();
    final notesLabel = notesText.isEmpty ? 'No notes' : notesText;
    final confirmedItems = items;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Text(widget.isEditing ? 'Confirm changes?' : 'Confirm utang?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryRow(
                dialogContext,
                label: 'Customer',
                value: customerLabel,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSummaryRow(dialogContext, label: 'Date', value: dateLabel),
              const SizedBox(height: AppSpacing.sm),
              _buildSummaryRow(dialogContext, label: 'Due', value: dueLabel),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Items',
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...confirmedItems.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${e.productName} \u00b7 ${_formatQuantity(e.quantity)} ${DebtItemUnits.displayNameForQuantity(e.unit, e.quantity)}',
                          style: Theme.of(dialogContext).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        e.price.format(),
                        style: Theme.of(dialogContext).textTheme.bodySmall
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: AppSpacing.lg),
              Row(
                children: [
                  Text(
                    'Total',
                    style: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    totalLabel,
                    style: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Notes',
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                notesLabel,
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: notesText.isEmpty
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(widget.isEditing ? 'Save' : 'Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(debtRepositoryProvider);
      if (widget.isEditing) {
        await repo.update(
          id: widget.debtId!,
          transactionDate: _transactionDate,
          dueDate: _dueDate,
          notes: _notesController.text,
          items: items,
        );
        invalidateBusinessData(
          ref,
          customerId: _customerId,
          debtId: widget.debtId,
        );
      } else {
        final debt = await repo.create(
          customerId: _customerId!,
          transactionDate: _transactionDate,
          dueDate: _dueDate,
          notes: _notesController.text,
          items: items,
        );
        invalidateBusinessData(ref, customerId: _customerId, debtId: debt.id);
      }

      if (!mounted) return;
      _isDirty = false;
      AppSnackBar.success(
        context,
        widget.isEditing ? 'Utang updated' : 'Utang recorded',
      );
      context.pop();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatQuantity(double quantity) {
    return quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toString();
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  void _loadEdit(DebtDetailViewData data) {
    _customerId = data.detail.debt.customerId;
    _customerName = data.detail.debt.customerName;
    _transactionDate = data.detail.debt.transactionDate.toLocal();
    _dueDate = data.detail.debt.dueDate?.toLocal();
    _notesController.text = data.detail.debt.notes ?? '';
    _notesExpanded = _notesController.text.trim().isNotEmpty;
    if (_customerName == null || _customerName!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_customerId != null) _resolveCustomerName(_customerId!);
      });
    }
    _items
      ..clear()
      ..addAll(
        data.detail.items.map(
          (item) => DebtItemInput(
            productName: item.productName,
            quantity: item.quantity,
            unit: item.unit,
            price: item.price,
          ),
        ),
      );
    _isDirty = false;
    _loaded = true;
  }

  void _scrollToFirstError() {
    if (_customerError != null) {
      final ctx = _customerFieldKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.2,
          duration: const Duration(milliseconds: 300),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing && !_loaded) {
      final async = ref.watch(debtDetailProvider(widget.debtId!));
      return async.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit debt')),
          body: const LoadingIndicator(),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit debt')),
          body: Center(child: Text(e.toString())),
        ),
        data: (data) {
          if (data == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit debt')),
              body: const Center(child: Text('Debt not found')),
            );
          }
          if (!data.detail.debt.isEditable) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit debt')),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'This debt already has payments and cannot be edited.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          if (!_loaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _loadEdit(data));
            });
          }
          return _buildForm();
        },
      );
    }

    return _buildForm();
  }

  Widget _buildForm() {
    return PopScope(
      canPop: !_isDirty && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit utang' : 'New utang'),
        ),
        bottomNavigationBar: _buildBottomBar(),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            AppTextField.buildLabel(context, 'Customer *'),
            const SizedBox(height: AppSpacing.sm),
            _CustomerField(
              key: _customerFieldKey,
              name: _customerName,
              enabled: !widget.isEditing,
              onTap: _pickCustomer,
              errorText: _customerError,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Date',
                    required: true,
                    value: context.smartDate(_transactionDate),
                    onTap: () => _pickDate(due: false),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _DateField(
                    label: 'Due date',
                    value: _dueDate == null
                        ? 'Optional'
                        : context.smartDate(_dueDate!),
                    onTap: () => _pickDate(due: true),
                    onClear: _dueDate == null
                        ? null
                        : () {
                            setState(() => _dueDate = null);
                            _markDirty();
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppTextField.buildLabel(context, 'Items *'),
                TextButton.icon(
                  onPressed: () => _showItemDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add item'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(
                  child: Text(
                    'No items',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < _items.length; i++) ...[
                      InkWell(
                        onTap: () => _showItemDialog(index: i),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.cardPadding,
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _items[i].productName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '${_formatQuantity(_items[i].quantity)} ${DebtItemUnits.displayNameForQuantity(_items[i].unit, _items[i].quantity)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MoneyText(
                                    _items[i].price,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () => _showItemDialog(index: i),
                                    padding: const EdgeInsets.all(12),
                                    constraints: const BoxConstraints(
                                      minWidth: 44,
                                      minHeight: 44,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Edit',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (i < _items.length - 1)
                        const Divider(
                          height: 1,
                          indent: AppSpacing.cardPadding,
                          endIndent: AppSpacing.cardPadding,
                        ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppTextField.buildLabel(context, 'Notes'),
                IconButton(
                  tooltip: _notesExpanded ? 'Hide note' : 'Add note',
                  onPressed: () =>
                      setState(() => _notesExpanded = !_notesExpanded),
                  icon: Icon(
                    _notesExpanded ? Icons.close : Icons.add,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (_notesExpanded) ...[
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _notesController,
                hint: 'Optional',
                minLines: 4,
                maxLines: 6,
                onChanged: (_) => _markDirty(),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.sm,
          AppSpacing.pagePadding,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                MoneyText(_total, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: widget.isEditing ? 'Save changes' : 'Save',
              onPressed: _save,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemBottomSheet extends ConsumerStatefulWidget {
  const _ItemBottomSheet({this.existing});

  final DebtItemInput? existing;

  @override
  ConsumerState<_ItemBottomSheet> createState() => _ItemBottomSheetState();
}

class _ItemBottomSheetState extends ConsumerState<_ItemBottomSheet> {
  late final TextEditingController _productController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final FocusNode _productFocusNode;
  late String _unit;
  String? _productError;
  String? _quantityError;
  String? _priceError;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _productController = TextEditingController(
      text: existing?.productName ?? '',
    );
    _productFocusNode = FocusNode();
    _quantityController = TextEditingController(
      text: existing != null ? _formatQuantity(existing.quantity) : '1',
    );
    _priceController = TextEditingController(
      text: existing != null ? existing.price.pesos.toStringAsFixed(2) : '',
    );
    _unit = existing?.unit ?? DebtItemUnits.piece;
  }

  @override
  void dispose() {
    _productController.dispose();
    _productFocusNode.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _formatQuantity(double quantity) {
    return quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toString();
  }

  Future<void> _pickUnit() async {
    final selected = await showAppModalBottomSheet<String>(
      context: context,
      builder: (context) => _UnitPickerSheet(selectedUnit: _unit),
    );
    if (selected == null) return;
    setState(() => _unit = selected);
  }

  void _save() {
    final productName = _productController.text.trim();
    final quantityText = _quantityController.text.trim();
    final priceText = _priceController.text.trim();
    final qty = double.tryParse(quantityText);

    String? pErr;
    String? qErr;
    String? prErr;
    Money? price;

    if (productName.isEmpty) {
      pErr = 'Product is required.';
    }
    if (quantityText.isEmpty) {
      qErr = 'Quantity is required.';
    } else if (qty == null) {
      qErr = 'Enter a valid quantity.';
    } else if (qty <= 0) {
      qErr = 'Quantity must be greater than 0.';
    }

    if (priceText.isEmpty) {
      prErr = 'Price is required.';
    } else {
      try {
        price = Money.fromPesoString(priceText);
        if (!price.isPositive) {
          prErr = 'Price must be greater than 0.';
        }
      } catch (_) {
        prErr = 'Enter a valid price.';
      }
    }

    if (pErr != null || qErr != null || prErr != null) {
      setState(() {
        _productError = pErr;
        _quantityError = qErr;
        _priceError = prErr;
      });
      return;
    }

    final input = DebtItemInput(
      productName: productName,
      quantity: qty!,
      unit: _unit,
      price: price!,
    );
    Navigator.of(context).pop(input);
  }

  @override
  Widget build(BuildContext context) {
    final recentAsync = ref.watch(recentProductNamesProvider);
    final recentNames = recentAsync.value ?? const <String>[];

    return AppModalBottomSheet(
      title: _isEditing ? 'Edit item' : 'Add item',
      footer: Row(
        children: [
          if (_isEditing)
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Delete'),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: _save,
            child: Text(_isEditing ? 'Update' : 'Save'),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProductAutocompleteField(
              controller: _productController,
              focusNode: _productFocusNode,
              errorText: _productError,
              recentNames: recentNames,
              isLoading: recentAsync.isLoading,
              onChanged: (_) {
                if (_productError != null) {
                  setState(() => _productError = null);
                }
              },
              onSelected: (value) {
                _productController.text = value;
                _productController.selection = TextSelection.collapsed(
                  offset: value.length,
                );
                if (_productError != null) {
                  setState(() => _productError = null);
                } else {
                  setState(() {});
                }
                _productFocusNode.unfocus();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _quantityController,
                    label: 'Quantity *',
                    hint: '2',
                    errorText: _quantityError,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    onChanged: (_) {
                      if (_quantityError != null) {
                        setState(() => _quantityError = null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _UnitField(unit: _unit, onTap: _pickUnit),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _priceController,
              label: 'Price *',
              hint: '50.00',
              errorText: _priceError,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onChanged: (_) {
                if (_priceError != null) {
                  setState(() => _priceError = null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductAutocompleteField extends StatelessWidget {
  const _ProductAutocompleteField({
    required this.controller,
    required this.focusNode,
    required this.recentNames,
    required this.isLoading,
    required this.onChanged,
    required this.onSelected,
    this.errorText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> recentNames;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSelected;
  final String? errorText;

  static const int _maxSuggestions = 8;

  Iterable<String> _optionsFor(String query, List<String> recent) {
    if (recent.isEmpty) return const Iterable<String>.empty();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return recent.take(_maxSuggestions);
    }
    final lower = trimmed.toLowerCase();
    return recent
        .where((e) => e.toLowerCase().contains(lower))
        .take(_maxSuggestions);
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String option,
    String query,
  ) {
    final q = query.trim();
    if (q.isEmpty) {
      return Text(
        option,
        style: AppTextField.inputStyle(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final lowerOption = option.toLowerCase();
    final lowerQuery = q.toLowerCase();
    final idx = lowerOption.indexOf(lowerQuery);
    if (idx < 0) {
      return Text(
        option,
        style: AppTextField.inputStyle(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final before = option.substring(0, idx);
    final match = option.substring(idx, idx + q.length);
    final after = option.substring(idx + q.length);
    final base = AppTextField.inputStyle(context);
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: base,
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: match,
            style: base?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasData = !isLoading && recentNames.isNotEmpty;

    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (!hasData) return const Iterable<String>.empty();
        return _optionsFor(textEditingValue.text, recentNames);
      },
      displayStringForOption: (option) => option,
      onSelected: onSelected,
      fieldViewBuilder:
          (context, textController, fieldFocusNode, onFieldSubmitted) {
            return AppTextField(
              controller: textController,
              focusNode: fieldFocusNode,
              label: 'Product *',
              hint: 'Bugas',
              errorText: errorText,
              textInputAction: TextInputAction.next,
              prefixIcon: hasData
                  ? const Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    )
                  : null,
              suffixIcon: hasData
                  ? const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    )
                  : null,
              onChanged: onChanged,
              onSubmitted: (_) => onFieldSubmitted(),
            );
          },
      optionsViewBuilder:
          (context, AutocompleteOnSelected<String> onSelected, options) {
            final query = controller.text;
            final opts = options.toList(growable: false);
            if (opts.isEmpty) {
              return const SizedBox.shrink();
            }
            final screenWidth = MediaQuery.sizeOf(context).width;
            final dropdownWidth = (screenWidth - (AppSpacing.pagePadding * 2))
                .clamp(200.0, 600.0);
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                shadowColor: AppColors.shadow,
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 196,
                    maxWidth: dropdownWidth,
                    minWidth: dropdownWidth,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Recent',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.outline,
                      ),
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: opts.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.outline,
                          ),
                          itemBuilder: (context, index) {
                            final option = opts[index];
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildHighlightedText(
                                        context,
                                        option,
                                        query,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }
}

class _CustomerField extends StatelessWidget {
  const _CustomerField({
    super.key,
    required this.name,
    required this.enabled,
    required this.onTap,
    this.errorText,
  });

  final String? name;
  final bool enabled;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasName = name != null && name!.isNotEmpty;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          errorText: errorText,
          suffixIcon: Icon(
            enabled ? Icons.person_search_outlined : Icons.lock_outline,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
        child: Text(
          hasName ? name! : 'Select customer',
          style: AppTextField.inputStyle(
            context,
            color: hasName ? AppColors.textPrimary : AppColors.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _UnitField extends StatelessWidget {
  const _UnitField({required this.unit, required this.onTap});

  final String unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField.buildLabel(context, 'Unit *'),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DebtItemUnits.displayName(unit),
                    style: AppTextField.inputStyle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UnitPickerSheet extends StatelessWidget {
  const _UnitPickerSheet({required this.selectedUnit});

  final String selectedUnit;

  @override
  Widget build(BuildContext context) {
    final selectedIsCustom = !DebtItemUnits.isCommon(selectedUnit);

    return AppModalBottomSheet(
      title: 'Select unit',
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        itemCount: DebtItemUnits.common.length + 1,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          indent: AppSpacing.lg,
          endIndent: AppSpacing.lg,
          color: AppColors.outline,
        ),
        itemBuilder: (context, index) {
          if (index == DebtItemUnits.common.length) {
            return ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(
                'Custom unit',
                style: AppTextField.inputStyle(
                  context,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: selectedIsCustom
                  ? Text(
                      DebtItemUnits.displayName(selectedUnit),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : Text(
                      'Use another selling unit',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
              trailing: selectedIsCustom
                  ? const Icon(Icons.check, color: AppColors.primaryDark)
                  : const Icon(Icons.chevron_right),
              onTap: () async {
                final custom = await showDialog<String>(
                  context: context,
                  builder: (context) => _CustomUnitDialog(
                    initialValue: selectedIsCustom ? selectedUnit : '',
                  ),
                );
                if (custom == null || !context.mounted) return;
                Navigator.of(context).pop(custom);
              },
            );
          }

          final option = DebtItemUnits.common[index];
          final selected = option.value == selectedUnit;
          return ListTile(
            title: Text(
              option.label,
              style: AppTextField.inputStyle(
                context,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: selected
                ? const Icon(Icons.check, color: AppColors.primaryDark)
                : null,
            onTap: () => Navigator.of(context).pop(option.value),
          );
        },
      ),
    );
  }
}

class _CustomUnitDialog extends StatefulWidget {
  const _CustomUnitDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_CustomUnitDialog> createState() => _CustomUnitDialogState();
}

class _CustomUnitDialogState extends State<_CustomUnitDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = DebtItemUnits.normalize(_controller.text);
    if (value.isEmpty) {
      setState(() => _error = 'Enter a unit name.');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom unit'),
      content: AppTextField(
        controller: _controller,
        label: 'Unit name *',
        hint: 'sack',
        errorText: _error,
        autofocus: true,
        textInputAction: TextInputAction.done,
        inputFormatters: [LengthLimitingTextInputFormatter(24)],
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Use unit')),
      ],
    );
  }
}

class _CustomerPickerSheet extends ConsumerStatefulWidget {
  const _CustomerPickerSheet({required this.selectedCustomerId});

  final String? selectedCustomerId;

  @override
  ConsumerState<_CustomerPickerSheet> createState() =>
      _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends ConsumerState<_CustomerPickerSheet> {
  String _query = '';
  List<Customer>? _customers;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  Future<void> _load(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trimmed = query.trim();
      final repo = ref.read(customerRepositoryProvider);
      final results = trimmed.isEmpty
          ? await repo.getAll()
          : await repo.search(trimmed);
      if (!mounted) return;
      setState(() {
        _customers = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = _customers;

    return AppModalBottomSheet(
      title: 'Select customer',
      headerBottom: AppSearchBar(
        hintText: 'Search customer',
        onChanged: (value) {
          _query = value;
          _load(value);
        },
      ),
      footer: TextButton.icon(
        onPressed: () async {
          final router = GoRouter.of(context);
          Navigator.of(context).pop();
          await router.push('/customers/new');
        },
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add customer'),
      ),
      child: _buildBody(customers),
    );
  }

  Widget _buildBody(List<Customer>? customers) {
    if (_loading && customers == null) {
      return const LoadingIndicator();
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            _error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
          ),
        ),
      );
    }
    if (customers == null || customers.isEmpty) {
      final searching = _query.trim().isNotEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            searching
                ? 'No customers match your search.'
                : 'No customers yet. Add one to continue.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      itemCount: customers.length,
      separatorBuilder: (_, _) => const Divider(
        height: 1,
        thickness: 1,
        indent: AppSpacing.lg,
        endIndent: AppSpacing.lg,
        color: AppColors.outline,
      ),
      itemBuilder: (context, index) {
        final customer = customers[index];
        final selected = customer.id == widget.selectedCustomerId;
        return ListTile(
          title: Text(customer.name),
          subtitle: customer.phone == null || customer.phone!.isEmpty
              ? null
              : Text(customer.phone!),
          trailing: selected
              ? const Icon(Icons.check, color: AppColors.primaryDark)
              : null,
          onTap: () => Navigator.of(context).pop(customer),
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
    this.required = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField.buildLabel(context, required ? '$label *' : label),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: onClear != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onClear,
                    )
                  : const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              value,
              style: AppTextField.inputStyle(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
