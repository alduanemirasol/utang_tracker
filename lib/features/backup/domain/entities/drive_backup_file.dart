import 'package:equatable/equatable.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class DriveBackupFile extends Equatable {
  const DriveBackupFile({
    required this.id,
    required this.name,
    this.createdTime,
    this.modifiedTime,
    this.sizeBytes,
    this.mimeType,
  });

  final String id;
  final String name;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
  final int? sizeBytes;
  final String? mimeType;

  factory DriveBackupFile.fromDriveFile(drive.File file) {
    return DriveBackupFile(
      id: file.id ?? '',
      name: file.name ?? 'backup.sqlite',
      createdTime: file.createdTime,
      modifiedTime: file.modifiedTime,
      sizeBytes: file.size == null ? null : int.tryParse(file.size!),
      mimeType: file.mimeType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        createdTime,
        modifiedTime,
        sizeBytes,
        mimeType,
      ];
}
