enum ActivityType { debt, payment }

class ActivityItem {
  final String id;
  final ActivityType type;
  final String customerName;
  final double amount;
  final DateTime date;
  final String statusLabel;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.statusLabel,
  });
}
