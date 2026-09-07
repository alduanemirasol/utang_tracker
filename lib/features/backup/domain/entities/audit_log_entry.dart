import 'package:equatable/equatable.dart';
import 'package:utang_tracker/features/backup/domain/entities/audit_action.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_status.dart';

class AuditLogEntry extends Equatable {
  const AuditLogEntry({
    required this.timestamp,
    required this.action,
    required this.backupName,
    required this.status,
    this.error,
  });

  final DateTime timestamp;
  final AuditAction action;
  final String backupName;
  final BackupStatus status;
  final String? error;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'action': action.name,
        'backupName': backupName,
        'status': status.name,
        'error': error,
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        action: AuditAction.values.byName(json['action'] as String),
        backupName: json['backupName'] as String,
        status: BackupStatus.values.byName(json['status'] as String),
        error: json['error'] as String?,
      );

  @override
  List<Object?> get props => [timestamp, action, backupName, status, error];
}
