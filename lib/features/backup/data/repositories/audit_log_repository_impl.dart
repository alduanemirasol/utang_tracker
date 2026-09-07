import 'package:utang_tracker/features/backup/data/datasources/backup_local_datasource.dart';
import 'package:utang_tracker/features/backup/domain/entities/audit_log_entry.dart';
import 'package:utang_tracker/features/backup/domain/repositories/audit_log_repository.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  AuditLogRepositoryImpl(this._datasource);

  final BackupLocalDatasource _datasource;

  @override
  Future<List<AuditLogEntry>> getEntries() => _datasource.loadAuditLog();

  @override
  Future<void> addEntry(AuditLogEntry entry) => _datasource.appendAuditLog(entry);

  @override
  Future<void> clear() => _datasource.clearAuditLog();
}
