import 'dart:io';

import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:utang_tracker/features/backup/data/datasources/drive_api_client.dart';
import 'package:utang_tracker/features/backup/domain/entities/drive_backup_file.dart';
import 'package:utang_tracker/features/backup/domain/repositories/drive_backup_repository.dart';

class DriveBackupRepositoryImpl implements DriveBackupRepository {
  DriveBackupRepositoryImpl({
    required DriveApiClient driveApiClient,
    Future<Directory> Function()? temporaryDirectory,
  })  : _driveApiClient = driveApiClient,
        _temporaryDirectory =
            temporaryDirectory ?? path_provider.getTemporaryDirectory;

  final DriveApiClient _driveApiClient;
  final Future<Directory> Function() _temporaryDirectory;

  @override
  Future<List<DriveBackupFile>> listBackups() {
    return _driveApiClient.listBackups();
  }

  @override
  Future<void> uploadBackup(File file, String fileName) {
    return _driveApiClient.uploadBackup(file, fileName);
  }

  @override
  Future<File> downloadBackup(DriveBackupFile file) {
    return _driveApiClient.downloadBackup(file);
  }

  Future<Directory> getTemporaryDirectory() => _temporaryDirectory();
}
