import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/cloud/cloud_bootstrap.dart';
import 'package:london_mystery/core/cloud/cloud_environment.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/features/account/account_controller.dart';
import 'package:london_mystery/features/account/auth_service.dart';
import 'package:london_mystery/features/account/fake_auth_service.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/profile/profile_session.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

const _email = 'detective@example.com';
const _password = 'detective42';

/// The app as `main()` runs it: the profile host, a started cloud on [env],
/// a fake sign-in service, and signing out closing an account's detective.
class _App {
  _App(this.t, this.host, this.account, this.auth, this.prefs);

  final WidgetTester t;
  final GlobalKey<ProfileSessionHostState> host;
  final AccountController account;
  final FakeAuthService auth;
  final SharedPreferences prefs;

  ProviderContainer get c => host.currentState!.container;
  String get path => c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();
  String get playing => host.currentState!.session.profileId;

  Future<void> go(String location) async {
    c.read(routerProvider).go(location);
    await wait(t, const Duration(milliseconds: 700));
  }

  Future<void> type(String label, String text) async {
    await t.enterText(find.widgetWithText(TextField, label), text);
    await t.pump();
  }

  Future<void> press(String label) async {
    final b = find.widgetWithText(GameButton, label);
    await t.ensureVisible(b);
    await t.pump();
    await t.tap(b);
    await wait(t, const Duration(milliseconds: 900));
  }

  Future<void> link(String label) async {
    final l = find.widgetWithText(TextButton, label);
    await t.ensureVisible(l);
    await t.pump();
    await t.tap(l);
    await wait(t, const Duration(milliseconds: 900));
  }

  Map<String, Object?> snapshot() => {for (final k in prefs.getKeys()) k: prefs.get(k)};
}

Future<_App> _open(
  WidgetTester t, {
  Size size = const Size(390, 844),
  double scale = 1,
  CloudEnvironment env = CloudEnvironment.dev,
  bool guestPlayed = false,
}) async {
  t.view.physicalSize = size * 3;
  t.view.devicePixelRatio = 3;
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  final overrides = await testOverrides();
  final prefs = await SharedPreferences.getInstance();
  final session = ProfileStore(prefs).ensureActiveSync();
  final auth = FakeAuthService();
  final cloud = CloudBootstrap(
    decision: CloudDecision.start(env),
    initialize: () async => (projectId: env.projectId, appId: env.androidAppId),
  );
  final account = AccountController(cloud: cloud, createAuth: () => auth);
  final host = GlobalKey<ProfileSessionHostState>();
  account.addListener(() => host.currentState?.enforceAccess());
  // Started in the test's own zone, so the session stream and what it sets
  // off run with the test clock (as they run with the app's).
  cloud.start();
  await t.pump();
  await t.pump();
  await t.pumpWidget(ProfileSessionHost(
    key: host,
    session: session,
    signedInUid: () => account.value.uid,
    overrides: [
      ...overrides,
      cloudBootstrapProvider.overrideWithValue(cloud),
      accountControllerProvider.overrideWithValue(account),
    ],
    child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
  ));
  await wait(t, const Duration(milliseconds: 400));
  final app = _App(t, host, account, auth, prefs);
  if (guestPlayed) {
    final game = app.c.read(gameControllerProvider.notifier);
    game.registerDetective('ANNA');
    game.startInvestigation();
    game.submitAnswer(episode01.missions.first, 'b');
    await t.pump();
  }
  return app;
}

/// [f] is inside the screen and at least 44 high.
void _whole(WidgetTester t, Finder f, Size size) {
  final r = t.getRect(f);
  expect(r.left, greaterThanOrEqualTo(0));
  expect(r.right, lessThanOrEqualTo(size.width));
  expect(r.bottom, lessThanOrEqualTo(size.height));
  expect(r.height, greaterThanOrEqualTo(44));
}

