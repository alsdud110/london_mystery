// The account screens against the real DEV Firebase project, as a player
// uses them, on an Android emulator or device, or an iOS simulator:
//   flutter test integration_test/account_flow_dev_test.dart --flavor dev -d <device>
// Starts the real app (main), makes one throw-away account in
// london-mystery-dev through the Account Desk, signs out and in again, and
// deletes that account at the end. Refuses to run against any other
// project. The guest detective and its saves must come through untouched.
// (A check email goes to a reserved example.com address and is not read.)
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:london_mystery/core/cloud/cloud_environment.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/features/account/account_controller.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/profile/profile_session.dart';
import 'package:london_mystery/main.dart' as app;
import 'package:london_mystery/widgets/game_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Frames run as on a phone (the title page animates; pages fade in).
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('DEV: sign up, sign out, sign in through the screens; the guest is untouched', (t) async {
    expect(appFlavor, 'dev', reason: 'only the dev flavor');
    final rnd = Random.secure();
    final email = 'lm-qa-ui-${DateTime.now().millisecondsSinceEpoch}-${rnd.nextInt(1 << 20)}@example.com';
    final password = 'Qa${rnd.nextInt(1 << 30)}x9';

    await app.main();
    await t.pump(const Duration(milliseconds: 500)); // first frame: Firebase starts after it
    ProfileSessionHostState host() => t.state<ProfileSessionHostState>(find.byType(ProfileSessionHost));
    AccountController account() => host().container.read(accountControllerProvider);
    String path() => host().container.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

    Future<void> until(bool Function() done, String what, {int seconds = 40}) async {
      for (var i = 0; i < seconds * 4; i++) {
        if (done()) return;
        await t.pump(const Duration(milliseconds: 250));
      }
      final shown = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().toList();
      fail('timed out: $what (at ${path()}, showing: ${shown.take(25).join(' | ')})');
    }

    /// On [route], with its page faded in.
    Future<void> arrive(String route) async {
      await until(() => path() == route, 'page $route');
      await t.pump(const Duration(milliseconds: 900));
    }

    Future<void> go(String location) async {
      final router = host().container.read(routerProvider);
      router.go(location);
      await until(() => router.routerDelegate.currentConfiguration.uri.toString() == location, 'page $location');
      await t.pump(const Duration(milliseconds: 900)); // the page's fade
    }

    Future<void> type(String label, String text) async {
      final f = find.widgetWithText(TextField, label);
      await t.ensureVisible(f);
      await t.enterText(f, text);
      await t.pump(const Duration(milliseconds: 100));
    }

    Future<void> press(String label) async {
      // The keyboard goes down first (the page moves when it does), as a
      // player's tap on the button would do.
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pump(const Duration(milliseconds: 600));
      final b = find.widgetWithText(GameButton, label);
      await t.ensureVisible(b);
      await t.pump(const Duration(milliseconds: 200));
      await t.tap(b);
      await t.pump(const Duration(milliseconds: 300));
    }

    Future<void> link(String label) async {
      final l = find.widgetWithText(TextButton, label);
      await t.ensureVisible(l);
      await t.pump(const Duration(milliseconds: 200));
      await t.tap(l);
      await t.pump(const Duration(milliseconds: 600));
    }

    try {
      await until(() => account().value.status == AccountStatus.signedOut, 'Firebase ready, signed out', seconds: 30);
      expect(Firebase.app().options.projectId, CloudEnvironment.dev.projectId, reason: 'never another project');

      // The guest has played a little: its saves are the "before".
      final guest = host().session.profileId;
      expect(host().session.profile.kind, ProfileKind.guest);
      final game = host().container.read(gameControllerProvider.notifier);
      if (!host().container.read(gameControllerProvider).hasDetective) game.registerDetective('QA GUEST');
      final prefs = await SharedPreferences.getInstance();
      Map<String, Object?> guestSaves() => {
            for (final k in prefs.getKeys())
              if (k.contains(guest) && !k.endsWith('.outbox.v1')) k: _withoutClock(prefs.get(k)),
          };
      final before = guestSaves();
      expect(before, isNotEmpty);

      // 1. New account through the Account Desk.
      await go(Routes.newAccount);
      expect(find.text('NEW ACCOUNT'), findsOneWidget);
      await type('Email', email);
      await type('Password', password);
      await type('Password again', password);
      await press('CREATE ACCOUNT');
      await arrive(Routes.accountVerify);
      final uid = account().value.uid!;
      expect(account().value.cloudFeaturesAllowed, isFalse, reason: 'consent is never confirmed by signing up');
      expect(find.textContaining('lm•••@ex•••.com'), findsOneWidget);
      expect(host().session.profileId, guest, reason: 'signing up keeps the guest playing');

      // 2. A detective for the account; the guest is still listed.
      await link('Later');
      await arrive(Routes.profiles);
      expect(find.text('QA GUEST'), findsWidgets);
      await press('NEW DETECTIVE');
      await arrive(Routes.newProfile);
      await type('Detective name', 'QA ACCOUNT');
      await press('CREATE DETECTIVE');
      await until(() => host().session.profileId != guest, 'the new detective playing');
      final mine = ProfileStore(prefs).profile(host().session.profileId)!;
      expect(mine.ownerUid, uid);
      expect(mine.detectiveName, 'QA ACCOUNT');

      // 3. Sign out from the account page: back to the guest.
      await go(Routes.accountSettings);
      expect(find.text('lm•••@ex•••.com'), findsOneWidget);
      expect(find.text('Not available yet'), findsOneWidget, reason: 'cloud save');
      expect(find.text('Delete account'), findsOneWidget, reason: 'DEV shows the (closed) deletion page');
      await link('Sign out');
      await press('SIGN OUT');
      await until(() => account().value.status == AccountStatus.signedOut, 'signed out');
      await until(() => host().session.profileId == guest, 'the guest playing again');

      // 4. Sign in again through the Account Desk: the same account.
      await go(Routes.account);
      await type('Email', email);
      await type('Password', password);
      await press('SIGN IN');
      await until(() => account().value.uid == uid, 'signed in as the same user');
      await arrive(Routes.accountVerify);
      await go(Routes.profiles);
      expect(find.text('QA ACCOUNT'), findsOneWidget, reason: "the account's detective comes back");

      // 5. Wrong password: refused, nobody signed in, the guest plays.
      await account().signOut();
      await until(() => host().session.profileId == guest, 'the guest after sign-out');
      await go(Routes.account);
      await type('Email', email);
      await type('Password', '${password}wrong');
      await press('SIGN IN');
      await until(() => find.text('That email or password is not right.').evaluate().isNotEmpty, 'the error');
      expect(account().value.status, AccountStatus.signedOut);

      expect(guestSaves(), before, reason: 'the guest and its saves are untouched');
    } finally {
      // Remove the throw-away account (this device signed it in moments ago).
      // (Firebase never started: no account was made.)
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser?.email == email
            ? FirebaseAuth.instance.currentUser
            : await FirebaseAuth.instance
                .signInWithEmailAndPassword(email: email, password: password)
                .then((c) => c.user, onError: (Object _) => null); // not made: nothing to remove
        await user?.delete();
        await FirebaseAuth.instance.signOut();
      }
      // Take the app down (the title page animates for ever).
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(milliseconds: 300));
    }
  });
}

/// A save without what a switch of detective rewrites on its own: the play
/// clock banked on leaving, and that save's revision counter.
Object? _withoutClock(Object? v) {
  if (v is! String || !v.contains('"playMillis"')) return v;
  return (jsonDecode(v) as Map<String, dynamic>)
    ..remove('playMillis')
    ..remove('rev');
}
