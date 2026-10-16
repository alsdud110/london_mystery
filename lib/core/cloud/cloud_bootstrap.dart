import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cloud_environment.dart';

/// Where Firebase stands on this device.
enum CloudStatus {
  /// This build does not use Firebase (see [CloudBlock]).
  disabled,

  /// Not started yet, or starting.
  starting,

  /// Could not start (no settings, an error, too slow, or the settings of
  /// another project). The game goes on as before, guest only.
  unavailable,

  /// Started with the expected project. User accounts may use it.
  ready,
}

/// The project and app Firebase actually started with.
typedef FirebaseIdentity = ({String projectId, String appId});

/// Starts Firebase in the background once the game is on screen. Nothing in
/// the game waits for it or needs it: the guest game and its local saves run
/// the same whether it starts, fails, or is never started. User accounts
/// and cloud features must ask [requireReady] first.
///
/// Device-wide (outside the profile sessions), so switching profiles does
/// not restart it.
class CloudBootstrap extends ValueNotifier<CloudStatus> {
  CloudBootstrap({
    required this.decision,
    Future<FirebaseIdentity> Function()? initialize,
    this.beforeReady,
    this.timeout = const Duration(seconds: 10),
  })  : _initialize = initialize ?? _initializeFirebase,
        super(decision.allowed ? CloudStatus.starting : CloudStatus.disabled);

  /// A bootstrap that never starts anything (tests, guest-only builds).
  CloudBootstrap.disabled() : this(decision: const CloudDecision.blocked(CloudBlock.noEnvironment));

  final CloudDecision decision;
  final Future<FirebaseIdentity> Function() _initialize;
  final Duration timeout;

  /// Runs after Firebase started with the expected project and before
  /// anyone sees [CloudStatus.ready] (e.g. pointing Auth and Firestore at the
  /// local emulators, see `CloudEmulator`). A failure makes it unavailable.
  final Future<void> Function()? beforeReady;

  /// Why it is [CloudStatus.unavailable] (a short code, never secrets).
  String? failure;

  Future<void>? _started;

  /// Starts once; later calls wait for the same start. Never throws.
  Future<void> start() => _started ??= _start();

  Future<void> _start() async {
    final env = decision.environment;
    if (env == null) {
      debugPrint('Cloud: off for this build (${decision.block!.name})');
      return;
    }
    try {
      final identity = await _initialize().timeout(timeout);
      if (identity.projectId != env.projectId || identity.appId != env.appIdFor(decision.platform!)) {
        // Settings of another project or app: never used.
        _fail('settings do not match ${env.name}');
        return;
      }
      await beforeReady?.call();
      value = CloudStatus.ready;
      debugPrint('Cloud: ready (${env.name})');
    } on TimeoutException {
      _fail('start timed out');
    } catch (e) {
      // No settings (a checkout without google-services.json), or a platform
      // error: only the kind is logged.
      _fail('start failed (${e.runtimeType})');
    }
  }

  void _fail(String why) {
    failure = why;
    value = CloudStatus.unavailable;
    debugPrint('Cloud: unavailable — $why; playing as a guest');
  }

  /// For user accounts and cloud features: throws unless Firebase started
  /// with the expected project. Nothing may call Firebase before this passes.
  void requireReady() {
    if (value != CloudStatus.ready) throw StateError('Firebase is not ready (${value.name})');
  }

  static Future<FirebaseIdentity> _initializeFirebase() async {
    // Android reads the flavor's google-services.json, iOS the flavor's
    // GoogleService-Info.plist (each copied into the app by its build).
    final app = await Firebase.initializeApp();
    return (projectId: app.options.projectId, appId: app.options.appId);
  }
}

/// The device's Firebase bootstrap, given to every profile session by
/// `main()`. Disabled unless overridden.
final cloudBootstrapProvider = Provider<CloudBootstrap>((ref) => CloudBootstrap.disabled());
