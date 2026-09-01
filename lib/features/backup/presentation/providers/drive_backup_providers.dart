import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:path_provider/path_provider.dart';
import 'package:utang_tracker/features/backup/data/datasources/drive_api_client.dart';
import 'package:utang_tracker/features/backup/data/datasources/google_auth_datasource.dart';
import 'package:utang_tracker/features/backup/data/repositories/drive_backup_repository_impl.dart';
import 'package:utang_tracker/features/backup/domain/entities/drive_backup_file.dart';
import 'package:utang_tracker/features/backup/domain/exceptions/drive_exception.dart';
import 'package:utang_tracker/features/backup/domain/repositories/drive_backup_repository.dart';

final googleAuthDataSourceProvider = Provider<GoogleAuthDataSource>((ref) {
  return GoogleAuthDataSource();
});

/// Awaits silent sign-in once at startup. Errors are mapped via
/// [DriveErrorMapper] so callers see a [DriveException].
final googleAuthInitProvider =
    FutureProvider<GoogleSignInAccount?>((ref) async {
  final dataSource = ref.watch(googleAuthDataSourceProvider);
  try {
    return await dataSource.signInSilently();
  } catch (e) {
    throw DriveErrorMapper.fromError(e);
  }
});

/// Emits Google sign-in state changes. No side-effects.
final googleAuthNotifierProvider =
    StreamProvider<GoogleSignInAccount?>((ref) {
  final dataSource = ref.watch(googleAuthDataSourceProvider);
  // Trigger one-time silent sign-in; errors are exposed via
  // googleAuthInitProvider / authenticatedClientProvider using
  // DriveErrorMapper, not swallowed here.
  ref.watch(googleAuthInitProvider);
  return dataSource.onCurrentUserChanged;
});

/// Injectable temporary directory seam for Drive download/upload.
/// Override in tests to avoid touching the real filesystem.
final driveTemporaryDirectoryProvider =
    Provider<Future<Directory> Function()>((ref) => getTemporaryDirectory);

final authenticatedClientProvider =
    FutureProvider<auth.AuthClient?>((ref) async {
  final dataSource = ref.watch(googleAuthDataSourceProvider);
  // Ensure silent sign-in has been attempted once before checking state.
  // Errors are already mapped in googleAuthInitProvider; re-map just in case.
  try {
    await ref.watch(googleAuthInitProvider.future);
  } catch (e) {
    throw DriveErrorMapper.fromError(e);
  }
  // Rebuild when sign-in state changes via stream.
  ref.watch(googleAuthNotifierProvider);
  final signedIn = await dataSource.isSignedIn();
  if (!signedIn) return null;
  try {
    final client = await dataSource.authenticatedClient();
    if (client != null) {
      ref.onDispose(() => client.close());
    }
    return client;
  } catch (e) {
    throw DriveErrorMapper.fromError(e);
  }
});

final driveApiProvider = FutureProvider<drive.DriveApi?>((ref) async {
  final client = await ref.watch(authenticatedClientProvider.future);
  if (client == null) return null;
  return drive.DriveApi(client);
});

final driveApiClientProvider = FutureProvider<DriveApiClient?>((ref) async {
  final api = await ref.watch(driveApiProvider.future);
  if (api == null) return null;
  final tempDir = ref.watch(driveTemporaryDirectoryProvider);
  return DriveApiClient(driveApi: api, temporaryDirectory: tempDir);
});

final driveBackupRepositoryProvider =
    FutureProvider<DriveBackupRepository?>((ref) async {
  final client = await ref.watch(driveApiClientProvider.future);
  if (client == null) return null;
  final tempDir = ref.watch(driveTemporaryDirectoryProvider);
  return DriveBackupRepositoryImpl(
    driveApiClient: client,
    temporaryDirectory: tempDir,
  );
});

final driveBackupsProvider =
    FutureProvider<List<DriveBackupFile>>((ref) async {
  final repo = await ref.watch(driveBackupRepositoryProvider.future);
  if (repo == null) {
    throw const DriveException('Not signed in to Google Drive.');
  }
  return repo.listBackups();
});
