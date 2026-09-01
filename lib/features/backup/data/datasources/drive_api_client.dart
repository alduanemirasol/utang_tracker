import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/features/backup/domain/entities/drive_backup_file.dart';
import 'package:utang_tracker/features/backup/domain/exceptions/drive_exception.dart';

class DriveApiClient {
  DriveApiClient({
    required drive.DriveApi driveApi,
    Future<Directory> Function()? temporaryDirectory,
  })  : _driveApi = driveApi,
        _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final drive.DriveApi _driveApi;
  final Future<Directory> Function() _temporaryDirectory;

  factory DriveApiClient.fromAuthClient(
    auth.AuthClient client, {
    Future<Directory> Function()? temporaryDirectory,
  }) {
    return DriveApiClient(
      driveApi: drive.DriveApi(client),
      temporaryDirectory: temporaryDirectory,
    );
  }

  Future<List<DriveBackupFile>> listBackups() async {
    try {
      final result = await _driveApi.files.list(
        q: AppConstants.driveQuery,
        spaces: 'drive',
        orderBy: 'modifiedTime desc',
        pageSize: 100,
        $fields: 'files(id, name, createdTime, modifiedTime, size, mimeType)',
      );
      final files = result.files ?? <drive.File>[];
      return files
          .where((f) => f.id != null && f.id!.isNotEmpty)
          .map(DriveBackupFile.fromDriveFile)
          .toList();
    } catch (e) {
      throw DriveErrorMapper.fromError(e);
    }
  }

  Future<void> uploadBackup(File file, String fileName) async {
    try {
      final media = drive.Media(file.openRead(), await file.length());
      final driveFile = drive.File()
        ..name = fileName
        ..mimeType = AppConstants.driveBackupMimeType;
      await _driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );
    } catch (e) {
      throw DriveErrorMapper.fromError(e);
    }
  }

  Future<File> downloadBackup(DriveBackupFile file) async {
    if (file.id.isEmpty) {
      throw const DriveException('Missing Drive file id.');
    }
    File? tempFile;
    IOSink? sink;
    try {
      final media = await _driveApi.files.get(
        file.id,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dir = await _temporaryDirectory();
      await dir.create(recursive: true);
      tempFile = File(p.join(dir.path, 'drive-download-${file.id}.sqlite'));
      if (await tempFile.exists()) await tempFile.delete();

      sink = tempFile.openWrite();
      try {
        await for (final chunk in media.stream) {
          sink.add(chunk);
        }
      } finally {
        await sink.close();
        sink = null;
      }
      return tempFile;
    } catch (e) {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (tempFile != null) {
        try {
          if (await tempFile.exists()) await tempFile.delete();
        } catch (_) {}
      }
      if (e is DriveException) rethrow;
      throw DriveErrorMapper.fromError(e);
    }
  }
}
