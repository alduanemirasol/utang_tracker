import 'package:utang_tracker/features/reports/domain/entities/collection_period.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_report.dart';

abstract class ReportRepository {
  Future<CollectionReport> getCollectionReport({
    required CollectionPeriod period,
    required DateTime now,
  });
}