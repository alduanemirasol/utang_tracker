import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_modal_bottom_sheet.dart';
import 'package:utang_tracker/core/widgets/app_snackbar.dart';
import 'package:utang_tracker/core/widgets/app_text_field.dart';
import 'package:utang_tracker/features/customers/domain/usecases/get_customer_detail.dart';
import 'package:utang_tracker/features/notifications/domain/entities/balance_reminder.dart';

Future<void> showBalanceReminderSheet({
  required BuildContext context,
  required CustomerDetailData data,
}) {
  return showAppModalBottomSheet<void>(
    context: context,
    builder: (_) => _BalanceReminderSheet(data: data),
  );
}

class _BalanceReminderSheet extends StatefulWidget {
  const _BalanceReminderSheet({required this.data});

  final CustomerDetailData data;

  @override
  State<_BalanceReminderSheet> createState() => _BalanceReminderSheetState();
}

class _BalanceReminderSheetState extends State<_BalanceReminderSheet> {
  late final TextEditingController _controller;
  var _style = BalanceReminderStyle.concise;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _messageFor(_style));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _messageFor(BalanceReminderStyle style) => BalanceReminder.build(
    customerName: widget.data.customer.name,
    outstandingBalance: widget.data.outstandingBalance,
    debts: widget.data.debts,
    style: style,
  );

  void _changeStyle(Set<BalanceReminderStyle> selection) {
    final style = selection.first;
    setState(() {
      _style = style;
      _controller.text = _messageFor(style);
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _controller.text.trim()));
    if (!mounted) return;
    AppSnackBar.success(context, 'Reminder copied');
  }

  Future<void> _share() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: message));
  }

  @override
  Widget build(BuildContext context) {
    return AppModalBottomSheet(
      title: 'Send balance reminder',
      subtitle: 'Preview and edit before sharing.',
      heightFactor: 0.8,
      headerBottom: SegmentedButton<BalanceReminderStyle>(
        segments: const [
          ButtonSegment(
            value: BalanceReminderStyle.concise,
            label: Text('Concise'),
          ),
          ButtonSegment(
            value: BalanceReminderStyle.detailed,
            label: Text('Detailed'),
          ),
        ],
        selected: {_style},
        onSelectionChanged: _changeStyle,
      ),
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Copy',
              icon: Icons.copy_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: _copy,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton(
              label: 'Share',
              icon: Icons.share_outlined,
              onPressed: _share,
            ),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        child: AppTextField(
          key: const Key('balance-reminder-message'),
          controller: _controller,
          label: 'Message',
          minLines: 7,
          maxLines: 14,
          keyboardType: TextInputType.multiline,
        ),
      ),
    );
  }
}
