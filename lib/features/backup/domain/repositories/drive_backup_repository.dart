import 'dart:io';

import 'package:utang_tracker/features/backup/domain/entities/drive_backup_file.dart';

abstract class DriveBackupRepository {
  Future<List<DriveBackupFile>> listBackups();
  Future<void> uploadBackup(File file, String fileName);
  Future<File> downloadBackup(DriveBackupFile file);
}
