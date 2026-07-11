import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/utils/debt_math.dart';
import 'package:utang_tracker/core/utils/invalidate_helpers.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/app_search_bar.dart';
import 'package:utang_tracker/core/widgets/app_snackbar.dart';
import 'package:utang_tracker/core/widgets/app_text_field.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';
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
      unitPrice = TextEditingController();

  final TextEditingController product;
  final TextEditingController quantity;
  final TextEditingController unitPrice;

  void dispose() {
    product.dispose();
    quantity.dispose();
    unitPrice.dispose();
  }
}

class _DebtFormPageState extends ConsumerState<DebtFormPage> {
  String? _customerId;
  String? _customerName;
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

  Future<void> _pickCustomer() async {
    final selected = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => const _CustomerPickerSheet(),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _customerId = selected.id;
      _customerName = selected.name;
    });
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
      Money price;
      try {
        price = Money.fromPesoString(item.unitPrice.text);
      } catch (_) {
        setState(() => _error = 'Enter a valid price.');
        return null;
      }
      if (name.isEmpty || qty == null || qty <= 0 || !price.isPositive) {
        setState(
          () => _error =
              'Each item needs product name, quantity > 0, and price > 0.',
        );
        return null;
      }
      result.add(
        DebtItemInput(productName: name, quantity: qty, unitPrice: price),
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
        invalidateBusinessData(ref, customerId: _customerId, debtId: debt.id);
      }

      if (!mounted) return;
      AppSnackBar.success(
        context,
        widget.isEditing ? 'Debt updated' : 'Debt recorded',
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit debt' : 'New debt')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.labelLarge,
              children: const [
                TextSpan(text: 'Customer'),
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.danger),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CustomerField(
            name: _customerName,
            enabled: !widget.isEditing,
            onTap: _pickCustomer,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Date',
                  required: true,
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
              Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.titleMedium,
                  children: const [
                    TextSpan(text: 'Items'),
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _items.add(_LineItemControllers())),
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
                    const Divider(height: AppSpacing.lg),
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
                            hint: 'e.g. 2',
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
                          flex: 2,
                          child: AppTextField(
                            controller: item.unitPrice,
                            label: 'Price',
                            hint: 'e.g. 50.00',
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
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
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

class _CustomerField extends StatelessWidget {
  const _CustomerField({
    required this.name,
    required this.enabled,
    required this.onTap,
  });

  final String? name;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasName = name != null && name!.isNotEmpty;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          suffixIcon: Icon(
            enabled ? Icons.person_search_outlined : Icons.lock_outline,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
        child: Text(
          hasName ? name! : 'Select customer',
          style: TextStyle(
            color: hasName ? AppColors.textPrimary : AppColors.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _CustomerPickerSheet extends ConsumerStatefulWidget {
  const _CustomerPickerSheet();

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
    final height = MediaQuery.sizeOf(context).height * 0.75;
    final customers = _customers;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              0,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: Text(
              'Select customer',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: AppSearchBar(
              hintText: 'Search customer',
              onChanged: (value) {
                _query = value;
                _load(value);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildBody(customers)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.sm,
                AppSpacing.pagePadding,
                AppSpacing.md,
              ),
              child: TextButton.icon(
                onPressed: () async {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  await router.push('/customers/new');
                },
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add customer'),
              ),
            ),
          ),
        ],
      ),
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
            style: const TextStyle(color: AppColors.danger),
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
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      itemCount: customers.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final customer = customers[index];
        return ListTile(
          title: Text(customer.name),
          subtitle: customer.phone == null || customer.phone!.isEmpty
              ? null
              : Text(customer.phone!),
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
        Text.rich(
          TextSpan(
            style: Theme.of(context).textTheme.labelLarge,
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.danger),
                ),
            ],
          ),
        ),
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
