import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/domain/payment_method.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/presentation/app_button.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/core/presentation/app_confirm_dialog.dart';
import 'package:utang_tracker/core/presentation/app_date_field.dart';
import 'package:utang_tracker/core/presentation/app_dropdown_field.dart';
import 'package:utang_tracker/core/presentation/app_async_views.dart';
import 'package:utang_tracker/core/presentation/app_input.dart';
import 'package:utang_tracker/core/presentation/app_money_text.dart';
import 'package:utang_tracker/core/presentation/app_page_body.dart';
import 'package:utang_tracker/core/utils/app_responsive.dart';
import 'package:utang_tracker/core/utils/number_formatter.dart';
import 'package:utang_tracker/core/utils/snackbar_helper.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';
import 'package:utang_tracker/features/payments/presentation/providers/payment_providers.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  final String debtId;
  final String? paymentId;
  final double? prefillAmount;

  const PaymentFormScreen({
    super.key,
    required this.debtId,
    this.paymentId,
    this.prefillAmount,
  });

  bool get isEditing => paymentId != null;

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTimeHelper.now();
  PaymentMethod _method = PaymentMethod.cash;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  double _remainingBalance = 0;
  String _customerName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final debtResult =
        await ref.read(getDebtUseCaseProvider).execute(widget.debtId);
    if (debtResult case Success(data: final debt)) {
      _remainingBalance = debt.balance;
      final customers = ref.read(customerListProvider).asData?.value ?? [];
      final match = customers.where((c) => c.id == debt.customerId);
      if (match.isNotEmpty) {
        _customerName = match.first.name;
      } else {
        final customerResult = await ref
            .read(getCustomerUseCaseProvider)
            .execute(debt.customerId);
        if (customerResult case Success(data: final customer)) {
          _customerName = customer.name;
        }
      }
    }

    if (widget.isEditing) {
      final paymentResult = await ref
          .read(getPaymentUseCaseProvider)
          .execute(widget.paymentId!);
      switch (paymentResult) {
        case Success(data: final payment):
          _amountController.text = payment.amount.toStringAsFixed(
            payment.amount == payment.amount.roundToDouble() ? 0 : 2,
          );
          _paymentDate = payment.paymentDate;
          _method = payment.paymentMethod;
          _notesController.text = payment.notes ?? '';
        case Error():
          if (mounted) {
            context.showErrorSnackBar('Failed to load payment');
            context.pop();
          }
      }
    } else if (widget.prefillAmount != null && widget.prefillAmount! > 0) {
      _setAmount(widget.prefillAmount!);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _setAmount(double amount) {
    _amountController.text = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
  }

  Future<void> _pickDate() async {
    final now = DateTimeHelper.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      context.showErrorSnackBar('Enter a valid amount');
      return;
    }

    if (!widget.isEditing && amount > _remainingBalance + 0.001) {
      context.showErrorSnackBar(
        'Amount cannot be more than remaining balance',
      );
      return;
    }

    setState(() => _isSaving = true);

    final Result result;
    if (widget.isEditing) {
      result = await ref.read(updatePaymentUseCaseProvider).execute(
            id: widget.paymentId!,
            amount: amount,
            paymentDate: _paymentDate,
            paymentMethod: _method,
            notes: _notesController.text.isEmpty
                ? null
                : _notesController.text,
          );
    } else {
      result = await ref.read(createPaymentUseCaseProvider).execute(
            debtId: widget.debtId,
            amount: amount,
            paymentDate: _paymentDate,
            paymentMethod: _method,
            notes: _notesController.text.isEmpty
                ? null
                : _notesController.text,
          );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    switch (result) {
      case Success():
        _invalidateRelated();
        context.showSuccessSnackBar(
          widget.isEditing
              ? 'Payment updated successfully'
              : 'Payment recorded successfully',
        );
        context.pop();
      case Error(failure: final f):
        context.showErrorSnackBar(f.message);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Payment',
      message: 'This will permanently delete this payment record.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    final result =
        await ref.read(deletePaymentUseCaseProvider).execute(widget.paymentId!);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    switch (result) {
      case Success():
        _invalidateRelated();
        context.showSuccessSnackBar('Payment deleted');
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
    ref.invalidate(paymentListProvider(widget.debtId));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canUseFullBalance =
        !widget.isEditing && _remainingBalance > 0.001;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Payment' : 'Record Payment'),
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
                      if (_customerName.isNotEmpty || _remainingBalance > 0)
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_customerName.isNotEmpty)
                                Text(
                                  _customerName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.xl,
                                    fontWeight: AppFontWeights.semibold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.space5),
                              const Text(
                                'Remaining balance',
                                style: TextStyle(
                                  fontSize: AppFontSizes.sm,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.space1),
                              AppMoneyText(
                                amount: _remainingBalance,
                                size: AppMoneySize.lg,
                                color: _remainingBalance > 0
                                    ? AppColors.textPrimary
                                    : AppColors.success,
                              ),
                            ],
                          ),
                        ),
                      AppInput(
                        label: 'Amount',
                        controller: _amountController,
                        hintText: '0.00',
                        isRequired: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          final n = double.tryParse(value.trim());
                          if (n == null || n <= 0) {
                            return 'Enter an amount greater than 0';
                          }
                          return null;
                        },
                      ),
                      if (canUseFullBalance) ...[
                        const SizedBox(height: AppSpacing.space3),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              setState(() => _setAmount(_remainingBalance));
                            },
                            child: Text(
                              'Use full balance (${formatPeso(_remainingBalance)})',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.space7),
                      AppDateField(
                        label: 'Payment Date',
                        value: _paymentDate,
                        isRequired: true,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: AppSpacing.space7),
                      AppDropdownField<PaymentMethod>(
                        label: 'Payment Method',
                        value: _method,
                        isRequired: true,
                        items: PaymentMethod.values
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(_methodLabel(m)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _method = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.space7),
                      AppInput(
                        label: 'Notes',
                        controller: _notesController,
                        hintText: 'Optional notes',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.space10),
                      AppPrimaryButton(
                        label: widget.isEditing ? 'Save' : 'Record payment',
                        onPressed: _save,
                        isLoading: _isSaving,
                      ),
                      if (widget.isEditing) ...[
                        const SizedBox(height: AppSpacing.space5),
                        AppDestructiveButton(
                          label: 'Delete payment',
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

  String _methodLabel(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.gcash => 'GCash',
      PaymentMethod.maya => 'Maya',
    };
  }
}
