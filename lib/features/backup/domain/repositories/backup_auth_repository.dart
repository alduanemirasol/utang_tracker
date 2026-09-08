import 'package:utang_tracker/features/backup/domain/entities/backup_connection_details.dart';

abstract class BackupAuthRepository {
  Future<BackupConnectionDetails> getConnectionDetails();
  Future<bool> isSignedIn();
  Future<String?> signIn();
  Future<void> signOut();
  Future<Map<String, String>> getAuthHeaders();
}
