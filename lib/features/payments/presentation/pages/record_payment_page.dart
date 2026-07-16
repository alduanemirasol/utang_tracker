import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/utils/invalidate_helpers.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_search_bar.dart';
import 'package:utang_tracker/core/widgets/app_snackbar.dart';
import 'package:utang_tracker/core/widgets/app_text_field.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
import 'package:utang_tracker/core/widgets/status_badge.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_status.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';
import 'package:utang_tracker/features/payments/presentation/providers/payment_providers.dart';

class RecordPaymentPage extends ConsumerStatefulWidget {
  const RecordPaymentPage({super.key, this.initialDebtId});

  final String? initialDebtId;

  @override
  ConsumerState<RecordPaymentPage> createState() => _RecordPaymentPageState();
}

class _RecordPaymentPageState extends ConsumerState<RecordPaymentPage> {
  String? _debtId;
  Debt? _selectedDebt;
  final _amountController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _method = AppConstants.paymentMethods.first;
  final _notesController = TextEditingController();
  bool _saving = false;
  String? _error;
  bool _resolvingInitial = false;

  @override
  void initState() {
    super.initState();
    _debtId = widget.initialDebtId;
    if (widget.initialDebtId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveInitialDebt(widget.initialDebtId!);
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _resolveInitialDebt(String id) async {
    setState(() => _resolvingInitial = true);
    try {
      final detail = await ref.read(getDebtDetailProvider)(id);
      if (!mounted || detail == null) return;
      final debt = detail.debt;
      if (debt.status == DebtStatus.paid) {
        setState(() {
          _debtId = null;
          _selectedDebt = null;
          _resolvingInitial = false;
        });
        return;
      }
      _applyDebtSelection(debt);
    } finally {
      if (mounted) setState(() => _resolvingInitial = false);
    }
  }

  void _applyDebtSelection(Debt debt) {
    setState(() {
      _debtId = debt.id;
      _selectedDebt = debt;
      _amountController.text = debt.balance.pesos.toStringAsFixed(2);
      _error = null;
    });
  }

  Future<void> _pickDebt() async {
    final selected = await showModalBottomSheet<Debt>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => const _DebtPickerSheet(),
    );
    if (selected == null || !mounted) return;
    _applyDebtSelection(selected);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_debtId == null) {
      setState(() => _error = 'Select a debt to pay.');
      return;
    }

    Money amount;
    try {
      amount = Money.fromPesoString(_amountController.text);
    } catch (_) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(recordPaymentUseCaseProvider)(
        debtId: _debtId!,
        amount: amount,
        paymentDate: _paymentDate,
        paymentMethod: _method,
        notes: _notesController.text,
      );
      invalidateBusinessData(
        ref,
        customerId: _selectedDebt?.customerId,
        debtId: _debtId,
      );
      if (!mounted) return;
      AppSnackBar.success(context, 'Payment recorded');
      context.pop();
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? get _debtFieldLabel {
    final debt = _selectedDebt;
    if (debt == null) return null;
    final name = debt.customerName ?? 'Customer';
    return '$name - ${debt.balance.format()}';
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvingInitial && _selectedDebt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Record payment')),
        body: const LoadingIndicator(),
      );
    }

    final selected = _selectedDebt;

    return Scaffold(
      appBar: AppBar(title: const Text('Record payment')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          AppTextField.buildLabel(context, 'Debt *'),
          const SizedBox(height: AppSpacing.sm),
          _DebtField(label: _debtFieldLabel, onTap: _pickDebt),
          if (selected != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Remaining balance: ${selected.balance.format()}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _amountController,
            label: 'Amount *',
            hint: 'e.g. 100.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],

            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField.buildLabel(context, 'Payment date *'),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(
                DateFormatters.formatDate(_paymentDate),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField.buildLabel(context, 'Payment method *'),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _method,
            style: Theme.of(context).textTheme.bodyMedium,
            items: AppConstants.paymentMethods
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(
                      m,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _method = v);
            },
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _notesController,
            label: 'Notes',
            hint: 'Optional',
            minLines: 4,
            maxLines: 6,
          ),
          if (selected != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Text('Balance after payment approx.'),
                const Spacer(),
                Builder(
                  builder: (context) {
                    try {
                      final amt = Money.fromPesoString(_amountController.text);
                      final after = selected.balance - amt;
                      return MoneyText(after.isNegative ? Money.zero() : after);
                    } catch (_) {
                      return MoneyText(selected.balance);
                    }
                  },
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Save payment',
            onPressed: _save,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}

class _DebtField extends StatelessWidget {
  const _DebtField({required this.label, required this.onTap});

  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null && label!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(
            Icons.receipt_long_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
        child: Text(
          hasLabel ? label! : 'Select debt',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: hasLabel ? AppColors.textPrimary : AppColors.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _DebtPickerSheet extends ConsumerStatefulWidget {
  const _DebtPickerSheet();

  @override
  ConsumerState<_DebtPickerSheet> createState() => _DebtPickerSheetState();
}

class _DebtPickerSheetState extends ConsumerState<_DebtPickerSheet> {
  String _query = '';
  List<Debt>? _debts;
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
      final getDebts = ref.read(getDebtsProvider);
      final unpaid = await getDebts(status: DebtStatus.unpaid);
      final partial = await getDebts(status: DebtStatus.partial);
      final open = [...unpaid, ...partial]
        ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      final trimmed = query.trim().toLowerCase();
      final filtered = trimmed.isEmpty
          ? open
          : open
                .where(
                  (d) => (d.customerName ?? '').toLowerCase().contains(trimmed),
                )
                .toList();

      if (!mounted) return;
      setState(() {
        _debts = filtered;
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
    final debts = _debts;

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
              'Select debt',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: AppSearchBar(
              hintText: 'Search by customer',
              onChanged: (value) {
                _query = value;
                _load(value);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildBody(debts)),
        ],
      ),
    );
  }

  Widget _buildBody(List<Debt>? debts) {
    if (_loading && debts == null) {
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
    if (debts == null || debts.isEmpty) {
      final searching = _query.trim().isNotEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            searching
                ? 'No open debts match your search.'
                : 'No open debts to pay.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      itemCount: debts.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final debt = debts[index];
        return ListTile(
          title: Text(debt.customerName ?? 'Customer'),
          subtitle: Text(
            DateFormatters.formatDateTime(debt.transactionDate),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(debt.balance),
              const SizedBox(height: 4),
              StatusBadge(status: debt.status),
            ],
          ),
          onTap: () => Navigator.of(context).pop(debt),
        );
      },
    );
  }
}
