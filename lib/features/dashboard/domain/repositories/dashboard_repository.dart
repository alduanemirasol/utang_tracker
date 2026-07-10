import 'package:utang_tracker/features/dashboard/domain/entities/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> getSummary();
}
