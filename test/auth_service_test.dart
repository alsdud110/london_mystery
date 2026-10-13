import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/cloud/cloud_bootstrap.dart';
import 'package:london_mystery/core/cloud/cloud_environment.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/features/account/account_controller.dart';
import 'package:london_mystery/features/account/fake_auth_service.dart';
import 'package:london_mystery/features/account/firebase_auth_service.dart';
import 'package:london_mystery/features/account/auth_service.dart';
import 'package:london_mystery/features/account/consent.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/profile/profile_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

const email = 'detective@example.com';
const password = 'detective42';

CloudBootstrap readyCloud() => CloudBootstrap(
      decision: const CloudDecision.start(CloudEnvironment.dev),
      initialize: () async => (projectId: CloudEnvironment.dev.projectId, appId: CloudEnvironment.dev.androidAppId),
    );

/// An account controller on a started (DEV) cloud with [auth].
Future<AccountController> readyAccount(FakeAuthService auth) async {
  final cloud = readyCloud();
  final account = AccountController(cloud: cloud, createAuth: () => auth);
  await cloud.start();
  await pumpEventQueue();
  return account;
}

Map<String, Object?> snapshot(SharedPreferences p) => {for (final k in p.getKeys()) k: p.get(k)};

void main() {
  group('sign-up, sign-in, sign-out', () {
    test('states follow the session: signed out → signed in → signed out', () async {
      final auth = FakeAuthService();
      final account = await readyAccount(auth);
      expect(account.value.status, AccountStatus.signedOut);

      final up = await account.signUp(email: email, password: password);
      expect(up.ok, isTrue);
      await pumpEventQueue();
      expect(account.value.status, AccountStatus.signedIn);
      expect(account.value.uid, up.session!.uid, reason: 'the uid is the provider\'s');
      expect(account.value.session!.emailVerified, isFalse);

      await account.signOut();
      await pumpEventQueue();
      expect(account.value.status, AccountStatus.signedOut);
      expect(account.value.uid, isNull);

      final back = await account.signIn(email: ' Detective@Example.com ', password: password);
      expect(back.ok, isTrue);
      await pumpEventQueue();
      expect(account.value.uid, up.session!.uid);
    });

    test('a session kept from an earlier start comes back without signing in', () async {
      const kept = UserSession(uid: 'kept-uid', emailVerified: true);
      final account = await readyAccount(FakeAuthService(restored: kept));
      expect(account.value.status, AccountStatus.signedIn);
      expect(account.value.session, kept);
    });

    test('checks before sending: email, password strength, an email already used', () async {
      final account = await readyAccount(FakeAuthService());
      expect((await account.signUp(email: 'not-an-email', password: password)).failure, AuthFailure.invalidEmail);
      expect((await account.signUp(email: email, password: 'short1')).failure, AuthFailure.weakPassword);
      expect((await account.signUp(email: email, password: 'lettersonly')).failure, AuthFailure.weakPassword);
      expect((await account.signUp(email: email, password: password)).ok, isTrue);
      await account.signOut();
      expect((await account.signUp(email: email, password: password)).failure, AuthFailure.emailInUse);
    });

    test('a wrong password and an unknown email get the same answer', () async {
      final account = await readyAccount(FakeAuthService());
      await account.signUp(email: email, password: password);
      await account.signOut();
      final wrong = await account.signIn(email: email, password: 'wrong1234');
      final unknown = await account.signIn(email: 'nobody@example.com', password: password);
      expect(wrong.failure, AuthFailure.wrongCredentials);
      expect(unknown.failure, AuthFailure.wrongCredentials);
      expect(wrong.failure!.message, unknown.failure!.message);
    });
  });

  group('password reset and re-authentication', () {
    test('a reset answers the same whether or not the address has an account', () async {
      final auth = FakeAuthService();
      final account = await readyAccount(auth);
      await account.signUp(email: email, password: password);
      expect((await account.sendPasswordReset(email)).ok, isTrue);
      expect((await account.sendPasswordReset('nobody@example.com')).ok, isTrue);
      expect(auth.resetsSent, [email]);
      expect((await account.sendPasswordReset('bad')).failure, AuthFailure.invalidEmail);
      auth.failNext = AuthFailure.network;
      final offline = await account.sendPasswordReset(email);
      expect(offline.failure, AuthFailure.network);
      expect(offline.failure!.message, contains('internet'));
    });

    test('re-authentication: the right password passes; a wrong one or nobody signed in does not', () async {
      final auth = FakeAuthService();
      final account = await readyAccount(auth);
      expect((await account.reauthenticate(password)).failure, AuthFailure.notSignedIn);
      await account.signUp(email: email, password: password);
      expect((await account.reauthenticate('wrong1234')).failure, AuthFailure.wrongCredentials);
      expect((await account.reauthenticate(password)).ok, isTrue);
      auth.failNext = AuthFailure.tooManyRequests;
      expect((await account.reauthenticate(password)).failure, AuthFailure.tooManyRequests);
    });

    test('email verification: sent, then seen once the user confirms', () async {
      final auth = FakeAuthService();
      final account = await readyAccount(auth);
      expect((await account.sendEmailVerification()).failure, AuthFailure.notSignedIn);
      await account.signUp(email: email, password: password);
      expect(auth.verificationsSent, 1, reason: 'sign-up sends the check once');
      expect((await account.sendEmailVerification()).ok, isTrue);
      expect(auth.verificationsSent, 2);
      expect((await account.refreshEmailVerified()).session!.emailVerified, isFalse);
      auth.verifyEmail(email);
      expect((await account.refreshEmailVerified()).session!.emailVerified, isTrue);
      await pumpEventQueue();
      expect(account.value.session!.emailVerified, isTrue);
    });
  });

  group('nothing calls Firebase before it is ready', () {
    test('Firebase failed: every action is unavailable and the sign-in service is never made', () async {
      var made = false;
      final cloud = CloudBootstrap(
        decision: const CloudDecision.start(CloudEnvironment.dev),
        initialize: () async => throw Exception('offline'),
      );
      final account = AccountController(
        cloud: cloud,
        createAuth: () {
          made = true;
          return FakeAuthService();
        },
      );
      await cloud.start();
      expect(account.value.status, AccountStatus.unavailable);
      for (final r in [
        await account.signUp(email: email, password: password),
        await account.signIn(email: email, password: password),
        await account.sendPasswordReset(email),
        await account.reauthenticate(password),
        await account.sendEmailVerification(),
        await account.refreshEmailVerified(),
      ]) {
        expect(r.failure, AuthFailure.cloudUnavailable);
      }
      await account.signOut();
      expect(made, isFalse);
    });

    test('still starting: unavailable until ready; then the service is made once', () async {
      var made = 0;
      final cloud = readyCloud();
      final account = AccountController(
        cloud: cloud,
        createAuth: () {
          made++;
          return FakeAuthService();
        },
      );
      expect(account.value.status, AccountStatus.starting);
      expect((await account.signIn(email: email, password: password)).failure, AuthFailure.cloudUnavailable);
      expect(made, 0);
      await cloud.start();
      await pumpEventQueue();
      expect(made, 1);
      expect(account.value.status, AccountStatus.signedOut);
    });

    test('a build without Firebase (tests, web, desktop, operator build on PROD): no accounts', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      expect(c.read(accountStateProvider).status, AccountStatus.unavailable);
      expect((await c.read(accountControllerProvider).signIn(email: email, password: password)).failure,
          AuthFailure.cloudUnavailable);
    });
  });

  group('signing in is not consent; it never touches the game', () {
    test('signing in or a checked email does not confirm consent: cloud features stay locked', () async {
      final auth = FakeAuthService();
      final account = await readyAccount(auth);
      await account.signUp(email: email, password: password);
      await pumpEventQueue();
      expect(account.value.uid, isNotNull);
      expect(account.value.consentConfirmed, isFalse);
      expect(account.value.cloudFeaturesAllowed, isFalse);
      // A checked email address is not a legal guardian's consent either.
      auth.verifyEmail(email);
      await account.refreshEmailVerified();
      await pumpEventQueue();
      expect(account.value.session!.emailVerified, isTrue);
      expect(account.value.cloudFeaturesAllowed, isFalse);
    });

    test('consent is read per account from its own record (the interface for the decided procedure)', () async {
      final auth = FakeAuthService();
      final cloud = readyCloud();
      final confirmedUids = <String>{};
      final account = AccountController(cloud: cloud, createAuth: () => auth, consents: _Consents(confirmedUids));
      await cloud.start();
      await pumpEventQueue();
      final a = await account.signUp(email: email, password: password);
      await pumpEventQueue();
      expect(account.value.consent, ConsentStatus.unconfirmed);
      await account.signOut();
      confirmedUids.add(a.session!.uid); // recorded by the (future) procedure
      await account.signIn(email: email, password: password);
      await pumpEventQueue();
      expect(account.value.consent, ConsentStatus.confirmed);
      expect(account.value.cloudFeaturesAllowed, isTrue);
      await account.signUp(email: 'other@example.com', password: password);
      await pumpEventQueue();
      expect(account.value.consent, ConsentStatus.unconfirmed, reason: 'another account has its own record');
      expect(await const UndecidedConsent().statusOf(a.session!.uid), ConsentStatus.unconfirmed,
          reason: 'until the procedure is decided, nobody is confirmed');
    });

    test('sign-in, failures and sign-out leave the guest and its saves exactly as they were', () async {
      final auth = FakeAuthService();
      final account = await readyAccount(auth);
      final c = ProviderContainer(overrides: [
        ...await testOverrides(),
        accountControllerProvider.overrideWithValue(account),
      ]);
      addTearDown(c.dispose);
      final game = c.read(gameControllerProvider.notifier);
      game.registerDetective('ANNA');
      game.startInvestigation();
      expect(game.submitAnswer(episode01.missions.first, 'b').coins, 30);
      final prefs = c.read(sharedPreferencesProvider);
      final before = snapshot(prefs);
      final guest = c.read(profileSessionProvider).profileId;

      auth.failNext = AuthFailure.network;
      expect((await account.signUp(email: email, password: password)).ok, isFalse);
      expect((await account.signIn(email: email, password: 'wrong1234')).ok, isFalse);
      expect((await account.signUp(email: email, password: password)).ok, isTrue);
      await pumpEventQueue();
      expect(c.read(accountStateProvider).status, AccountStatus.signedIn);
      await account.signOut();
      await pumpEventQueue();

      expect(snapshot(prefs), before, reason: 'nothing saved, uploaded or queued by signing in or out');
      expect(c.read(profileSessionProvider).profileId, guest);
      expect(c.read(gameControllerProvider).isCompleted('m01'), isTrue);
    });
  });

  group('an account\'s profiles open only for that account', () {
    test('another account\'s profiles are not listed; the guest always is', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      c.read(profileSessionProvider); // the device's profiles are made on first use
      final store = c.read(profileStoreProvider);
      final guest = store.guest!;
      final a = await store.addProfile(detectiveName: 'AMY', ownerUid: 'uid-a');
      final b = await store.addProfile(detectiveName: 'BOB', ownerUid: 'uid-b');
      expect(store.openableBy(null).map((p) => p.id), [guest.id]);
      expect(store.openableBy('uid-a').map((p) => p.id), [guest.id, a.id]);
      expect(store.openableBy('uid-b').map((p) => p.id), [guest.id, b.id]);
      expect(ProfileStore(c.read(sharedPreferencesProvider)).read()!.byId(a.id)!.ownerUid, 'uid-a');
    });

    test('at start nobody is signed in yet: an account\'s profile left open does not open', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      final prefs = c.read(sharedPreferencesProvider);
      c.read(profileSessionProvider); // the device's profiles are made on first use
      final store = c.read(profileStoreProvider);
      final guest = store.guest!;
      final a = await store.addProfile(ownerUid: 'uid-a');
      await store.setActive(a.id);
      c.dispose();
      final session = await ProfileStore(prefs).bootstrap();
      expect(session.profileId, guest.id);
      expect(ProfileStore(prefs).read()!.activeProfileId, guest.id);
    });

    testWidgets('switching to another account\'s profile is refused; signing out closes the account\'s profile', (t) async {
      final overrides = await testOverrides();
      final prefs = await SharedPreferences.getInstance();
      final store = ProfileStore(prefs);
      final start = store.ensureActiveSync();
      final a = await store.addProfile(detectiveName: 'AMY', ownerUid: 'uid-a');
      final b = await store.addProfile(detectiveName: 'BOB', ownerUid: 'uid-b');
      String? signedIn = 'uid-a';
      final host = GlobalKey<ProfileSessionHostState>();
      await t.pumpWidget(ProfileSessionHost(
        key: host,
        session: start,
        overrides: overrides,
        signedInUid: () => signedIn,
        child: const SizedBox(),
      ));

      await host.currentState!.switchTo(a.id);
      await t.pump();
      expect(host.currentState!.session.profileId, a.id);
      await expectLater(host.currentState!.switchTo(b.id), throwsStateError);
      expect(host.currentState!.session.profileId, a.id);

      signedIn = 'uid-b'; // another user signs in on this device
      await host.currentState!.enforceAccess();
      await t.pump();
      expect(host.currentState!.session.profileId, start.profileId, reason: 'back to the guest');

      signedIn = null; // signed out
      await host.currentState!.enforceAccess();
      await t.pump();
      expect(host.currentState!.session.profileId, start.profileId, reason: 'the guest stays');
      await expectLater(host.currentState!.switchTo(a.id), throwsStateError);
      expect(store.profile(a.id), isNotNull, reason: 'locked, not deleted');
    });

    test('old profiles without an owner keep opening as before', () {
      final p = DetectiveProfile.fromJson({'id': 'abcdef0123456789', 'kind': 'guest', 'origin': 'fresh'})!;
      expect(p.ownerUid, isNull);
      expect(p.mayOpen(null), isTrue);
      expect(p.toJson().containsKey('ownerUid'), isFalse);
    });
  });

  group('messages and logs', () {
    test('Firebase error codes become a reason; unknown codes are "unknown"', () {
      expect(FirebaseAuthService.failureOf('invalid-credential'), AuthFailure.wrongCredentials);
      expect(FirebaseAuthService.failureOf('user-not-found'), AuthFailure.wrongCredentials);
      expect(FirebaseAuthService.failureOf('wrong-password'), AuthFailure.wrongCredentials);
      expect(FirebaseAuthService.failureOf('email-already-in-use'), AuthFailure.emailInUse);
      expect(FirebaseAuthService.failureOf('weak-password'), AuthFailure.weakPassword);
      expect(FirebaseAuthService.failureOf('too-many-requests'), AuthFailure.tooManyRequests);
      expect(FirebaseAuthService.failureOf('network-request-failed'), AuthFailure.network);
      expect(FirebaseAuthService.failureOf('requires-recent-login'), AuthFailure.requiresRecentLogin);
      expect(FirebaseAuthService.failureOf('user-disabled'), AuthFailure.userDisabled);
      expect(FirebaseAuthService.failureOf('internal-error'), AuthFailure.unknown);
    });

    test('messages for players carry no codes or internals; a session prints no full uid', () {
      for (final f in AuthFailure.values) {
        expect(f.message, isNot(matches(RegExp(r'[a-z]+-[a-z]+'))), reason: f.name);
        expect(f.message, isNotEmpty);
      }
      const s = UserSession(uid: 'abcdefghijklmnop', emailVerified: false);
      expect(s.toString(), isNot(contains('abcdefghijklmnop')));
    });
  });
}

/// Consent records for tests: the uids in [confirmed] are confirmed.
class _Consents implements ConsentRepository {
  _Consents(this.confirmed);

  final Set<String> confirmed;

  @override
  Future<ConsentStatus> statusOf(String uid) async =>
      confirmed.contains(uid) ? ConsentStatus.confirmed : ConsentStatus.unconfirmed;
}
