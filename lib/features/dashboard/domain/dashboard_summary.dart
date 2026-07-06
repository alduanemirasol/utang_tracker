import 'activity_item.dart';

class DashboardSummary {
  final double totalOutstandingBalance;
  final double totalCollected;
  final int activeDebtCount;
  final int totalCustomers;
  final List<ActivityItem> recentActivity;

  const DashboardSummary({
    required this.totalOutstandingBalance,
    required this.totalCollected,
    required this.activeDebtCount,
    required this.totalCustomers,
    required this.recentActivity,
  });
}
