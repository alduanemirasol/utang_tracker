// ignore_for_file: unnecessary_cast
import 'dart:io';
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_prefs_keys.dart';
import 'package:utang_tracker/features/backup/data/datasources/google_auth_datasource.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_meta.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_source.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_status.dart';
import 'package:utang_tracker/features/backup/domain/entities/storage_quota.dart';

class GoogleDriveService {
  GoogleDriveService({
    required GoogleAuthDatasource auth,
    http.Client? httpClient,
    drive.DriveApi? driveApi,
    SharedPreferences? prefs,
  })  : _auth = auth,
        _httpClient = httpClient,
        _driveApiOverride = driveApi,
        _prefsOverride = prefs;

  final GoogleAuthDatasource _auth;
  final http.Client? _httpClient;
  final drive.DriveApi? _driveApiOverride;
  final SharedPreferences? _prefsOverride;

  static const String folderName = 'utang_tracker_backup';
  static const String folderMimeType = 'application/vnd.google-apps.folder';

  Future<SharedPreferences> _getPrefs() async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  Future<drive.DriveApi> _getDriveApi() async {
    if (_driveApiOverride != null) return _driveApiOverride;
    final headers = await _auth.getAuthHeaders();
    final client = _httpClient ?? http.Client();
    final authClient = _AuthenticatedHttpClient(client, headers);
    return drive.DriveApi(authClient);
  }

  Future<String> ensureFolderId() async {
    final prefs = await _getPrefs();
    final stored = prefs.getString(BackupPrefsKeys.driveFolderId);
    if (stored != null && stored.isNotEmpty) {
      try {
        final api = await _getDriveApi();
        final f = await api.files.get(
          stored,
          $fields: 'id,name,mimeType,trashed',
        ) as drive.File;
        if (f.id != null && f.trashed != true) {
          return stored;
        }
      } catch (e) {
        if (!_isNotFound(e)) {
          _handleDriveError(e);
        }
      }
      await prefs.remove(BackupPrefsKeys.driveFolderId);
    }
    return _findOrCreateFolder();
  }

  Future<String> _findOrCreateFolder() async {
    final api = await _getDriveApi();
    try {
      final result = await api.files.list(
        q: "mimeType = '$folderMimeType' and name = '$folderName' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id,name,mimeType,owners,trashed)',
      );
      final files = result.files ?? [];
      for (final f in files) {
        if (f.id == null) continue;
        if (f.trashed == true) continue;
        final owners = f.owners;
        if (owners != null && owners.isNotEmpty) {
          final me = owners.any((o) => o.me == true);
          if (!me) continue;
        }
        final prefs = await _getPrefs();
        await prefs.setString(BackupPrefsKeys.driveFolderId, f.id!);
        return f.id!;
      }
    } catch (e) {
      _handleDriveError(e);
    }
    try {
      final folder = drive.File()
        ..name = folderName
        ..mimeType = folderMimeType;
      final created = await api.files.create(
        folder,
        $fields: 'id',
      ) as drive.File;
      final id = created.id;
      if (id == null || id.isEmpty) {
        throw const BackupException('Failed to create Drive folder.');
      }
      final prefs = await _getPrefs();
      await prefs.setString(BackupPrefsKeys.driveFolderId, id);
      return id;
    } catch (e) {
      _handleDriveError(e);
      rethrow;
    }
  }

  Future<List<BackupMeta>> listBackupsInFolder() async {
    final folderId = await ensureFolderId();
    final api = await _getDriveApi();
    try {
      final result = await api.files.list(
        q: "'$folderId' in parents and trashed = false",
        orderBy: 'createdTime desc',
        spaces: 'drive',
        $fields: 'files(id,name,size,createdTime,appProperties)',
      );
      final files = result.files ?? [];
      return files.where((f) => f.id != null).map((f) {
        final size = f.size == null ? 0 : int.tryParse(f.size!) ?? 0;
        final created = f.createdTime ?? DateTime.now();
        final hash = f.appProperties?['sha256'] ?? '';
        return BackupMeta(
          id: f.id!,
          name: f.name ?? 'backup.zip',
          createdTime: created,
          sizeBytes: size,
          status: BackupStatus.success,
          source: BackupSource.manual,
          hash: hash,
        );
      }).toList();
    } catch (e) {
      _handleDriveError(e);
      rethrow;
    }
  }

  Future<drive.File> uploadFile(
    File zipFile,
    String fileName,
    String folderId,
    String sha256Hash,
  ) async {
    final api = await _getDriveApi();
    try {
      final media = drive.Media(zipFile.openRead(), await zipFile.length());
      final file = drive.File()
        ..name = fileName
        ..parents = [folderId]
        ..appProperties = {'sha256': sha256Hash};
      final created = await api.files.create(
        file,
        uploadMedia: media,
        $fields: 'id,name,size,createdTime,appProperties',
      ) as drive.File;
      return created;
    } catch (e) {
      _handleDriveError(e);
      rethrow;
    }
  }

  Future<void> downloadFile(
    String fileId,
    File destination, {
    void Function(double progress)? onProgress,
  }) async {
    final api = await _getDriveApi();
    try {
      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      final sink = destination.openWrite();
      int received = 0;
      final total = media.length ?? 0;
      try {
        await for (final chunk in media.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (onProgress != null && total > 0) {
            onProgress(received / total);
          }
        }
      } finally {
        await sink.close();
      }
      if (onProgress != null) onProgress(1.0);
    } catch (e) {
      _handleDriveError(e);
      rethrow;
    }
  }

  Future<Uint8List> downloadBytes(String fileId) async {
    final api = await _getDriveApi();
    try {
      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      return Uint8List.fromList(bytes);
    } catch (e) {
      _handleDriveError(e);
      rethrow;
    }
  }

  Future<StorageQuota> getStorageQuota() async {
    final api = await _getDriveApi();
    try {
      final about = await api.about.get(
        $fields: 'storageQuota',
      ) as drive.About;
      final q = about.storageQuota;
      final used = q?.usage == null ? 0 : int.tryParse(q!.usage!) ?? 0;
      final limit = q?.limit == null ? null : int.tryParse(q!.limit!);
      final available =
          limit == null ? null : (limit - used).clamp(0, limit);
      return StorageQuota(
        usedBytes: used,
        totalBytes: limit,
        availableBytes: available,
      );
    } catch (e) {
      _handleDriveError(e);
      rethrow;
    }
  }

  Future<int> sumFolderSizes() async {
    final metas = await listBackupsInFolder();
    return metas.fold<int>(0, (sum, m) => sum + m.sizeBytes);
  }

  Future<void> deleteFile(String fileId) async {
    final api = await _getDriveApi();
    try {
      await api.files.delete(fileId);
    } catch (e) {
      _handleDriveError(e);
      rethrow;
    }
  }

  bool _isNotFound(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('404') || msg.contains('not found');
  }

  void _handleDriveError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') ||
        msg.contains('invalid_grant') ||
        msg.contains('unauthenticated')) {
      throw AuthExpiredException('Authentication expired, please sign in again. $e');
    }
    if (msg.contains('404') && msg.contains('file not found')) {
      throw NotFoundException('Drive file not found. $e');
    }
  }
}

class _AuthenticatedHttpClient extends http.BaseClient {
  _AuthenticatedHttpClient(this._inner, this._headers);

  final http.Client _inner;
  final Map<String, String> _headers;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
