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
import 'package:utang_tracker/core/widgets/app_text_field.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
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
  final _amountController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _method = AppConstants.paymentMethods.first;
  final _notesController = TextEditingController();
  bool _saving = false;
  String? _error;
  bool _amountPrefillDone = false;

  @override
  void initState() {
    super.initState();
    _debtId = widget.initialDebtId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _save(Debt? selectedDebt) async {
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
        customerId: selectedDebt?.customerId,
        debtId: _debtId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded')),
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

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(debtsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Record payment')),
      body: debtsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (allDebts) {
          final openDebts = allDebts
              .where((d) => d.status != DebtStatus.paid)
              .toList();

          Debt? selected;
          if (_debtId != null) {
            selected = openDebts.cast<Debt?>().firstWhere(
                  (d) => d?.id == _debtId,
                  orElse: () => allDebts.cast<Debt?>().firstWhere(
                        (d) => d?.id == _debtId,
                        orElse: () => null,
                      ),
                );
          }

          if (selected != null &&
              selected.status != DebtStatus.paid &&
              !_amountPrefillDone &&
              _amountController.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _amountController.text =
                    selected!.balance.pesos.toStringAsFixed(2);
                _amountPrefillDone = true;
              });
            });
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              Text('Debt *', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              if (openDebts.isEmpty)
                const Text(
                  'No open debts to pay.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: openDebts.any((d) => d.id == _debtId) ? _debtId : null,
                  items: openDebts
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(
                            '${d.customerName ?? 'Customer'} · ${d.balance.format()}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _debtId = v;
                      _amountPrefillDone = false;
                      final debt = openDebts.firstWhere((d) => d.id == v);
                      _amountController.text =
                          debt.balance.pesos.toStringAsFixed(2);
                      _amountPrefillDone = true;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Select debt',
                  ),
                ),
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Payment date *',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  child: Text(DateFormatters.formatDate(_paymentDate)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Payment method *',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _method,
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
                maxLines: 2,
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
                          final amt =
                              Money.fromPesoString(_amountController.text);
                          final after = selected!.balance - amt;
                          return MoneyText(
                            after.isNegative ? Money.zero() : after,
                          );
                        } catch (_) {
                          return MoneyText(selected!.balance);
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
                onPressed: openDebts.isEmpty ? null : () => _save(selected),
                isLoading: _saving,
              ),
            ],
          );
        },
      ),
    );
  }
}
