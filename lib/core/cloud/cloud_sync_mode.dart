import 'package:firebase_core/firebase_core.dart';

import 'cloud_emulator.dart';
import 'cloud_environment.dart';

/// Where this build syncs game data, if anywhere. Only a DEV build that was
/// explicitly given a test option syncs at all:
///
/// - `--dart-define=LM_CLOUD_EMULATOR=<host>`: the local emulators (4.3B-1).
/// - `--dart-define=LM_CLOUD_SYNC=dev`: the real DEV project (4.3B-2 tests).
///
/// Every other build (a plain DEV run, any PROD build, whatever it is given)
/// syncs nothing and reads no consent record: [off].
///
/// An operator build (debug, `LM_PLAYTEST`) may sync with DEV, its
/// development backend: `SyncPolicy.buildMayUseLiveCloud` keeps such builds
/// off the live cloud (PROD), which `CloudDecision` already refuses to start.
/// Operator (playtest) records are never sent either way.
enum CloudSyncMode {
  off,
  emulator,
  dev;

  /// The sync option given to this build (empty: none).
  static const buildOption = String.fromEnvironment('LM_CLOUD_SYNC');

  static CloudSyncMode forBuild(
    CloudDecision decision, {
    String emulatorHost = CloudEmulator.buildHost,
    String option = buildOption,
  }) {
    // DEV only: PROD (and a build that may not start Firebase) never syncs.
    if (decision.environment != CloudEnvironment.dev) return off;
    if (emulatorHost.isNotEmpty) return emulator;
    if (option == 'dev') return dev;
    return off;
  }

  /// Before the real DEV project is used: Firebase must have started with
  /// exactly the DEV project and this platform's DEV app (checked again here,
  /// on top of `CloudBootstrap`'s start check). Throws otherwise.
  static void requireDevApp(CloudDecision decision, FirebaseOptions options) {
    final platform = decision.platform;
    if (decision.environment != CloudEnvironment.dev ||
        platform == null ||
        options.projectId != CloudEnvironment.dev.projectId ||
        options.appId != CloudEnvironment.dev.appIdFor(platform)) {
      throw StateError('not the DEV app');
    }
  }
}
