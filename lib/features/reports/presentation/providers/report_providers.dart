import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_period.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_report.dart';
import 'package:utang_tracker/features/reports/domain/usecases/get_collection_report.dart';

final getCollectionReportProvider = Provider((ref) {
  return GetCollectionReport(ref.watch(reportRepositoryProvider));
});

final collectionReportProvider =
    FutureProvider.family<CollectionReport, CollectionPeriod>((ref, period) {
  return ref.watch(getCollectionReportProvider)(period);
});