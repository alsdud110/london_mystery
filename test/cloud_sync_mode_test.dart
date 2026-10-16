import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/cloud/cloud_environment.dart';
import 'package:london_mystery/core/cloud/cloud_sync_mode.dart';

/// Phase 4.3B-2: which builds sync game data, and with which project.
void main() {
  const dev = CloudDecision.start(CloudEnvironment.dev, CloudPlatform.android);
  const devIos = CloudDecision.start(CloudEnvironment.dev, CloudPlatform.ios);
  const prod = CloudDecision.start(CloudEnvironment.prod, CloudPlatform.android);

  test('only a DEV build given a test option syncs', () {
    expect(CloudSyncMode.forBuild(dev, emulatorHost: '', option: ''), CloudSyncMode.off, reason: 'a plain DEV run');
    expect(CloudSyncMode.forBuild(dev, emulatorHost: '', option: 'dev'), CloudSyncMode.dev);
    expect(CloudSyncMode.forBuild(dev, emulatorHost: '', option: 'prod'), CloudSyncMode.off);
    expect(CloudSyncMode.forBuild(dev, emulatorHost: '', option: 'DEV'), CloudSyncMode.off, reason: 'exactly "dev"');
    expect(CloudSyncMode.forBuild(dev, emulatorHost: '10.0.2.2', option: 'dev'), CloudSyncMode.emulator,
        reason: 'the emulators win: never both');
  });

  test('PROD and builds without Firebase never sync, whatever they are given', () {
    for (final option in ['', 'dev', 'prod']) {
      expect(CloudSyncMode.forBuild(prod, emulatorHost: '', option: option), CloudSyncMode.off);
      expect(CloudSyncMode.forBuild(prod, emulatorHost: 'localhost', option: option), CloudSyncMode.off);
      for (final block in CloudBlock.values) {
        expect(CloudSyncMode.forBuild(CloudDecision.blocked(block), emulatorHost: 'localhost', option: option), CloudSyncMode.off);
      }
    }
    // An operator (debug) build given PROD is blocked before anything.
    final operatorProd = CloudDecision.of(flavor: 'prod', androidApp: true, operatorToolsInBuild: true);
    expect(operatorProd.block, CloudBlock.operatorBuildOnProduction);
    expect(CloudSyncMode.forBuild(operatorProd, emulatorHost: '', option: 'dev'), CloudSyncMode.off);
  });

  test('an operator (debug, LM_PLAYTEST) build may use DEV, never PROD (SyncPolicy: no live cloud)', () {
    // The integration tests are debug builds: DEV is their development
    // backend. PROD is refused before anything starts.
    final operatorDev = CloudDecision.of(flavor: 'dev', androidApp: true, operatorToolsInBuild: true);
    expect(CloudSyncMode.forBuild(operatorDev, emulatorHost: '', option: 'dev'), CloudSyncMode.dev);
    final operatorProd = CloudDecision.of(flavor: 'prod', androidApp: true, operatorToolsInBuild: true);
    expect(operatorProd.allowed, isFalse);
    expect(CloudSyncMode.forBuild(operatorProd, emulatorHost: '', option: 'dev'), CloudSyncMode.off);
  });

  test('the real DEV project is used only with the DEV project and this platform\'s DEV app', () {
    FirebaseOptions options(String project, String app) =>
        FirebaseOptions(apiKey: 'k', appId: app, messagingSenderId: 's', projectId: project);
    final env = CloudEnvironment.dev;
    expect(() => CloudSyncMode.requireDevApp(dev, options(env.projectId, env.androidAppId)), returnsNormally);
    expect(() => CloudSyncMode.requireDevApp(devIos, options(env.projectId, env.iosAppId)), returnsNormally);
    expect(() => CloudSyncMode.requireDevApp(dev, options(env.projectId, env.iosAppId)), throwsStateError,
        reason: 'the other platform\'s app');
    expect(() => CloudSyncMode.requireDevApp(dev, options('london-mystery-prod', env.androidAppId)), throwsStateError);
    final p = CloudEnvironment.prod;
    expect(() => CloudSyncMode.requireDevApp(prod, options(p.projectId, p.androidAppId)), throwsStateError);
  });
}
