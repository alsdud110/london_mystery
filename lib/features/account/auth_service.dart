import 'package:flutter/foundation.dart';

/// A signed-in user, as the sign-in provider reports it. The [uid] comes
/// only from the provider (never from input or storage); it owns the
/// user's detective profiles. Holds no email, password or token.
@immutable
class UserSession {
  const UserSession({required this.uid, required this.emailVerified});

  final String uid;
  final bool emailVerified;

  @override
  bool operator ==(Object other) =>
      other is UserSession && other.uid == uid && other.emailVerified == emailVerified;

  @override
  int get hashCode => Object.hash(uid, emailVerified);

  /// Never prints the uid in full (logs).
  @override
  String toString() => 'UserSession(${uid.length > 4 ? '${uid.substring(0, 4)}…' : '…'}, verified: $emailVerified)';
}

/// Why an account action did not succeed: a short code for the app, turned
/// into a message for the player by [message]. Provider details stay out of
/// the screen and the logs.
enum AuthFailure {
  /// Not a usable email address.
  invalidEmail,

  /// The email or the password is wrong (never says which).
  wrongCredentials,

  /// An account with this email exists already.
  emailInUse,

  /// The password is too short or too simple.
  weakPassword,

  /// Too many tries: wait a while.
  tooManyRequests,

  /// No connection.
  network,

  /// The action needs the password again (see [AuthService.reauthenticate]).
  requiresRecentLogin,

  /// The account was turned off.
  userDisabled,

  /// Nobody is signed in.
  notSignedIn,

  /// Accounts are not available on this device right now (Firebase off for
  /// this build, or not started).
  cloudUnavailable,

  /// Anything else.
  unknown;

  /// For the player (Korean, calm, no internal detail).
  String get message => switch (this) {
        invalidEmail => '이메일 주소를 다시 확인해 주세요.',
        wrongCredentials => '이메일 또는 비밀번호가 올바르지 않습니다.',
        emailInUse => '이미 가입된 이메일입니다. 로그인하거나 비밀번호를 재설정해 주세요.',
        weakPassword => '비밀번호는 8자 이상으로, 영문과 숫자를 섞어 만들어 주세요.',
        tooManyRequests => '시도가 너무 많았습니다. 잠시 후 다시 시도해 주세요.',
        network => '인터넷 연결을 확인한 뒤 다시 시도해 주세요.',
        requiresRecentLogin => '안전을 위해 비밀번호를 한 번 더 입력해 주세요.',
        userDisabled => '사용할 수 없는 계정입니다. 고객 지원에 문의해 주세요.',
        notSignedIn => '먼저 로그인해 주세요.',
        cloudUnavailable => '지금은 계정 기능을 사용할 수 없습니다. 게임은 계속할 수 있어요.',
        unknown => '잠시 문제가 생겼습니다. 다시 시도해 주세요.',
      };
}

/// The outcome of an account action.
@immutable
class AuthResult {
  const AuthResult.ok([this.session]) : failure = null;

  const AuthResult.failed(AuthFailure this.failure) : session = null;

  final UserSession? session;
  final AuthFailure? failure;

  bool get ok => failure == null;
}

/// User sign-in (email and password). Implementations: `FirebaseAuthService`
/// (the app), `FakeAuthService` (tests).
///
/// Signing in, or a checked email address, is not the consent a legal
/// guardian must give for a child under 14: nothing here records or implies
/// it (see `ConsentRepository`).
abstract interface class AuthService {
  /// The signed-in user, now and on every change (null: signed out). A
  /// session kept from an earlier start comes back here.
  Stream<UserSession?> sessions();

  UserSession? get current;

  Future<AuthResult> signUp({required String email, required String password});

  Future<AuthResult> signIn({required String email, required String password});

  /// Sends a password reset email. Reports success whether or not the
  /// address has an account (it does not tell who has one).
  Future<AuthResult> sendPasswordReset(String email);

  /// Asks for the password again before a sensitive action (account or
  /// profile deletion, consent withdrawal).
  Future<AuthResult> reauthenticate(String password);

  /// Sends the email address check to the signed-in user.
  Future<AuthResult> sendEmailVerification();

  /// Asks the provider again whether the email address is checked.
  Future<AuthResult> refreshEmailVerified();

  Future<void> signOut();
}

/// Checks done before anything is sent (server-side rules still apply).
abstract final class AuthCredentials {
  static const passwordMinLength = 8;
  static const passwordMaxLength = 128;
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String cleanEmail(String raw) => raw.trim();

  static AuthFailure? checkEmail(String raw) {
    final email = cleanEmail(raw);
    return email.isEmpty || email.length > 254 || !_email.hasMatch(email) ? AuthFailure.invalidEmail : null;
  }

  /// At least 8 characters, letters and digits, at most 128.
  static AuthFailure? checkNewPassword(String password) {
    final ok = password.length >= passwordMinLength &&
        password.length <= passwordMaxLength &&
        password.contains(RegExp(r'[A-Za-z]')) &&
        password.contains(RegExp(r'[0-9]'));
    return ok ? null : AuthFailure.weakPassword;
  }
}
