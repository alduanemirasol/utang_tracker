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

  Future<void> _showItemDialog({int? index}) async {
    final isEditing = index != null;
    final existing = index != null ? _items[index] : null;
    final productController = TextEditingController(
      text: existing?.productName ?? '',
    );
    final quantityController = TextEditingController(
      text: existing != null ? _formatQuantity(existing.quantity) : '1',
    );
    final priceController = TextEditingController(
      text: existing != null ? existing.price.pesos.toStringAsFixed(2) : '',
    );
    String unit = existing?.unit ?? DebtItemUnits.piece;

    String? productError;
    String? quantityError;
    String? priceError;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickUnit() async {
              final selected = await showAppModalBottomSheet<String>(
                context: context,
                builder: (context) => _UnitPickerSheet(selectedUnit: unit),
              );
              if (selected == null) return;
              setDialogState(() => unit = selected);
            }

            void save() {
              final productName = productController.text.trim();
              final quantityText = quantityController.text.trim();
              final priceText = priceController.text.trim();
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
                setDialogState(() {
                  productError = pErr;
                  quantityError = qErr;
                  priceError = prErr;
                });
                return;
              }

              final input = DebtItemInput(
                productName: productName,
                quantity: qty!,
                unit: unit,
                price: price!,
              );
              if (index != null) {
                setState(() => _items[index] = input);
              } else {
                setState(() => _items.add(input));
              }
              _markDirty();
              Navigator.of(dialogContext).pop(true);
            }

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              title: Text(isEditing ? 'Edit paninda' : 'Add paninda'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: productController,
                      label: 'Product *',
                      hint: 'Bugas',
                      errorText: productError,
                      onChanged: (_) {
                        if (productError != null) {
                          setDialogState(() => productError = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: quantityController,
                            label: 'Quantity *',
                            hint: '2',
                            errorText: quantityError,
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
                              if (quantityError != null) {
                                setDialogState(() => quantityError = null);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _UnitField(
                            unit: unit,
                            onTap: pickUnit,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: priceController,
                      label: 'Halaga *',
                      hint: '50.00',
                      errorText: priceError,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      onChanged: (_) {
                        if (priceError != null) {
                          setDialogState(() => priceError = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Buong halaga nito',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      // ignore: unnecessary_cast
                      setState(() => _items.removeAt(index as int));
                      _markDirty();
                      Navigator.of(dialogContext).pop(true);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: save,
                  child: Text(isEditing ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    // Dispose local controllers after dialog closes.
    productController.dispose();
    quantityController.dispose();
    priceController.dispose();

    if (result == true && mounted) {
      setState(() => _error = null);
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
              _buildSummaryRow(
                dialogContext,
                label: 'Date',
                value: dateLabel,
              ),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
            ),
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
            const SizedBox(height: AppSpacing.xl),
            AppTextField.buildLabel(context, 'Items *'),
            const SizedBox(height: AppSpacing.sm),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: Text(
                    'No items',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
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
                                      '${_formatQuantity(_items[i].quantity)} · ${DebtItemUnits.displayNameForQuantity(_items[i].unit, _items[i].quantity)}',
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
                                    onPressed: () =>
                                        _showItemDialog(index: i),
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
                  onPressed: () => setState(() => _notesExpanded = !_notesExpanded),
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
                MoneyText(
                  _total,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showItemDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: widget.isEditing ? 'Save changes' : 'Save',
                    onPressed: _save,
                    isLoading: _saving,
                  ),
                ),
              ],
            ),
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
