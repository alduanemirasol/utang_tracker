import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';

enum BalanceReminderStyle { concise, detailed }

class BalanceReminder {
  const BalanceReminder._();

  static String build({
    required String customerName,
    required Money outstandingBalance,
    required List<Debt> debts,
    required BalanceReminderStyle style,
    DateTime? now,
  }) {
    final activeDebts = debts.where((debt) => debt.balance.isPositive).toList()
      ..sort((a, b) {
        final aDate = a.dueDate ?? a.transactionDate;
        final bDate = b.dueDate ?? b.transactionDate;
        return aDate.compareTo(bDate);
      });
    final reference = (now ?? DateTime.now()).toLocal();
    final dueDate = activeDebts
        .where((debt) => debt.dueDate != null)
        .map((debt) => debt.dueDate!.toLocal())
        .firstOrNull;

    final buffer = StringBuffer(
      'Hi $customerName, friendly reminder: naa kay remaining balance nga '
      '${outstandingBalance.format()}',
    );
    if (dueDate != null) {
      final prefix = _isBeforeDay(dueDate, reference)
          ? ' overdue since '
          : ', due ';
      buffer.write('$prefix${DateFormatters.calendarDate(dueDate)}');
    }
    buffer.write('.');

    if (style == BalanceReminderStyle.detailed && activeDebts.isNotEmpty) {
      buffer.write('\n\nUtang details:');
      for (final debt in activeDebts) {
        buffer.write(
          '\n- ${DateFormatters.calendarDate(debt.transactionDate)}: '
          '${debt.balance.format()}',
        );
        if (debt.dueDate != null) {
          buffer.write(' (due ${DateFormatters.calendarDate(debt.dueDate!)})');
        }
      }
      buffer.write('\nTotal: ${outstandingBalance.format()}');
    }

    buffer.write('\n\nSalamat!');
    return buffer.toString();
  }

  static bool _isBeforeDay(DateTime value, DateTime reference) {
    final valueDay = DateTime(value.year, value.month, value.day);
    final referenceDay = DateTime(
      reference.year,
      reference.month,
      reference.day,
    );
    return valueDay.isBefore(referenceDay);
  }
}
