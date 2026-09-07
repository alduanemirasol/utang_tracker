import 'package:utang_tracker/features/backup/domain/entities/audit_log_entry.dart';

abstract class AuditLogRepository {
  Future<List<AuditLogEntry>> getEntries();
  Future<void> addEntry(AuditLogEntry entry);
  Future<void> clear();
}
