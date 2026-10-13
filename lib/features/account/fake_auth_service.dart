import 'dart:async';

import 'auth_service.dart';

/// [AuthService] in memory, for tests and previews: accounts are kept in this
/// object only. [failNext] makes the next call fail with a given reason
/// (network, too many tries, …).
class FakeAuthService implements AuthService {
  FakeAuthService({UserSession? restored}) : _current = restored;

  final _accounts = <String, ({String uid, String password, bool verified})>{};
  final _changes = StreamController<UserSession?>.broadcast();
  UserSession? _current;
  String? _currentEmail;
  int _nextUid = 1;

  /// The next call fails with this reason (then it is cleared).
  AuthFailure? failNext;

  /// Password reset emails "sent", by address (only to existing accounts).
  final resetsSent = <String>[];
  int verificationsSent = 0;

  void close() => _changes.close();

  AuthFailure? _takeFailure() {
    final f = failNext;
    failNext = null;
    return f;
  }

  void _set(UserSession? s, [String? email]) {
    _current = s;
    _currentEmail = s == null ? null : email;
    _changes.add(s);
  }

  @override
  Stream<UserSession?> sessions() async* {
    yield _current;
    yield* _changes.stream;
  }

  @override
  UserSession? get current => _current;

  @override
  Future<AuthResult> signUp({required String email, required String password}) async {
    if (_takeFailure() case final f?) return AuthResult.failed(f);
    final bad = AuthCredentials.checkEmail(email) ?? AuthCredentials.checkNewPassword(password);
    if (bad != null) return AuthResult.failed(bad);
    final key = AuthCredentials.cleanEmail(email).toLowerCase();
    if (_accounts.containsKey(key)) return const AuthResult.failed(AuthFailure.emailInUse);
    final uid = 'fake-uid-${_nextUid++}';
    _accounts[key] = (uid: uid, password: password, verified: false);
    final s = UserSession(uid: uid, emailVerified: false);
    _set(s, key);
    return AuthResult.ok(s);
  }

  @override
  Future<AuthResult> signIn({required String email, required String password}) async {
    if (_takeFailure() case final f?) return AuthResult.failed(f);
    final key = AuthCredentials.cleanEmail(email).toLowerCase();
    final a = _accounts[key];
    if (a == null || a.password != password) return const AuthResult.failed(AuthFailure.wrongCredentials);
    final s = UserSession(uid: a.uid, emailVerified: a.verified);
    _set(s, key);
    return AuthResult.ok(s);
  }

  @override
  Future<AuthResult> sendPasswordReset(String email) async {
    if (_takeFailure() case final f?) return AuthResult.failed(f);
    final bad = AuthCredentials.checkEmail(email);
    if (bad != null) return AuthResult.failed(bad);
    final key = AuthCredentials.cleanEmail(email).toLowerCase();
    if (_accounts.containsKey(key)) resetsSent.add(key);
    return const AuthResult.ok(); // the same answer either way
  }

  @override
  Future<AuthResult> reauthenticate(String password) async {
    if (_takeFailure() case final f?) return AuthResult.failed(f);
    final email = _currentEmail;
    if (_current == null || email == null) return const AuthResult.failed(AuthFailure.notSignedIn);
    return _accounts[email]!.password == password
        ? AuthResult.ok(_current)
        : const AuthResult.failed(AuthFailure.wrongCredentials);
  }

  @override
  Future<AuthResult> sendEmailVerification() async {
    if (_takeFailure() case final f?) return AuthResult.failed(f);
    if (_current == null) return const AuthResult.failed(AuthFailure.notSignedIn);
    verificationsSent++;
    return AuthResult.ok(_current);
  }

  /// The user clicked the link in the email (test helper).
  void verifyEmail(String email) {
    final key = email.toLowerCase();
    final a = _accounts[key]!;
    _accounts[key] = (uid: a.uid, password: a.password, verified: true);
  }

  @override
  Future<AuthResult> refreshEmailVerified() async {
    if (_takeFailure() case final f?) return AuthResult.failed(f);
    final email = _currentEmail;
    if (_current == null || email == null) return const AuthResult.failed(AuthFailure.notSignedIn);
    final s = UserSession(uid: _current!.uid, emailVerified: _accounts[email]!.verified);
    if (s != _current) _set(s, email);
    return AuthResult.ok(s);
  }

  @override
  Future<void> signOut() async => _set(null);
}