void main() {
  group('title page', () {
    testWidgets('a small Sign in link under the game button; playing needs no account', (t) async {
      final app = await _open(t);
      await wait(t, const Duration(seconds: 3)); // the title's rise-in
      expect(find.text('START ADVENTURE'), findsOneWidget);
      final link = find.widgetWithText(TextButton, 'Sign in');
      expect(link, findsOneWidget);
      expect(t.getRect(link).top, greaterThan(t.getRect(find.text('START ADVENTURE')).bottom), reason: 'below it');
      await app.link('Sign in');
      expect(app.path, Routes.account);
      expect(find.byType(TextField), findsWidgets);
      expect(find.textContaining('parent', findRichText: true), findsNothing, reason: 'no parent gate');
    });

    testWidgets('without accounts in the build: no link at all', (t) async {
      await t.pumpWidget(ProviderScope(overrides: await testOverrides(), child: const LondonMysteryApp()));
      await wait(t, const Duration(seconds: 3));
      expect(find.text('START ADVENTURE'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
    });
  });

  group('Account Desk', () {
    for (final (size, scale, tag) in const [
      (Size(360, 640), 1.0, '360x640'),
      (Size(390, 844), 1.0, '390x844'),
      (Size(360, 640), 1.3, '360x640_x1.3'),
    ]) {
      testWidgets('$tag: sign in and new account lay out; the buttons are whole', (t) async {
        final app = await _open(t, size: size, scale: scale);
        await app.go(Routes.account);
        expect(find.text('SIGN IN'), findsWidgets);
        expect(find.text('NEW ACCOUNT'), findsOneWidget);
        final signIn = find.widgetWithText(GameButton, 'SIGN IN');
        await t.ensureVisible(signIn); // a small phone with large text scrolls the page
        await t.pump();
        _whole(t, signIn, size);
        await capture(t, 'account_sign_in_$tag');
        await app.go(Routes.newAccount);
        expect(find.widgetWithText(TextField, 'Password again'), findsOneWidget);
        final create = find.widgetWithText(GameButton, 'CREATE ACCOUNT');
        await t.ensureVisible(create);
        await t.pump();
        _whole(t, create, size);
        await capture(t, 'account_new_$tag');
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('new account: made, signed in, sent to the email check; nothing else changes', (t) async {
      final app = await _open(t, guestPlayed: true);
      final guest = app.playing;
      final before = app.snapshot();
      await app.go(Routes.newAccount);
      await app.type('Email', _email);
      await app.type('Password', _password);
      await app.type('Password again', _password);
      await app.press('CREATE ACCOUNT');
      expect(app.account.value.status, AccountStatus.signedIn);
      expect(app.path, Routes.accountVerify);
      expect(app.auth.verificationsSent, 1);
      expect(app.account.value.cloudFeaturesAllowed, isFalse, reason: 'consent is never confirmed by signing up');
      expect(app.playing, guest, reason: 'the guest keeps playing');
      expect(app.snapshot(), before, reason: 'no owner changed, nothing saved, uploaded or queued');
      final store = ProfileStore(app.prefs);
      expect(store.profile(guest)!.ownerUid, isNull, reason: 'the guest is not given to the account');
    });

    testWidgets('the check email could not be sent: said at once, and it can be sent again', (t) async {
      final app = await _open(t);
      app.auth.failNextVerification = AuthFailure.network;
      await app.go(Routes.newAccount);
      await app.type('Email', _email);
      await app.type('Password', _password);
      await app.type('Password again', _password);
      await app.press('CREATE ACCOUNT');
      expect(app.account.value.status, AccountStatus.signedIn, reason: 'the account is made');
      expect(app.path, Routes.accountVerify);
      expect(app.auth.verificationsSent, 0);
      expect(find.text("We couldn't send the letter. ${AuthFailure.network.message}"), findsOneWidget);
      expect(find.textContaining('We sent a letter'), findsNothing, reason: 'never claims it was sent');
      await app.link('Send it again');
      expect(find.text('Sent again. It may take a minute.'), findsOneWidget);
      expect(app.auth.verificationsSent, 1);
      expect(app.account.verificationSendFailure, isNull);
    });

    testWidgets("one account's unsent letter is never told to the next account", (t) async {
      final app = await _open(t);
      app.auth.failNextVerification = AuthFailure.network;
      await app.account.signUp(email: _email, password: _password);
      await wait(t, const Duration(milliseconds: 300));
      expect(app.account.verificationSendFailure, AuthFailure.network);
      await app.account.signOut();
      await wait(t, const Duration(milliseconds: 300));
      expect(app.account.verificationSendFailure, isNull, reason: 'signed out');
      await app.account.signUp(email: 'other@example.com', password: _password);
      await app.account.signOut();
      await wait(t, const Duration(milliseconds: 300));
      await app.go(Routes.account);
      await app.type('Email', 'other@example.com');
      await app.type('Password', _password);
      await app.press('SIGN IN');
      expect(app.path, Routes.accountVerify);
      expect(find.textContaining("couldn't send"), findsNothing);
      expect(find.textContaining('We sent a letter'), findsOneWidget);
    });

    testWidgets('mistakes: passwords not the same, a weak password, a wrong one; the game is untouched', (t) async {
      final app = await _open(t, guestPlayed: true);
      final before = app.snapshot();
      await app.go(Routes.newAccount);
      await app.type('Email', _email);
      await app.type('Password', _password);
      await app.type('Password again', 'other4242');
      await app.press('CREATE ACCOUNT');
      expect(find.text('The two passwords are not the same.'), findsOneWidget);
      await app.type('Password', 'short');
      await app.type('Password again', 'short');
      await app.press('CREATE ACCOUNT');
      expect(find.text(AuthFailure.weakPassword.message), findsOneWidget);

      await app.go(Routes.account);
      await app.type('Email', _email);
      await app.type('Password', 'wrong4242');
      await app.press('SIGN IN');
      expect(find.text(AuthFailure.wrongCredentials.message), findsOneWidget);
      app.auth.failNext = AuthFailure.network;
      await app.press('SIGN IN');
      expect(find.text(AuthFailure.network.message), findsOneWidget);
      expect(app.account.value.status, AccountStatus.signedOut);
      expect(app.path, Routes.account);
      expect(app.snapshot(), before);
      await app.link('Play as a guest');
      expect(app.path, Routes.start);
    });

    testWidgets('sign in with a checked email goes to the detectives', (t) async {
      final app = await _open(t);
      await app.account.signUp(email: _email, password: _password);
      app.auth.verifyEmail(_email);
      await app.account.signOut();
      await wait(t, const Duration(milliseconds: 300));
      await app.go(Routes.account);
      await app.type('Email', _email);
      await app.type('Password', _password);
      await app.press('SIGN IN');
      expect(app.path, Routes.profiles);
    });
  });

  group('PROD: no accounts offered (email sign-in is off on the server)', () {
    testWidgets('no Sign in / My account link; account pages go back to the title; sign-up refused', (t) async {
      final app = await _open(t, env: CloudEnvironment.prod);
      await wait(t, const Duration(seconds: 3)); // the title's rise-in
      expect(find.text('START ADVENTURE'), findsOneWidget, reason: 'the game is as before');
      expect(find.text('Sign in'), findsNothing);
      for (final page in [
        Routes.account,
        Routes.newAccount,
        Routes.accountReset,
        Routes.accountVerify,
        Routes.accountSettings,
        Routes.accountDelete,
        Routes.profiles,
        Routes.newProfile,
      ]) {
        await app.go(page);
        expect(app.path, Routes.start, reason: page);
      }
      final r = await app.account.signUp(email: _email, password: _password);
      expect(r.failure, AuthFailure.signUpClosed);
      expect(app.account.value.status, AccountStatus.signedOut);
      expect(CloudEnvironment.prod.signUpOpen, isFalse);
      expect(CloudEnvironment.prod.accountsShown, isFalse);
      expect(CloudEnvironment.dev.signUpOpen, isTrue);
      expect(CloudEnvironment.dev.accountsShown, isTrue);
    });

    testWidgets('even signed in somehow: no My account link and no account pages', (t) async {
      final app = await _open(t, env: CloudEnvironment.prod);
      await app.auth.signUp(email: _email, password: _password); // not through the app
      await wait(t, const Duration(seconds: 3));
      expect(app.account.value.status, AccountStatus.signedIn);
      expect(find.text('My account'), findsNothing);
      await app.go(Routes.accountSettings);
      expect(app.path, Routes.start);
    });
  });

  group('password reset and the email check', () {
    testWidgets('reset: the same answer for any address', (t) async {
      final app = await _open(t);
      await app.account.signUp(email: _email, password: _password);
      await app.account.signOut();
      await wait(t, const Duration(milliseconds: 300));
      await app.go(Routes.account);
      await app.link('Forgot your password?');
      expect(app.path, Routes.accountReset);
      await app.type('Email', 'nobody@example.com');
      await app.press('SEND RESET LINK');
      const same = 'If an account uses this email, a reset link is on its way. Check your inbox.';
      expect(find.text(same), findsOneWidget);
      await app.type('Email', _email);
      await app.press('SEND RESET LINK');
      expect(find.text(same), findsOneWidget);
      expect(app.auth.resetsSent, [_email]);
    });

    testWidgets('email check: not yet, then checked', (t) async {
      final app = await _open(t);
      await app.account.signUp(email: _email, password: _password);
      await app.go(Routes.accountVerify);
      expect(find.textContaining('de•••@ex•••.com'), findsOneWidget, reason: 'the address, partly hidden');
      await app.press("I'VE CHECKED MY EMAIL");
      expect(find.text('Not checked yet. Open the link in the email, then try again.'), findsOneWidget);
      app.auth.verifyEmail(_email);
      await app.press("I'VE CHECKED MY EMAIL");
      expect(app.path, Routes.profiles);
    });
  });

  group('detectives: each account its own; the guest stays', () {
    testWidgets('a new detective for the account plays; the guest and its saves are untouched', (t) async {
      final app = await _open(t, guestPlayed: true);
      final guest = app.playing;
      final guestSaves = {
        for (final e in app.snapshot().entries)
          if (e.key.contains(guest)) e.key: e.value,
      };
      await app.account.signUp(email: _email, password: _password);
      final uid = app.account.value.uid!;
      await app.go(Routes.profiles);
      expect(find.text('ANNA'), findsOneWidget, reason: 'the guest is listed');
      expect(find.text('GUEST · THIS DEVICE'), findsOneWidget);
      await app.press('NEW DETECTIVE');
      expect(app.path, Routes.newProfile);
      await app.type('Detective name', ' min  young ');
      await app.press('CREATE DETECTIVE');
      await wait(t, const Duration(milliseconds: 600));
      expect(app.playing, isNot(guest));
      final p = ProfileStore(app.prefs).profile(app.playing)!;
      expect(p.kind, ProfileKind.account);
      expect(p.ownerUid, uid);
      expect(p.detectiveName, 'MIN YOUNG');
      expect(app.c.read(gameControllerProvider).detectiveName, 'MIN YOUNG');
      expect(app.c.read(gameControllerProvider).isCompleted('m01'), isFalse, reason: 'its own saves');
      expect(DetectiveProfile.isValidId(p.id), isTrue);
      // Every guest save as it was; only the play clock of the case left is
      // banked on switching (as on leaving any case).
      Object? withoutClock(Object? v) {
        if (v is! String || !v.contains('"playMillis"')) return v;
        return (jsonDecode(v) as Map<String, dynamic>)
          ..remove('playMillis')
          ..remove('rev'); // that save's revision counter
      }

      // The local outbox (never uploaded here) keeps something for every
      // record it had: a newer save of the same case replaces its pending
      // event (Outbox.enqueue); wallet entries stay as they are.
      Set<String> events(Object? v) => {
            for (final x in (jsonDecode(v! as String) as Map<String, dynamic>).values)
              if (x is List)
                for (final e in x.cast<Map<String, dynamic>>())
                  e['kind'] == 'walletEntry' ? jsonEncode(e) : '${e['kind']}:${e['subject']}',
          };

      final after = app.snapshot();
      expect(after.keys, containsAll(guestSaves.keys));
      for (final e in guestSaves.entries) {
        if (e.key.endsWith('.outbox.v1')) {
          expect(events(after[e.key]), containsAll(events(e.value)), reason: 'guest outbox ${e.key}');
        } else {
          expect(withoutClock(after[e.key]), withoutClock(e.value), reason: 'guest save ${e.key}');
        }
      }
    });

    testWidgets('a name outside the rule is refused before anything is made', (t) async {
      final app = await _open(t);
      await app.account.signUp(email: _email, password: _password);
      final before = ProfileStore(app.prefs).read()!.profiles.length;
      await app.go(Routes.newProfile);
      await app.type('Detective name', '   ');
      await app.press('CREATE DETECTIVE');
      expect(find.text('Please type your detective name.'), findsOneWidget);
      expect(ProfileStore(app.prefs).read()!.profiles.length, before);
    });

    testWidgets("switching accounts: another account's detectives are never listed or opened", (t) async {
      final app = await _open(t, guestPlayed: true);
      final guest = app.playing;
      await app.account.signUp(email: _email, password: _password);
      await wait(t, const Duration(milliseconds: 300));
      final store = ProfileStore(app.prefs);
      final amy = await store.addProfile(detectiveName: 'AMY', ownerUid: app.account.value.uid);
      await app.host.currentState!.switchTo(amy.id);
      await wait(t, const Duration(milliseconds: 400));
      expect(app.playing, amy.id);

      await app.account.signOut();
      await wait(t, const Duration(milliseconds: 400));
      expect(app.playing, guest, reason: 'signing out closes the account\'s detective');

      await app.account.signUp(email: 'other@example.com', password: _password);
      await wait(t, const Duration(milliseconds: 300));
      await app.go(Routes.profiles);
      expect(find.text('AMY'), findsNothing, reason: 'not this account\'s');
      expect(find.text('ANNA'), findsOneWidget);
      await expectLater(app.host.currentState!.switchTo(amy.id), throwsStateError);
      expect(store.profile(amy.id), isNotNull, reason: 'kept on the device, locked');
      expect(app.playing, guest);
    });

    testWidgets('signed out: the list shows the guest and a way to sign in', (t) async {
      final app = await _open(t, guestPlayed: true);
      await app.go(Routes.profiles);
      expect(find.text('ANNA'), findsOneWidget);
      expect(find.widgetWithText(GameButton, 'SIGN IN'), findsOneWidget);
      expect(find.widgetWithText(GameButton, 'NEW DETECTIVE'), findsNothing);
      await app.go(Routes.newProfile);
      expect(app.path, Routes.account, reason: 'needs an account');
    });
  });

  group('account page, sign out, deletion', () {
    testWidgets('the page: hidden email, email check, cloud save not available; sign out keeps the guest', (t) async {
      final app = await _open(t, guestPlayed: true);
      final guest = app.playing;
      await app.account.signUp(email: _email, password: _password);
      await app.go(Routes.accountSettings);
      expect(find.text('de•••@ex•••.com'), findsOneWidget);
      expect(find.text('Not checked yet'), findsOneWidget);
      expect(find.text('Not available yet'), findsOneWidget);
      expect(find.textContaining(_email), findsNothing, reason: 'never the full address');
      await capture(t, 'account_settings_390x844');
      await app.link('Sign out');
      await t.tap(find.widgetWithText(GameButton, 'SIGN OUT'));
      await wait(t, const Duration(milliseconds: 900));
      expect(app.account.value.status, AccountStatus.signedOut);
      expect(app.playing, guest);
      await app.go(Routes.accountSettings);
      expect(app.path, Routes.account, reason: 'signed out: the desk');
    });

    testWidgets('DEV: deletion is explained but closed; nothing is deleted', (t) async {
      final app = await _open(t);
      await app.account.signUp(email: _email, password: _password);
      await app.go(Routes.accountSettings);
      await app.link('Delete account');
      expect(app.path, Routes.accountDelete);
      expect(find.text('Account deletion is not available in this test build yet. Nothing has been deleted.'), findsOneWidget);
      final delete = t.widget<GameButton>(find.widgetWithText(GameButton, 'DELETE MY ACCOUNT'));
      expect(delete.onPressed, isNull, reason: 'closed until the server path exists');
      expect(app.account.deletionAvailable, isFalse);
      await capture(t, 'account_delete_390x844');
      expect(app.account.value.status, AccountStatus.signedIn);
    });

  });

  test('saved game data shape is untouched by account profiles (old saves decode as before)', () {
    final old = jsonEncode(const GameProgress(detectiveName: 'ANNA').toJson());
    expect(GameProgress.fromJson(jsonDecode(old) as Map<String, dynamic>).detectiveName, 'ANNA');
  });
}
