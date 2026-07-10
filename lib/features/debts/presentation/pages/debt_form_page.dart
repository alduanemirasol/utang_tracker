import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/utils/debt_math.dart';
import 'package:utang_tracker/core/utils/invalidate_helpers.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/app_text_field.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';

class DebtFormPage extends ConsumerStatefulWidget {
  const DebtFormPage({
    super.key,
    this.debtId,
    this.initialCustomerId,
  });

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
        unit = TextEditingController(text: 'pc'),
        unitPrice = TextEditingController();

  final TextEditingController product;
  final TextEditingController quantity;
  final TextEditingController unit;
  final TextEditingController unitPrice;

  void dispose() {
    product.dispose();
    quantity.dispose();
    unit.dispose();
    unitPrice.dispose();
  }
}

class _DebtFormPageState extends ConsumerState<DebtFormPage> {
  String? _customerId;
  DateTime _transactionDate = DateTime.now();
  DateTime? _dueDate;
  final _notesController = TextEditingController();
  final List<_LineItemControllers> _items = [_LineItemControllers()];
  bool _saving = false;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _customerId = widget.initialCustomerId;
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
    final subtotals = <Money>[];
    for (final item in _items) {
      final qty = double.tryParse(item.quantity.text.trim()) ?? 0;
      Money price;
      try {
        price = Money.fromPesoString(
          item.unitPrice.text.isEmpty ? '0' : item.unitPrice.text,
        );
      } catch (_) {
        price = Money.zero();
      }
      if (qty > 0 && price.isPositive) {
        subtotals.add(
          DebtMath.computeSubtotal(quantity: qty, unitPrice: price),
        );
      }
    }
    return DebtMath.computeTotal(subtotals);
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
  }

  List<DebtItemInput>? _buildItems() {
    final result = <DebtItemInput>[];
    for (final item in _items) {
      final name = item.product.text.trim();
      final qty = double.tryParse(item.quantity.text.trim());
      final unit = item.unit.text.trim();
      Money price;
      try {
        price = Money.fromPesoString(item.unitPrice.text);
      } catch (_) {
        setState(() => _error = 'Enter a valid unit price.');
        return null;
      }
      if (name.isEmpty || qty == null || qty <= 0 || unit.isEmpty || !price.isPositive) {
        setState(
          () => _error =
              'Each item needs product name, quantity > 0, unit, and price > 0.',
        );
        return null;
      }
      result.add(
        DebtItemInput(
          productName: name,
          quantity: qty,
          unit: unit,
          unitPrice: price,
        ),
      );
    }
    return result;
  }

  Future<void> _save() async {
    setState(() => _error = null);

    if (_customerId == null) {
      setState(() => _error = 'Select a customer.');
      return;
    }
    final items = _buildItems();
    if (items == null) return;

    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        await ref.read(updateDebtProvider)(
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
        final debt = await ref.read(createDebtProvider)(
          customerId: _customerId!,
          transactionDate: _transactionDate,
          dueDate: _dueDate,
          notes: _notesController.text,
          items: items,
        );
        invalidateBusinessData(
          ref,
          customerId: _customerId,
          debtId: debt.id,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? 'Debt updated' : 'Debt recorded'),
        ),
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
    _transactionDate = data.detail.debt.transactionDate.toLocal();
    _dueDate = data.detail.debt.dueDate?.toLocal();
    _notesController.text = data.detail.debt.notes ?? '';
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
          c.unit.text = item.unit;
          c.unitPrice.text = item.unitPrice.pesos.toStringAsFixed(2);
          return c;
        }),
      );
    if (_items.isEmpty) _items.add(_LineItemControllers());
    _loaded = true;
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
    final customersAsync = ref.watch(customersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit debt' : 'New debt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text('Customer *', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          customersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
            data: (customers) {
              if (customers.isEmpty) {
                return AppButton(
                  label: 'Add a customer first',
                  onPressed: () => context.push('/customers/new'),
                );
              }
              return DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _customerId != null &&
                        customers.any((c) => c.id == _customerId)
                    ? _customerId
                    : null,
                items: customers
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: widget.isEditing
                    ? null
                    : (v) => setState(() => _customerId = v),
                decoration: const InputDecoration(
                  hintText: 'Select customer',
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Date *',
                  value: DateFormatters.formatDate(_transactionDate),
                  onTap: () => _pickDate(due: false),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateField(
                  label: 'Due date',
                  value: _dueDate == null
                      ? 'Optional'
                      : DateFormatters.formatDate(_dueDate!),
                  onTap: () => _pickDate(due: true),
                  onClear: _dueDate == null
                      ? null
                      : () => setState(() => _dueDate = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Text('Items *', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _items.add(_LineItemControllers())),
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
                        Text(
                          'Item ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (_items.length > 1)
                          IconButton(
                            tooltip: 'Remove item',
                            onPressed: () {
                              setState(() {
                                item.dispose();
                                _items.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.close, size: 20),
                          ),
                      ],
                    ),
                    AppTextField(
                      controller: item.product,
                      label: 'Product',
                      hint: 'e.g. Bigas',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: item.quantity,
                            label: 'Qty',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            controller: item.unit,
                            label: 'Unit',
                            hint: AppConstants.commonUnits.first,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: AppTextField(
                            controller: item.unitPrice,
                            label: 'Unit price',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                            onChanged: (_) => setState(() {}),
                          ),
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
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
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
            maxLines: 2,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: widget.isEditing ? 'Save changes' : 'Save debt',
            onPressed: _save,
            isLoading: _saving,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
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
            child: Text(value),
          ),
        ),
      ],
    );
  }
}
