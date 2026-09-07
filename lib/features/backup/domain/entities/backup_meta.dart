import 'package:equatable/equatable.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_source.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_status.dart';

class BackupMeta extends Equatable {
  const BackupMeta({
    required this.id,
    required this.name,
    required this.createdTime,
    required this.sizeBytes,
    required this.status,
    required this.source,
    required this.hash,
  });

  final String id;
  final String name;
  final DateTime createdTime;
  final int sizeBytes;
  final BackupStatus status;
  final BackupSource source;
  final String hash;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdTime': createdTime.toIso8601String(),
        'sizeBytes': sizeBytes,
        'status': status.name,
        'source': source.name,
        'hash': hash,
      };

  factory BackupMeta.fromJson(Map<String, dynamic> json) => BackupMeta(
        id: json['id'] as String,
        name: json['name'] as String,
        createdTime: DateTime.parse(json['createdTime'] as String),
        sizeBytes: json['sizeBytes'] as int,
        status: BackupStatus.values.byName(json['status'] as String),
        source: BackupSource.values.byName(json['source'] as String),
        hash: json['hash'] as String,
      );

  @override
  List<Object?> get props => [id, name, createdTime, sizeBytes, status, source, hash];
}
