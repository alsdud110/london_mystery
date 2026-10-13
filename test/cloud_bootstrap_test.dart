import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/cloud/cloud_bootstrap.dart';
import 'package:london_mystery/core/cloud/cloud_environment.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';

import 'helpers.dart';

FirebaseIdentity identityOf(CloudEnvironment env) => (projectId: env.projectId, appId: env.androidAppId);

void main() {
  group('which builds may start Firebase, and with which project', () {
    CloudDecision decide(String? flavor, {bool android = true, bool ios = false, bool operator = false}) =>
        CloudDecision.of(flavor: flavor, androidApp: android, iosApp: ios, operatorToolsInBuild: operator);

    test('the dev flavor uses the DEV project; the prod flavor the PROD project', () {
      expect(decide('dev').environment, CloudEnvironment.dev);
      expect(decide('prod').environment, CloudEnvironment.prod);
      expect(CloudEnvironment.dev.projectId, 'london-mystery-dev');
      expect(CloudEnvironment.prod.projectId, 'london-mystery-prod');
    });

    test('a build with operator tools never reaches PROD (it may use DEV)', () {
      expect(decide('prod', operator: true).block, CloudBlock.operatorBuildOnProduction);
      expect(decide('dev', operator: true).environment, CloudEnvironment.dev);
    });

    test('iOS: the same flavors and projects, checked against its own app ids', () {
      final dev = decide('dev', android: false, ios: true);
      expect(dev.environment, CloudEnvironment.dev);
      expect(dev.platform, CloudPlatform.ios);
      expect(decide('prod', android: false, ios: true).environment, CloudEnvironment.prod);
      expect(decide('prod', android: false, ios: true, operator: true).block, CloudBlock.operatorBuildOnProduction);
      expect(decide('dev').platform, CloudPlatform.android);
      expect(CloudEnvironment.dev.appIdFor(CloudPlatform.ios), '1:332839632440:ios:d5f9b8424ac7d924a0f0cd');
      expect(CloudEnvironment.prod.appIdFor(CloudPlatform.ios), '1:784365257039:ios:af3ac3a6032b276752053a');
      for (final env in CloudEnvironment.values) {
        expect(env.iosAppId, isNot(env.androidAppId));
        expect(env.iosAppId.split(':')[1], env.androidAppId.split(':')[1], reason: '${env.name}: the same project');
      }
      expect(CloudEnvironment.dev.iosAppId.split(':')[1], isNot(CloudEnvironment.prod.iosAppId.split(':')[1]));
    });

    test('no flavor, an unknown flavor, or a platform not set up: no Firebase at all', () {
      expect(decide(null).block, CloudBlock.noEnvironment);
      expect(decide('staging').block, CloudBlock.noEnvironment);
      expect(decide('prod', android: false).block, CloudBlock.unsupportedPlatform);
      expect(decide('dev', android: false).allowed, isFalse);
    });
  });

  group('starting Firebase never holds up the game', () {
    test('started with the expected project: ready', () async {
      var calls = 0;
      final cloud = CloudBootstrap(
        decision: const CloudDecision.start(CloudEnvironment.dev),
        initialize: () async {
          calls++;
          return identityOf(CloudEnvironment.dev);
        },
      );
      expect(cloud.value, CloudStatus.starting);
      expect(cloud.requireReady, throwsStateError, reason: 'nothing may use Firebase before it is ready');
      await Future.wait([cloud.start(), cloud.start()]);
      expect(cloud.value, CloudStatus.ready);
      expect(calls, 1, reason: 'started once');
      cloud.requireReady();
    });

    test('iOS: started with the iOS app of its project, ready; the Android app id or the other project, never', () async {
      for (final (identity, expected) in [
        ((projectId: CloudEnvironment.dev.projectId, appId: CloudEnvironment.dev.iosAppId), CloudStatus.ready),
        ((projectId: CloudEnvironment.dev.projectId, appId: CloudEnvironment.dev.androidAppId), CloudStatus.unavailable),
        ((projectId: CloudEnvironment.prod.projectId, appId: CloudEnvironment.prod.iosAppId), CloudStatus.unavailable),
      ]) {
        final cloud = CloudBootstrap(
          decision: const CloudDecision.start(CloudEnvironment.dev, CloudPlatform.ios),
          initialize: () async => identity,
        );
        await cloud.start();
        expect(cloud.value, expected, reason: '$identity');
      }
    });

    test('settings of the other project are never used', () async {
      final cloud = CloudBootstrap(
        decision: const CloudDecision.start(CloudEnvironment.dev),
        initialize: () async => identityOf(CloudEnvironment.prod),
      );
      await cloud.start();
      expect(cloud.value, CloudStatus.unavailable);
      expect(cloud.requireReady, throwsStateError);
      final wrongApp = CloudBootstrap(
        decision: const CloudDecision.start(CloudEnvironment.dev),
        initialize: () async => (projectId: 'london-mystery-dev', appId: '1:332839632440:android:fcd7ea487701e3e3a0f0cd'),
      );
      await wrongApp.start();
      expect(wrongApp.value, CloudStatus.unavailable, reason: 'the old DEV app id is not this build');
    });

    test('no settings or an error: unavailable, without throwing', () async {
      final cloud = CloudBootstrap(
        decision: const CloudDecision.start(CloudEnvironment.dev),
        initialize: () async => throw Exception('no google-services.json'),
      );
      await cloud.start();
      expect(cloud.value, CloudStatus.unavailable);
      expect(cloud.failure, contains('start failed'));
    });

    test('too slow (e.g. a stuck device): gives up after the timeout', () async {
      final never = Completer<FirebaseIdentity>();
      final cloud = CloudBootstrap(
        decision: const CloudDecision.start(CloudEnvironment.dev),
        initialize: () => never.future,
        timeout: const Duration(milliseconds: 20),
      );
      await cloud.start();
      expect(cloud.value, CloudStatus.unavailable);
      expect(cloud.failure, 'start timed out');
    });

    test('an operator build given PROD never even tries to start it', () async {
      var called = false;
      final cloud = CloudBootstrap(
        decision: CloudDecision.of(flavor: 'prod', androidApp: true, operatorToolsInBuild: true),
        initialize: () async {
          called = true;
          return identityOf(CloudEnvironment.prod);
        },
      );
      expect(cloud.value, CloudStatus.disabled);
      await cloud.start();
      expect(called, isFalse);
      expect(cloud.value, CloudStatus.disabled);
    });

    test('the guest game plays and saves while Firebase is failing', () async {
      final cloud = CloudBootstrap(
        decision: const CloudDecision.start(CloudEnvironment.dev),
        initialize: () async => throw Exception('offline'),
      );
      final c = ProviderContainer(overrides: [
        ...await testOverrides(),
        cloudBootstrapProvider.overrideWithValue(cloud),
      ]);
      addTearDown(c.dispose);
      final started = cloud.start(); // in the background, as in the app
      final game = c.read(gameControllerProvider.notifier);
      expect(game.registerDetective('ANNA'), isNull);
      game.startInvestigation();
      expect(game.submitAnswer(episode01.missions.first, 'b').coins, 30);
      await started;
      expect(cloud.value, CloudStatus.unavailable);
      expect(c.read(walletProvider).balance, 50);
      expect(c.read(progressRepositoryProvider).load().isCompleted('m01'), isTrue);
    });

    test('without an override the game has no Firebase at all', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      expect(c.read(cloudBootstrapProvider).value, CloudStatus.disabled);
    });
  });

  group('the flavors point at the right Firebase apps', () {
    test('the gradle flavors give DEV and PROD their application ids', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('applicationId = "com.londonmystery.app"'));
      expect(RegExp(r'create\("dev"\)[^}]*applicationIdSuffix = "\.dev"').hasMatch(gradle), isTrue);
      expect(RegExp(r'create\("prod"\)[^}]*applicationIdSuffix').hasMatch(gradle), isFalse);
      expect(gradle, isNot(contains('signingConfig = signingConfigs.getByName("debug")\n        }\n    }\n}')),
          reason: 'release is not signed with the debug key by the build type');
    });

    test('each flavor\'s google-services.json is the expected project and app (when present)', () {
      for (final (flavor, env, package) in [
        ('dev', CloudEnvironment.dev, 'com.londonmystery.app.dev'),
        ('prod', CloudEnvironment.prod, 'com.londonmystery.app'),
      ]) {
        final file = File('android/app/src/$flavor/google-services.json');
        if (!file.existsSync()) {
          markTestSkipped('$flavor config not on this checkout (git-ignored)');
          continue;
        }
        final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect((json['project_info'] as Map)['project_id'], env.projectId, reason: flavor);
        final clients = {
          for (final c in json['client'] as List)
            (c['client_info']['android_client_info']['package_name'] as String): c['client_info']['mobilesdk_app_id'],
        };
        expect(clients[package], env.androidAppId, reason: '$flavor: the app this build uses');
      }
    });

    test("each iOS flavor's GoogleService-Info.plist is the expected project, app and bundle (when present)", () {
      for (final (flavor, env, bundle) in [
        ('dev', CloudEnvironment.dev, 'com.londonmystery.app.dev'),
        ('prod', CloudEnvironment.prod, 'com.londonmystery.app'),
      ]) {
        final file = File('ios/config/$flavor/GoogleService-Info.plist');
        if (!file.existsSync()) {
          markTestSkipped('iOS $flavor config not on this checkout (git-ignored)');
          continue;
        }
        String value(String key) =>
            RegExp('<key>$key</key>\\s*<string>([^<]*)</string>').firstMatch(file.readAsStringSync())!.group(1)!;
        expect(value('PROJECT_ID'), env.projectId, reason: flavor);
        expect(value('GOOGLE_APP_ID'), env.iosAppId, reason: flavor);
        expect(value('BUNDLE_ID'), bundle, reason: flavor);
      }
    });

    test('the iOS build gives each flavor its own bundle id and config folder', () {
      final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      expect(pbx, contains('LM_FLAVOR = dev;'));
      expect(pbx, contains('LM_FLAVOR = prod;'));
      expect(pbx, contains('PRODUCT_BUNDLE_IDENTIFIER = com.londonmystery.app.dev;'));
      expect(pbx, contains(r'config/${LM_FLAVOR}/GoogleService-Info.plist'));
      expect(pbx, contains('BUNDLE_ID'), reason: 'the copy refuses a config made for another bundle id');
      for (final flavor in ['dev', 'prod']) {
        final scheme = File('ios/Runner.xcodeproj/xcshareddata/xcschemes/$flavor.xcscheme').readAsStringSync();
        for (final c in ['Debug', 'Release', 'Profile']) {
          if (scheme.contains('buildConfiguration = "$c"')) fail('$flavor scheme uses plain $c');
        }
        expect(scheme, contains('buildConfiguration = "Debug-$flavor"'));
        expect(scheme, contains('buildConfiguration = "Release-$flavor"'));
      }
    });

    test('firebase.json records the same mapping', () {
      final file = File('firebase.json');
      if (!file.existsSync()) return markTestSkipped('no firebase.json');
      final configs = jsonDecode(file.readAsStringSync())['flutter']['platforms']['android']['buildConfigurations'] as Map;
      final byPath = {for (final v in configs.values) (v['fileOutput'] as String): v};
      expect(byPath['android/app/src/dev/google-services.json']['projectId'], CloudEnvironment.dev.projectId);
      expect(byPath['android/app/src/dev/google-services.json']['appId'], CloudEnvironment.dev.androidAppId);
      expect(byPath['android/app/src/prod/google-services.json']['projectId'], CloudEnvironment.prod.projectId);
      expect(byPath['android/app/src/prod/google-services.json']['appId'], CloudEnvironment.prod.androidAppId);
    });
  });
}
