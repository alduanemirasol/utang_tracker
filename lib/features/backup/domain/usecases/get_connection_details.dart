import 'package:utang_tracker/features/backup/domain/entities/backup_connection_details.dart';
import 'package:utang_tracker/features/backup/domain/repositories/backup_auth_repository.dart';

class GetConnectionDetails {
  const GetConnectionDetails(this._auth);

  final BackupAuthRepository _auth;

  Future<BackupConnectionDetails> call() => _auth.getConnectionDetails();

  Future<bool> isSignedIn() => _auth.isSignedIn();

  Future<String?> signIn() => _auth.signIn();

  Future<void> signOut() => _auth.signOut();
}
