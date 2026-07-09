import 'activity_item.dart';

class DashboardSummary {
  final double totalOutstandingBalance;
  final double totalCollected;
  final double totalDebtAmount;
  final int activeDebtCount;
  final int totalCustomers;
  final int overdueCount;
  final double overdueAmount;
  final List<UpcomingDueItem> upcomingDues;
  final List<ActivityItem> recentPayments;
  final List<ActivityItem> recentActivity;

  const DashboardSummary({
    required this.totalOutstandingBalance,
    required this.totalCollected,
    required this.totalDebtAmount,
    required this.activeDebtCount,
    required this.totalCustomers,
    required this.overdueCount,
    required this.overdueAmount,
    required this.upcomingDues,
    required this.recentPayments,
    required this.recentActivity,
  });
}
