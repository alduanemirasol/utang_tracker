import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:utang_tracker/core/constants/app_constants.dart';

class GoogleAuthDataSource {
  GoogleAuthDataSource({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(scopes: AppConstants.driveScopes);

  final GoogleSignIn _googleSignIn;

  GoogleSignIn get googleSignIn => _googleSignIn;

  Future<GoogleSignInAccount?> signInSilently() {
    return _googleSignIn.signInSilently();
  }

  Future<GoogleSignInAccount?> signIn() {
    return _googleSignIn.signIn();
  }

  Future<void> signOut() {
    return _googleSignIn.signOut();
  }

  Future<void> disconnect() {
    return _googleSignIn.disconnect();
  }

  Future<bool> isSignedIn() {
    return _googleSignIn.isSignedIn();
  }

  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<auth.AuthClient?> authenticatedClient() {
    return _googleSignIn.authenticatedClient();
  }
}
