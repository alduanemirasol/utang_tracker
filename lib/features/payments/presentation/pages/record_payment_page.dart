import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_time_display.dart';
import 'package:utang_tracker/core/utils/invalidate_helpers.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_modal_bottom_sheet.dart';
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
  String? _debtError;
  String? _amountError;
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
      _debtError = null;
      _amountError = null;
      _error = null;
    });
  }

  Future<void> _pickDebt() async {
    final selected = await showAppModalBottomSheet<Debt>(
      context: context,
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
    Money? amount;
    setState(() {
      _error = null;
      _debtError = _debtId == null ? 'Select utang para bayaran' : null;

      final amountText = _amountController.text.trim();
      if (amountText.isEmpty) {
        _amountError = 'Amount is required.';
        return;
      }
      try {
        final parsed = Money.fromPesoString(amountText);
        if (!parsed.isPositive) {
          _amountError = 'Amount must be greater than 0.';
          return;
        }
        amount = parsed;
        _amountError = null;
      } catch (_) {
        _amountError = 'Enter a valid amount.';
      }
    });
    if (_debtError != null || amount == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(recordPaymentUseCaseProvider)(
        debtId: _debtId!,
        amount: amount!,
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
      AppSnackBar.success(context, 'Bayad recorded');
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
        appBar: AppBar(title: const Text('Record bayad')),
        body: const LoadingIndicator(),
      );
    }

    final selected = _selectedDebt;

    return Scaffold(
      appBar: AppBar(title: const Text('Record bayad')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          AppTextField.buildLabel(context, 'Utang *'),
          const SizedBox(height: AppSpacing.sm),
          _DebtField(
            label: _debtFieldLabel,
            onTap: _pickDebt,
            errorText: _debtError,
          ),
          if (selected != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Remaining balance: ${selected.balance.format()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            errorText: _amountError,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],

            onChanged: (_) => setState(() {
              _amountError = null;
            }),
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
                context.smartDate(_paymentDate),
                style: AppTextField.inputStyle(context),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField.buildLabel(context, 'Payment method *'),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _method,
            style: AppTextField.inputStyle(context),
            items: AppConstants.paymentMethods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
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
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: 'Save', onPressed: _save, isLoading: _saving),
        ],
      ),
    );
  }
}

class _DebtField extends StatelessWidget {
  const _DebtField({required this.label, required this.onTap, this.errorText});

  final String? label;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null && label!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          errorText: errorText,
          suffixIcon: const Icon(
            Icons.receipt_long_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
        child: Text(
          hasLabel ? label! : 'Select utang',
          style: AppTextField.inputStyle(
            context,
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
    final debts = _debts;

    return AppModalBottomSheet(
      title: 'Select utang',
      headerBottom: AppSearchBar(
        hintText: 'Search by customer',
        onChanged: (value) {
          _query = value;
          _load(value);
        },
      ),
      child: _buildBody(debts),
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
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
            searching ? 'Walay utang match your search.' : 'Wala pay utang',
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
      itemCount: debts.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final debt = debts[index];
        return ListTile(
          title: Text(debt.customerName ?? 'Customer'),
          subtitle: Text(context.smartTimestamp(debt.transactionDate)),
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
