import 'package:equatable/equatable.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_source.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_status.dart';

class BackupHistoryEntry extends Equatable {
  const BackupHistoryEntry({
    required this.id,
    required this.backupName,
    required this.createdTime,
    required this.sizeBytes,
    required this.status,
    required this.source,
    required this.hash,
  });

  final String id;
  final String backupName;
  final DateTime createdTime;
  final int sizeBytes;
  final BackupStatus status;
  final BackupSource source;
  final String hash;

  Map<String, dynamic> toJson() => {
        'id': id,
        'backupName': backupName,
        'createdTime': createdTime.toIso8601String(),
        'sizeBytes': sizeBytes,
        'status': status.name,
        'source': source.name,
        'hash': hash,
      };

  factory BackupHistoryEntry.fromJson(Map<String, dynamic> json) => BackupHistoryEntry(
        id: json['id'] as String,
        backupName: json['backupName'] as String,
        createdTime: DateTime.parse(json['createdTime'] as String),
        sizeBytes: json['sizeBytes'] as int,
        status: BackupStatus.values.byName(json['status'] as String),
        source: BackupSource.values.byName(json['source'] as String),
        hash: json['hash'] as String,
      );

  @override
  List<Object?> get props => [id, backupName, createdTime, sizeBytes, status, source, hash];
}
