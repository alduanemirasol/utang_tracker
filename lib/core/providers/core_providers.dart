import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:utang_tracker/features/customers/domain/repositories/customer_repository.dart';
import 'package:utang_tracker/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:utang_tracker/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:utang_tracker/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:utang_tracker/features/debts/domain/repositories/debt_repository.dart';
import 'package:utang_tracker/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:utang_tracker/features/payments/domain/repositories/payment_repository.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_local_datasource.dart';
import 'package:utang_tracker/features/backup/data/datasources/google_auth_datasource.dart';
import 'package:utang_tracker/features/backup/data/datasources/google_drive_service.dart';
import 'package:utang_tracker/features/backup/data/repositories/audit_log_repository_impl.dart';
import 'package:utang_tracker/features/backup/data/repositories/backup_history_repository_impl.dart';
import 'package:utang_tracker/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:utang_tracker/features/backup/domain/repositories/audit_log_repository.dart';
import 'package:utang_tracker/features/backup/domain/repositories/backup_history_repository.dart';
import 'package:utang_tracker/features/backup/domain/repositories/backup_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:utang_tracker/features/backup/data/services/backup_queue_service.dart';
import 'package:utang_tracker/features/backup/data/services/backup_scheduler.dart';
import 'package:utang_tracker/features/updater/data/repositories/update_repository_impl.dart';
import 'package:utang_tracker/features/updater/domain/repositories/update_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl(ref.watch(databaseProvider));
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(ref.watch(databaseProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.watch(databaseProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    customers: ref.watch(customerRepositoryProvider),
    debts: ref.watch(debtRepositoryProvider),
    payments: ref.watch(paymentRepositoryProvider),
  );
});

final updateRepositoryProvider = Provider<UpdateRepository>(
  (_) => UpdateRepositoryImpl(),
);

final backupLocalDatasourceProvider = Provider<BackupLocalDatasource>((_) {
  return BackupLocalDatasource();
});

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepositoryImpl(ref.watch(backupLocalDatasourceProvider));
});

final backupHistoryRepositoryProvider = Provider<BackupHistoryRepository>((ref) {
  return BackupHistoryRepositoryImpl(ref.watch(backupLocalDatasourceProvider));
});

final googleAuthDatasourceProvider = Provider<GoogleAuthDatasource>((_) {
  return GoogleAuthDatasource();
});

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService(auth: ref.watch(googleAuthDatasourceProvider));
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepositoryImpl(
    database: ref.watch(databaseProvider),
    auth: ref.watch(googleAuthDatasourceProvider),
    driveService: ref.watch(googleDriveServiceProvider),
    localDatasource: ref.watch(backupLocalDatasourceProvider),
  );
});

final backupConnectionStatusProvider = FutureProvider<bool>((ref) async {
  return ref.watch(googleAuthDatasourceProvider).isSignedIn();
});

final backupQuotaProvider = FutureProvider((ref) async {
  return ref.watch(backupRepositoryProvider).getQuota();
});

final backupSchedulerProvider = Provider<BackupScheduler>((_) {
  return BackupScheduler();
});

final connectivityProvider = Provider<Connectivity>((_) {
  return Connectivity();
});

final backupQueueServiceProvider = Provider<BackupQueueService>((_) {
  return BackupQueueService();
});
