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
      // Cancellation during silent sign-in is not expected but treat as benign.
      if (_isCancellation(caughtError)) return null;
      _handleAuthError(caughtError);
      rethrow;
    }
  }

  /// Returns `null` when the user cancels or when a non-recoverable error
  /// occurs that has been wrapped in a typed exception and re-thrown.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      // signIn() returns null when the user cancels — not an error.
      if (account == null) return null;
      return account;
    } catch (caughtError) {
      // User explicitly cancelled via the system dialog.
      if (_isCancellation(caughtError)) return null;
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

  /// Returns `true` when the error represents an explicit user cancellation
  /// (`sign_in_canceled` PlatformException code).
  bool _isCancellation(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('sign_in_canceled');
  }

  void _handleAuthError(Object error) {
    final msg = error.toString().toLowerCase();

    // ── Configuration / developer errors ──────────────────────────────────
    // These indicate the OAuth client is misconfigured (SHA fingerprint
    // mismatch, google-services.json missing oauth_client, etc.).
    if (msg.contains('developer_error') ||
        msg.contains('apicode: 10') ||
        msg.contains('apicode:10') ||
        msg.contains('apiexception: 10') ||
        msg.contains('apiexception:10') ||
        msg.contains('12500') ||
        msg.contains('invalid_account')) {
      throw BackupException(
          'Sign-in failed — configuration error (DEVELOPER_ERROR). '
          'Check SHA fingerprint and google-services.json. '
          'See docs/SETUP.md §4.7 for troubleshooting. $error');
    }

    // ── Auth expired ──────────────────────────────────────────────────────
    if (msg.contains('401') ||
        msg.contains('invalid_grant') ||
        msg.contains('unauthenticated') ||
        (msg.contains('auth') && msg.contains('expired')) ||
        msg.contains('failed_to_recover_auth') ||
        msg.contains('user_recoverable_auth')) {
      throw AuthExpiredException(
          'Authentication expired, please sign in again. $error');
    }

    // ── Network errors ────────────────────────────────────────────────────
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('failed host lookup') ||
        msg.contains('network_error')) {
      throw NetworkException('No internet connection. $error');
    }

    // ── Sign-in failed (generic Google error, not config-specific) ────────
    if (msg.contains('sign_in_failed')) {
      throw BackupException(
          'Sign-in failed. This usually means the Google account is not '
          'available on the device or the app lacks permission. '
          'Try removing and re-adding the Google account in device Settings. '
          'See docs/SETUP.md §4.7. $error');
    }

    // ── Catch-all ─────────────────────────────────────────────────────────
    throw BackupException('Sign-in failed: $error');
  }
}
