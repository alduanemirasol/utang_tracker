enum ActivityType { debt, payment }

class ActivityItem {
  final String id;
  final String debtId;
  final ActivityType type;
  final String customerName;
  final double amount;
  final DateTime date;
  final String statusLabel;

  const ActivityItem({
    required this.id,
    required this.debtId,
    required this.type,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.statusLabel,
  });
}

class UpcomingDueItem {
  final String debtId;
  final String customerName;
  final double balance;
  final DateTime dueDate;

  const UpcomingDueItem({
    required this.debtId,
    required this.customerName,
    required this.balance,
    required this.dueDate,
  });
}
