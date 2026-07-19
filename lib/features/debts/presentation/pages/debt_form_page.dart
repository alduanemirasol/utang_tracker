import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_time_display.dart';
import 'package:utang_tracker/core/utils/debt_math.dart';
import 'package:utang_tracker/core/utils/invalidate_helpers.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/app_modal_bottom_sheet.dart';
import 'package:utang_tracker/core/widgets/app_search_bar.dart';
import 'package:utang_tracker/core/widgets/app_snackbar.dart';
import 'package:utang_tracker/core/widgets/app_text_field.dart';
import 'package:utang_tracker/core/widgets/confirmation_dialog.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
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

class _LineItemControllers {
  _LineItemControllers()
    : product = TextEditingController(),
      quantity = TextEditingController(text: '1'),
      price = TextEditingController(),
      productFocusNode = FocusNode(),
      quantityFocusNode = FocusNode(),
      priceFocusNode = FocusNode();

  final TextEditingController product;
  final TextEditingController quantity;
  final TextEditingController price;
  final FocusNode productFocusNode;
  final FocusNode quantityFocusNode;
  final FocusNode priceFocusNode;
  String unit = DebtItemUnits.piece;
  bool isExpanded = true;
  String? productError;
  String? quantityError;
  String? priceError;

  void dispose() {
    product.dispose();
    quantity.dispose();
    price.dispose();
    productFocusNode.dispose();
    quantityFocusNode.dispose();
    priceFocusNode.dispose();
  }
}

