import 'package:google_sign_in/google_sign_in.dart';
import 'package:utang_tracker/core/error/app_exception.dart';

class GoogleAuthDatasource {
  GoogleAuthDatasource({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['https://www.googleapis.com/auth/drive.file'],
            );

  final GoogleSignIn _googleSignIn;

  GoogleSignIn get googleSignIn => _googleSignIn;

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;

  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();

  Future<GoogleSignInAccount?> silentSignIn() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (caughtError) {
      _handleAuthError(caughtError);
      rethrow;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (caughtError) {
      _handleAuthError(caughtError);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (caughtError) {
      _handleAuthError(caughtError);
      rethrow;
    }
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final user = _googleSignIn.currentUser;
    if (user == null) {
      throw const AuthExpiredException('Not signed in. Please sign in again.');
    }
    try {
      final headers = await user.authHeaders;
      final auth = headers['Authorization'] ?? '';
      if (auth.isEmpty || auth.contains('null')) {
        throw const AuthExpiredException(
            'Authentication expired, please sign in again.');
      }
      return headers;
    } catch (caughtError) {
      _handleAuthError(caughtError);
      rethrow;
    }
  }

  void _handleAuthError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('401') ||
        msg.contains('invalid_grant') ||
        msg.contains('unauthenticated') ||
        msg.contains('auth') && msg.contains('expired') ||
        msg.contains('failed_to_recover_auth') ||
        msg.contains('user_recoverable_auth')) {
      throw AuthExpiredException(
          'Authentication expired, please sign in again. $error');
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('failed host lookup')) {
      throw NetworkException('No internet connection. $error');
    }
  }
}
