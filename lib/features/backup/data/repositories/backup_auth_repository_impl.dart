import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/features/backup/data/datasources/google_auth_datasource.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_connection_details.dart';
import 'package:utang_tracker/features/backup/domain/repositories/backup_auth_repository.dart';

class BackupAuthRepositoryImpl implements BackupAuthRepository {
  BackupAuthRepositoryImpl({GoogleAuthDatasource? auth}) : _auth = auth ?? GoogleAuthDatasource();

  final GoogleAuthDatasource _auth;

  @override
  Future<BackupConnectionDetails> getConnectionDetails() async {
    final signedIn = await _auth.isSignedIn();
    if (!signedIn) {
      return const BackupConnectionDetails(status: BackupConnectionStatus.signedOut);
    }
    try {
      await _auth.getAuthHeaders();
      final email = _auth.currentUser?.email ?? 'Signed in';
      return BackupConnectionDetails(status: BackupConnectionStatus.signedIn, email: email);
    } catch (caughtError) {
      if (caughtError is AuthExpiredException) {
        return const BackupConnectionDetails(status: BackupConnectionStatus.expired);
      }
      // For network or other errors, we know the user was signed in from
      // isSignedIn() above — return signedIn with whatever email is available.
      return BackupConnectionDetails(
        status: BackupConnectionStatus.signedIn,
        email: _auth.currentUser?.email,
      );
    }
  }

  @override
  Future<bool> isSignedIn() => _auth.isSignedIn();

  @override
  Future<String?> signIn() async {
    final account = await _auth.signIn();
    return account?.email;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<Map<String, String>> getAuthHeaders() => _auth.getAuthHeaders();
}
