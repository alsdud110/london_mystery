// Real user sign-in against the DEV Firebase project, on an Android
// emulator or device:
//   flutter test integration_test/auth_dev_test.dart --flavor dev -d <device>
// It makes one throw-away account in london-mystery-dev and deletes it at
// the end. It refuses to run against any other project. It sends no emails.
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:london_mystery/core/cloud/cloud_environment.dart';
import 'package:london_mystery/features/account/firebase_auth_service.dart';
import 'package:london_mystery/features/account/auth_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user sign-up, sign-in, re-authentication and sign-out on DEV', (t) async {
    expect(appFlavor, 'dev', reason: 'only the dev flavor');
    final app = await Firebase.initializeApp();
    expect(app.options.projectId, CloudEnvironment.dev.projectId, reason: 'never another project');
    expect(app.options.appId, CloudEnvironment.dev.androidAppId);

    final auth = FirebaseAuthService();
    await FirebaseAuth.instance.signOut();
    final rnd = Random.secure();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'lm-qa-$stamp-${rnd.nextInt(1 << 20)}@example.com';
    final password = 'Qa${rnd.nextInt(1 << 30)}x9';

    try {
      final up = await auth.signUp(email: email, password: password);
      expect(up.ok, isTrue, reason: '${up.failure}');
      final uid = up.session!.uid;
      expect(uid, isNotEmpty);
      expect(up.session!.emailVerified, isFalse);
      expect(auth.current?.uid, uid);

      expect((await auth.signUp(email: email, password: password)).failure, AuthFailure.emailInUse);

      await auth.signOut();
      expect(auth.current, isNull);
      expect((await auth.signIn(email: email, password: '${password}wrong')).failure, AuthFailure.wrongCredentials);
      expect((await auth.signIn(email: 'nobody-$stamp@example.com', password: password)).failure,
          AuthFailure.wrongCredentials);

      final back = await auth.signIn(email: email, password: password);
      expect(back.ok, isTrue, reason: '${back.failure}');
      expect(back.session!.uid, uid, reason: 'the same user');

      expect((await auth.reauthenticate('${password}wrong')).failure, AuthFailure.wrongCredentials);
      expect((await auth.reauthenticate(password)).ok, isTrue);
      expect((await auth.refreshEmailVerified()).session!.emailVerified, isFalse);

      final seen = await auth.sessions().first;
      expect(seen?.uid, uid);
    } finally {
      // Remove the throw-away account (re-authenticated just above).
      final user = FirebaseAuth.instance.currentUser ??
          (await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password)).user;
      await user?.delete();
      await FirebaseAuth.instance.signOut();
    }
  });
}
