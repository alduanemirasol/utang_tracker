import 'package:equatable/equatable.dart';
import 'package:utang_tracker/core/domain/money.dart';

enum DebtReminderKind { overdue, dueToday }

class DebtReminder extends Equatable {
  const DebtReminder({
    required this.debtId,
    required this.customerName,
    required this.balance,
    required this.kind,
    required this.scheduledDate,
  });

  final String debtId;
  final String customerName;
  final Money balance;
  final DebtReminderKind kind;
  final DateTime scheduledDate;

  String get title =>
      kind == DebtReminderKind.overdue ? 'Overdue utang' : 'Due today';

  String get body => '$customerName - ${balance.format()}';

  @override
  List<Object?> get props => [
    debtId,
    customerName,
    balance,
    kind,
    scheduledDate,
  ];
}