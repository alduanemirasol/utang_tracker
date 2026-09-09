import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/error/backup_error_mapper.dart';
import 'package:utang_tracker/features/backup/data/datasources/google_auth_datasource.dart';
import 'package:utang_tracker/features/backup/data/repositories/backup_auth_repository_impl.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_connection_details.dart';

// ---------------------------------------------------------------------------
// Minimal fakes — no native Google Sign-In calls in tests.
// ---------------------------------------------------------------------------

/// Fake [GoogleSignIn] that never hits native code.
class _FakeGoogleSignIn extends GoogleSignIn {
  _FakeGoogleSignIn({this.throwOnSignIn});

  /// If non-null, [signIn] will throw this.
  final Object? throwOnSignIn;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (throwOnSignIn != null) throw throwOnSignIn!;
    return null;
  }

  @override
  Future<GoogleSignInAccount?> signInSilently({
    bool reAuthenticate = false,
    bool suppressErrors = true,
  }) async => null;

  @override
  Future<GoogleSignInAccount?> signOut() async => null;

  // ignore: non_constant_identifier_names
  bool isSignedIn_sync() => false;

  @override
  GoogleSignInAccount? get currentUser => null;

  @override
  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      const Stream.empty();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -----------------------------------------------------------------------
  // BackupAuthRepositoryImpl.signIn — direct mock bypassing _handleAuthError
  // -----------------------------------------------------------------------
  group('BackupAuthRepositoryImpl.signIn (via mock repo)', () {
    test('returns null when GoogleSignIn returns null (user cancels)', () async {
      final repo = BackupAuthRepositoryImpl(
        auth: GoogleAuthDatasource(googleSignIn: _FakeGoogleSignIn()),
      );
      final email = await repo.signIn();
      expect(email, isNull);
    });

    test('propagates NetworkException from datasource', () async {
      final repo = BackupAuthRepositoryImpl(
        auth: _MockAuthDatasource(
          signInError: const NetworkException('No internet connection.'),
        ),
      );
      expect(() => repo.signIn(), throwsA(isA<NetworkException>()));
    });

    test('propagates AuthExpiredException from datasource', () async {
      final repo = BackupAuthRepositoryImpl(
        auth: _MockAuthDatasource(
          signInError: const AuthExpiredException('Token expired.'),
        ),
      );
      expect(() => repo.signIn(), throwsA(isA<AuthExpiredException>()));
    });

    test('propagates BackupException from datasource', () async {
      final repo = BackupAuthRepositoryImpl(
        auth: _MockAuthDatasource(
          signInError: const BackupException('Sign-in failed: unknown'),
        ),
      );
      expect(() => repo.signIn(), throwsA(isA<BackupException>()));
    });
  });

  // -----------------------------------------------------------------------
  // BackupAuthRepositoryImpl.getConnectionDetails
  // -----------------------------------------------------------------------
  group('BackupAuthRepositoryImpl.getConnectionDetails', () {
    test('returns signedOut when not signed in', () async {
      final repo = BackupAuthRepositoryImpl(
        auth: _MockAuthDatasource(signedIn: false),
      );
      final details = await repo.getConnectionDetails();
      expect(details.status, BackupConnectionStatus.signedOut);
      expect(details.email, isNull);
    });

    test('returns signedIn with fallback label when authenticated', () async {
      final repo = BackupAuthRepositoryImpl(
        auth: _MockAuthDatasource(
          signedIn: true,
          getHeadersResult: {'Authorization': 'Bearer token'},
        ),
      );
      final details = await repo.getConnectionDetails();
      expect(details.status, BackupConnectionStatus.signedIn);
      expect(details.email, 'Signed in');
    });

    test('returns expired when AuthExpiredException is thrown', () async {
      final repo = BackupAuthRepositoryImpl(
        auth: _MockAuthDatasource(
          signedIn: true,
          getHeadersError: const AuthExpiredException('Token expired.'),
        ),
      );
      final details = await repo.getConnectionDetails();
      expect(details.status, BackupConnectionStatus.expired);
    });

    test('returns signedIn on network error (optimistic)', () async {
      final repo = BackupAuthRepositoryImpl(
        auth: _MockAuthDatasource(
          signedIn: true,
          getHeadersError: const NetworkException('No internet.'),
        ),
      );
      final details = await repo.getConnectionDetails();
      expect(details.status, BackupConnectionStatus.signedIn);
    });
  });

  // -----------------------------------------------------------------------
  // GoogleAuthDatasource._handleAuthError — tested via real datasource
  // with _FakeGoogleSignIn that throws specific exceptions.
  // -----------------------------------------------------------------------
  group('GoogleAuthDatasource._handleAuthError (via real signIn)', () {
    test('wraps unknown exception in BackupException', () async {
      final ds = GoogleAuthDatasource(
        googleSignIn: _FakeGoogleSignIn(
          throwOnSignIn: Exception('Development mode not configured'),
        ),
      );
      expect(
        () => ds.signIn(),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('Sign-in failed'),
          ),
        ),
      );
    });

    test('maps 401 errors to AuthExpiredException', () async {
      final ds = GoogleAuthDatasource(
        googleSignIn: _FakeGoogleSignIn(
          throwOnSignIn: Exception('HTTP 401 Unauthorized'),
        ),
      );
      expect(() => ds.signIn(), throwsA(isA<AuthExpiredException>()));
    });

    test('maps socket errors to NetworkException', () async {
      final ds = GoogleAuthDatasource(
        googleSignIn: _FakeGoogleSignIn(
          throwOnSignIn: const SocketException('Failed host lookup'),
        ),
      );
      expect(() => ds.signIn(), throwsA(isA<NetworkException>()));
    });

    test('returns null when PlatformException is sign_in_canceled', () async {
      final ds = GoogleAuthDatasource(
        googleSignIn: _FakeGoogleSignIn(
          throwOnSignIn: Exception('sign_in_canceled'),
        ),
      );
      // Cancellation should return null, not throw.
      final result = await ds.signIn();
      expect(result, isNull);
    });

    test('returns null when signIn returns null (user cancels silently)', () async {
      final ds = GoogleAuthDatasource(
        googleSignIn: _FakeGoogleSignIn(), // signIn returns null
      );
      final result = await ds.signIn();
      expect(result, isNull);
    });

    test('maps DEVELOPER_ERROR to BackupException with config guidance', () async {
      final ds = GoogleAuthDatasource(
        googleSignIn: _FakeGoogleSignIn(
          throwOnSignIn: Exception('DEVELOPER_ERROR'),
        ),
      );
      expect(
        () => ds.signIn(),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('DEVELOPER_ERROR'),
              contains('SHA fingerprint'),
              contains('docs/SETUP.md'),
            ),
          ),
        ),
      );
    });

    test('maps ApiException 10 to BackupException with config guidance', () async {
      final ds = GoogleAuthDatasource(
        googleSignIn: _FakeGoogleSignIn(
          throwOnSignIn: Exception('ApiException: 10'),
        ),
      );
      expect(
        () => ds.signIn(),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('DEVELOPER_ERROR'),
          ),
        ),
      );
    });

    test('maps error code 12500 to BackupException with config guidance', () async {
      final ds = GoogleAuthDatasource(
        googleSignIn: _FakeGoogleSignIn(
          throwOnSignIn: Exception('StatusCode: 12500'),
        ),
      );
      expect(
        () => ds.signIn(),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('DEVELOPER_ERROR'),
          ),
        ),
      );
    });

    test('maps sign_in_failed to BackupException with guidance', () async {
      final ds = GoogleAuthDatasource(
        googleSignIn: _FakeGoogleSignIn(
          throwOnSignIn: Exception('sign_in_failed'),
        ),
      );
      expect(
        () => ds.signIn(),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('sign_in_failed'),
              contains('Google account'),
            ),
          ),
        ),
      );
    });

    test('maps network_error to NetworkException', () async {
      final ds = GoogleAuthDatasource(
        googleSignIn: _FakeGoogleSignIn(
          throwOnSignIn: Exception('network_error'),
        ),
      );
      expect(() => ds.signIn(), throwsA(isA<NetworkException>()));
    });

    test('maps INVALID_ACCOUNT to BackupException with config guidance', () async {
      final ds = GoogleAuthDatasource(
        googleSignIn: _FakeGoogleSignIn(
          throwOnSignIn: Exception('INVALID_ACCOUNT'),
        ),
      );
      expect(
        () => ds.signIn(),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('DEVELOPER_ERROR'),
          ),
        ),
      );
    });
  });

  // -----------------------------------------------------------------------
  // BackupErrorMapper.toEnglish — regression + new mappings
  // -----------------------------------------------------------------------
  group('BackupErrorMapper.toEnglish', () {
    test('maps NetworkException to network message', () {
      const error = NetworkException('No internet');
      expect(
        BackupErrorMapper.toEnglish(error),
        contains('No internet connection'),
      );
    });

    test('maps AuthExpiredException to expired message', () {
      const error = AuthExpiredException('Token expired');
      expect(
        BackupErrorMapper.toEnglish(error),
        contains('expired'),
      );
    });

    test('maps sign_in_canceled fallback to info message', () {
      // Raw string fallback path (if somehow not caught as typed exception).
      final error = Exception('sign_in_canceled');
      expect(
        BackupErrorMapper.toEnglish(error),
        equals('Sign-in cancelled'),
      );
    });

    test('maps DEVELOPER_ERROR BackupException to config guidance', () {
      const error = BackupException(
        'Sign-in failed — configuration error (DEVELOPER_ERROR). '
        'Check SHA fingerprint and google-services.json. '
        'See docs/SETUP.md §4.7 for troubleshooting. Some error',
      );
      expect(
        BackupErrorMapper.toEnglish(error),
        allOf(
          contains('DEVELOPER_ERROR 10'),
          contains('SHA fingerprint'),
          contains('docs/SETUP.md'),
        ),
      );
    });

    test('maps sign_in_failed BackupException to guidance', () {
      const error = BackupException('Sign-in failed: sign_in_failed');
      expect(
        BackupErrorMapper.toEnglish(error),
        allOf(
          contains('Sign-in failed'),
          contains('Google account'),
          contains('device Settings'),
        ),
      );
    });

    test('maps DEVELOPER_ERROR in raw string to config guidance', () {
      final error = Exception('DEVELOPER_ERROR');
      expect(
        BackupErrorMapper.toEnglish(error),
        allOf(
          contains('DEVELOPER_ERROR'),
          contains('SHA fingerprint'),
        ),
      );
    });

    test('maps ApiException 10 in raw string to config guidance', () {
      final error = Exception('ApiException: 10');
      expect(
        BackupErrorMapper.toEnglish(error),
        allOf(
          contains('DEVELOPER_ERROR'),
          contains('SHA fingerprint'),
        ),
      );
    });

    test('maps error 12500 in raw string to config guidance', () {
      final error = Exception('StatusCode: 12500');
      expect(
        BackupErrorMapper.toEnglish(error),
        allOf(
          contains('DEVELOPER_ERROR'),
          contains('SHA fingerprint'),
        ),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Configurable mock for [BackupAuthRepositoryImpl] unit tests.
// ---------------------------------------------------------------------------
class _MockAuthDatasource extends GoogleAuthDatasource {
  _MockAuthDatasource({
    this.signInAccount, // ignore: unused_element_parameter
    this.signInError,
    this.signedIn = false,
    this.getHeadersResult,
    this.getHeadersError,
  }) : super(googleSignIn: _FakeGoogleSignIn());

  final GoogleSignInAccount? signInAccount;
  final Object? signInError;
  final bool signedIn;
  final Map<String, String>? getHeadersResult;
  final Object? getHeadersError;

  @override
  Future<bool> isSignedIn() async => signedIn;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (signInError != null) throw signInError!;
    return signInAccount;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async => null;

  @override
  Future<Map<String, String>> getAuthHeaders() async {
    if (getHeadersError != null) throw getHeadersError!;
    return getHeadersResult ?? {};
  }

  @override
  GoogleSignInAccount? get currentUser => signInAccount;
}
