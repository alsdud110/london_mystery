import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'cloud_environment.dart';

/// The local Firebase emulators (Auth and Firestore) a DEV build may be
/// pointed at for testing the cloud sync (Phase 4.3B-1):
///
///     flutter run --flavor dev --dart-define=LM_CLOUD_EMULATOR=localhost
///
/// (`10.0.2.2` from an Android emulator.) Only the DEV environment may use
/// it; a PROD build ignores it. Until the sync is approved for the real DEV
/// project (Phase 4.3B-2), the app syncs only in such a build: without it,
/// nothing reads or writes game data in any Firebase project.
@immutable
class CloudEmulator {
  const CloudEmulator(this.host, {this.firestorePort = 8080, this.authPort = 9099});

  /// The host given to this build (empty: none).
  static const buildHost = String.fromEnvironment('LM_CLOUD_EMULATOR');

  /// The emulators for a build that starts Firebase with [decision], or null
  /// (no emulator host given, or not the DEV environment).
  static CloudEmulator? forBuild(CloudDecision decision, {String host = buildHost}) =>
      host.isNotEmpty && decision.environment == CloudEnvironment.dev ? CloudEmulator(host) : null;

  final String host;
  final int firestorePort;
  final int authPort;

  /// Points Auth and Firestore at the emulators. Must run once Firebase has
  /// started and before either is used (see `CloudBootstrap.beforeReady`);
  /// throws unless Firestore now talks to the emulator.
  Future<void> connect() async {
    final db = FirebaseFirestore.instance;
    // Once per process (an integration test may start the app again).
    if (!_connected) {
      db.useFirestoreEmulator(host, firestorePort);
      await FirebaseAuth.instance.useAuthEmulator(host, authPort);
      _connected = true;
    }
    if (!uses(db)) throw StateError('Firestore is not on the emulator');
    debugPrint('Cloud: local emulators ($host)');
  }

  static bool _connected = false;

  /// Whether [db] talks to these emulators (never a real project).
  bool uses(FirebaseFirestore db) => db.settings.host?.startsWith(host) ?? false;
}
