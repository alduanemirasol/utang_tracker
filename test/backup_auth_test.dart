import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
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
