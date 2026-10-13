import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

/// [AuthService] on Firebase Authentication (email and password). Create it
/// only once Firebase is ready (see `AccountController`); the session is
/// kept on the device by Firebase and comes back on the next start, also
/// offline.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  static UserSession? _session(User? user) =>
      user == null ? null : UserSession(uid: user.uid, emailVerified: user.emailVerified);

  @override
  Stream<UserSession?> sessions() => _auth.userChanges().map(_session).distinct();

  @override
  UserSession? get current => _session(_auth.currentUser);

  @override
  Future<AuthResult> signUp({required String email, required String password}) async {
    final bad = AuthCredentials.checkEmail(email) ?? AuthCredentials.checkNewPassword(password);
    if (bad != null) return AuthResult.failed(bad);
    return _run(() async {
      final c = await _auth.createUserWithEmailAndPassword(email: AuthCredentials.cleanEmail(email), password: password);
      return AuthResult.ok(_session(c.user));
    });
  }

  @override
  Future<AuthResult> signIn({required String email, required String password}) async {
    if (AuthCredentials.checkEmail(email) != null || password.isEmpty) {
      return const AuthResult.failed(AuthFailure.wrongCredentials);
    }
    return _run(() async {
      final c = await _auth.signInWithEmailAndPassword(email: AuthCredentials.cleanEmail(email), password: password);
      return AuthResult.ok(_session(c.user));
    });
  }

  @override
  Future<AuthResult> sendPasswordReset(String email) async {
    final bad = AuthCredentials.checkEmail(email);
    if (bad != null) return AuthResult.failed(bad);
    final r = await _run(() async {
      await _auth.sendPasswordResetEmail(email: AuthCredentials.cleanEmail(email));
      return const AuthResult.ok();
    });
    // Whether the address has an account is not told.
    return r.failure == AuthFailure.wrongCredentials ? const AuthResult.ok() : r;
  }

  @override
  Future<AuthResult> reauthenticate(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return const AuthResult.failed(AuthFailure.notSignedIn);
    return _run(() async {
      final c = await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: email, password: password));
      return AuthResult.ok(_session(c.user));
    });
  }

  @override
  Future<AuthResult> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return const AuthResult.failed(AuthFailure.notSignedIn);
    return _run(() async {
      await user.sendEmailVerification();
      return AuthResult.ok(_session(user));
    });
  }

  @override
  Future<AuthResult> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return const AuthResult.failed(AuthFailure.notSignedIn);
    return _run(() async {
      await user.reload();
      return AuthResult.ok(_session(_auth.currentUser));
    });
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AuthResult> _run(Future<AuthResult> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      final failure = failureOf(e.code);
      // The code only: never the email, the password or a token.
      debugPrint('Account: ${failure.name} (${e.code})');
      return AuthResult.failed(failure);
    } catch (e) {
      debugPrint('Account: unknown (${e.runtimeType})');
      return const AuthResult.failed(AuthFailure.unknown);
    }
  }

  /// Firebase Authentication error codes → [AuthFailure].
  @visibleForTesting
  static AuthFailure failureOf(String code) => switch (code) {
        'invalid-email' => AuthFailure.invalidEmail,
        'user-not-found' || 'wrong-password' || 'invalid-credential' || 'invalid-login-credentials' =>
          AuthFailure.wrongCredentials,
        'email-already-in-use' || 'credential-already-in-use' => AuthFailure.emailInUse,
        'weak-password' || 'password-does-not-meet-requirements' => AuthFailure.weakPassword,
        'too-many-requests' => AuthFailure.tooManyRequests,
        'network-request-failed' => AuthFailure.network,
        'requires-recent-login' || 'user-token-expired' => AuthFailure.requiresRecentLogin,
        'user-disabled' => AuthFailure.userDisabled,
        _ => AuthFailure.unknown,
      };
}
