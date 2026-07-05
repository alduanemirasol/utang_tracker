import 'package:utang_tracker/core/errors/result.dart';
import 'dashboard_summary.dart';

abstract class DashboardRepository {
  Future<Result<DashboardSummary>> getSummary();
}