class _DebtFormPageState extends ConsumerState<DebtFormPage> {
  bool _isDirty = false;
  final _customerFieldKey = GlobalKey();
  String? _customerId;
  String? _customerName;
  DateTime _transactionDate = DateTime.now();
  DateTime? _dueDate;
  final _notesController = TextEditingController();
  final List<_LineItemControllers> _items = [_LineItemControllers()];
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
    final customer = await ref.read(getCustomerByIdProvider)(id);
    if (!mounted || customer == null) return;
    if (_customerId != id) return;
    setState(() => _customerName = customer.name);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _confirmBack() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Discard changes?',
      message:
          'You have unsaved changes. Are you sure you want to discard them?',
      confirmLabel: 'Discard',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      context.pop();
    }
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
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  Money get _total {
    final prices = _items.map(_itemSubtotal).where((price) => price.isPositive);
    return DebtMath.computeTotal(prices);
  }

  Money _itemSubtotal(_LineItemControllers item) {
    try {
      return Money.fromPesoString(
        item.price.text.isEmpty ? '0' : item.price.text,
      );
    } catch (_) {
      return Money.zero();
    }
  }

  String _collapsedItemSummary(_LineItemControllers item) {
    final product = item.product.text.trim();
    final quantity = item.quantity.text.trim();
    final unit = DebtItemUnits.displayName(item.unit);
    return '${product.isEmpty ? 'No product yet' : product} · '
        '${quantity.isEmpty ? '0' : quantity} $unit';
  }

  Future<void> _pickDate({required bool due}) async {
    final initial = due ? (_dueDate ?? _transactionDate) : _transactionDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
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

  Future<void> _pickUnit(_LineItemControllers item) async {
    final selected = await showAppModalBottomSheet<String>(
      context: context,
      builder: (context) => _UnitPickerSheet(selectedUnit: item.unit),
    );
    if (selected == null || !mounted) return;
    setState(() => item.unit = selected);
    _markDirty();
  }

  void _addItem() {
    setState(() {
      for (final item in _items) {
        item.isExpanded = false;
      }
      _items.add(_LineItemControllers());
    });
    _markDirty();
  }

  List<DebtItemInput>? _buildItems() {
    final result = <DebtItemInput>[];
    var hasErrors = false;
    var expandedInvalidItem = false;

    for (final item in _items) {
      final name = item.product.text.trim();
      final quantityText = item.quantity.text.trim();
      final priceText = item.price.text.trim();
      final qty = double.tryParse(quantityText);

      item.productError = name.isEmpty ? 'Product is required.' : null;
      item.quantityError = quantityText.isEmpty
          ? 'Quantity is required.'
          : qty == null
          ? 'Enter a valid quantity.'
          : qty <= 0
          ? 'Quantity must be greater than 0.'
          : null;

      Money? price;
      if (priceText.isEmpty) {
        item.priceError = 'Price is required.';
      } else {
        try {
          price = Money.fromPesoString(priceText);
          item.priceError = price.isPositive
              ? null
              : 'Price must be greater than 0.';
        } catch (_) {
          item.priceError = 'Enter a valid price.';
        }
      }

      final itemHasErrors =
          item.productError != null ||
          item.quantityError != null ||
          item.priceError != null;
      if (itemHasErrors) {
        hasErrors = true;
        if (!expandedInvalidItem) {
          item.isExpanded = true;
          expandedInvalidItem = true;
        }
        continue;
      }

      result.add(
        DebtItemInput(
          productName: name,
          quantity: qty!,
          unit: item.unit,
          price: price!,
        ),
      );
    }
    return hasErrors ? null : result;
  }

  Future<void> _save() async {
    List<DebtItemInput>? items;
    setState(() {
      _error = null;
      _customerError = _customerId == null ? 'Select a customer.' : null;
      items = _buildItems();
    });
    if (_customerError != null || items == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFirstError();
      });
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        await ref.read(updateDebtProvider)(
          id: widget.debtId!,
          transactionDate: _transactionDate,
          dueDate: _dueDate,
          notes: _notesController.text,
          items: items!,
        );
        invalidateBusinessData(
          ref,
          customerId: _customerId,
          debtId: widget.debtId,
        );
      } else {
        final debt = await ref.read(createDebtProvider)(
          customerId: _customerId!,
          transactionDate: _transactionDate,
          dueDate: _dueDate,
          notes: _notesController.text,
          items: items!,
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
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _loadEdit(DebtDetailViewData data) {
    _customerId = data.detail.debt.customerId;
    _customerName = data.detail.debt.customerName;
    _transactionDate = data.detail.debt.transactionDate.toLocal();
    _dueDate = data.detail.debt.dueDate?.toLocal();
    _notesController.text = data.detail.debt.notes ?? '';
    if (_customerName == null || _customerName!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_customerId != null) _resolveCustomerName(_customerId!);
      });
    }
    for (final i in _items) {
      i.dispose();
    }
    _items
      ..clear()
      ..addAll(
        data.detail.items.map((item) {
          final c = _LineItemControllers();
          c.product.text = item.productName;
          c.quantity.text = item.quantity % 1 == 0
              ? item.quantity.toInt().toString()
              : item.quantity.toString();
          c.unit = item.unit;
          c.price.text = item.price.pesos.toStringAsFixed(2);
          return c;
        }),
      );
    if (_items.isEmpty) _items.add(_LineItemControllers());
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
      return;
    }

    for (final item in _items) {
      if (item.productError != null) {
        item.productFocusNode.requestFocus();
        return;
      }
      if (item.quantityError != null) {
        item.quantityFocusNode.requestFocus();
        return;
      }
      if (item.priceError != null) {
        item.priceFocusNode.requestFocus();
        return;
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
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit utang' : 'New utang'),
        ),
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
          _DateField(
            label: 'Date',
            required: true,
            value: context.smartDate(_transactionDate),
            onTap: () => _pickDate(due: false),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DateField(
            label: 'Due date',
            value: _dueDate == null ? 'Optional' : context.smartDate(_dueDate!),
            onTap: () => _pickDate(due: true),
            onClear: _dueDate == null
                ? null
                : () {
                      setState(() => _dueDate = null);
                      _markDirty();
                    },
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              AppTextField.buildLabel(
                context,
                'Items *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: item.isExpanded
                                ? 'Collapse item ${index + 1}'
                                : 'Expand item ${index + 1}',
                            child: InkWell(
                              onTap: () => setState(
                                () => item.isExpanded = !item.isExpanded,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Item ${index + 1}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          if (!item.isExpanded)
                                            Text(
                                              _collapsedItemSummary(item),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      item.isExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_items.length > 1)
                          IconButton(
                            tooltip: 'Remove item',
                            onPressed: () {
                              setState(() {
                                item.dispose();
                                _items.removeAt(index);
                              });
                              _markDirty();
                            },
                            icon: const Icon(Icons.close, size: 20),
                          ),
                      ],
                    ),
                    if (item.isExpanded) ...[
                      const Divider(height: AppSpacing.lg),
                      AppTextField(
                        controller: item.product,
                        focusNode: item.productFocusNode,
                        label: 'Product *',
                        hint: 'e.g. Bugas',
                        errorText: item.productError,
                        onChanged: (_) {
                          _markDirty();
                          setState(() => item.productError = null);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: item.quantity,
                              focusNode: item.quantityFocusNode,
                              label: 'Quantity *',
                              hint: 'e.g. 2',
                              errorText: item.quantityError,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d.]'),
                                ),
                              ],
                              onChanged: (_) {
                                _markDirty();
                                setState(() => item.quantityError = null);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _UnitField(
                              unit: item.unit,
                              onTap: () => _pickUnit(item),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: item.price,
                        focusNode: item.priceFocusNode,
                        label: 'Price *',
                        hint: 'e.g. 50.00',
                        errorText: item.priceError,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        ],
                        onChanged: (_) {
                          _markDirty();
                          setState(() => item.priceError = null);
                        },
                      ),
                    ],
                    const Divider(height: AppSpacing.xl),
                    Row(
                      key: ValueKey('debt-form-item-subtotal-row-$index'),
                      children: [
                        Text(
                          'Subtotal',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        MoneyText(
                          _itemSubtotal(item),
                          key: ValueKey(
                            'debt-form-item-subtotal-amount-$index',
                          ),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          AppCard(
            child: Row(
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                MoneyText(
                  _total,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _notesController,
            label: 'Notes',
            hint: 'Optional',
            minLines: 4,
            maxLines: 6,
            onChanged: (_) => _markDirty(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: widget.isEditing ? 'Save changes' : 'Save',
            onPressed: _save,
            isLoading: _saving,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    ),
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
              title: const Text('Custom unit'),
              subtitle: selectedIsCustom
                  ? Text(DebtItemUnits.displayName(selectedUnit))
                  : const Text('Use another selling unit'),
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
            title: Text(option.label),
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
        hint: 'e.g. sack',
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
      final results = trimmed.isEmpty
          ? await ref.read(getCustomersProvider)()
          : await ref.read(searchCustomersProvider)(trimmed);
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
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            searching
                ? 'No customers match your search.'
                : 'No customers yet. Add one to continue.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
            child: Text(value, style: AppTextField.inputStyle(context)),
          ),
        ),
      ],
    );
  }
}
