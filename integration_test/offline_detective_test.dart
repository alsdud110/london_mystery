import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/utils/audio_service.dart';
import 'package:london_mystery/data/mock/season1/season1_discoveries.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/onboarding/detective_hold_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/full_playthrough_test.dart' show tapText, wait;
import '../test/mission_play.dart';

/// On a real device or simulator, with the device's own storage: a new
/// detective is created, a mission is played and rewarded once, and a
/// restart of the game (a new start on the same storage) finds it all.
/// Run with the network off to check the game needs none:
///   flutter test integration_test/offline_detective_test.dart -d DEVICE_ID
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<WidgetRef> startGame(WidgetTester t, SharedPreferences prefs) async {
    final store = ProfileStore(prefs);
    final start = await store.bootstrap();
    final catalog = MockEpisodeRepository.bundled();
    late WidgetRef ref;
    await t.pumpWidget(DeviceDetectiveGate(
      start: start,
      store: store,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        episodeCatalogProvider.overrideWithValue(catalog),
        // Silent: sound is not what this checks.
        audioServiceProvider.overrideWithValue(MockAudioService()),
      ],
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const LondonMysteryApp();
      }),
    ));
    await wait(t, const Duration(milliseconds: 1500));
    return ref;
  }

  testWidgets('a new detective, a mission played offline, kept after a restart', (t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // First start: CREATE YOUR DETECTIVE.
    var ref = await startGame(t, prefs);
    await tapText(t, 'START ADVENTURE', after: const Duration(milliseconds: 1200));
    expect(find.text('CREATE YOUR DETECTIVE'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('avatar-girl')));
    await t.pump();
    await t.enterText(find.byType(TextField), 'anna');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await wait(t, const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('how-to-play-welcome')), findsOneWidget, reason: 'How to Play comes next');
    final profile = ProfileStore(prefs).profile!;
    expect((profile.detectiveName, profile.avatar), ('ANNA', DetectiveAvatar.girl));

    // The first mission of Case 01, played as a child would.
    ref.read(gameControllerProvider.notifier).startInvestigation();
    ref.read(routerProvider).go(Routes.mission('m01'));
    await wait(t, const Duration(milliseconds: 1500));
    final m = ref.read(currentEpisodeProvider).missionById('m01')!;
    await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 1200));
    await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1500));
    await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 1200));
    final coinsBefore = ref.read(walletProvider).balance;
    await MissionPlay().solve(t, m);
    await wait(t, const Duration(milliseconds: 2800));
    expect(find.text(discoveryOf(m).type.cheer), findsOneWidget);
    expect(find.textContaining('+30 XP'), findsOneWidget);
    expect(ref.read(walletProvider).balance - coinsBefore, WalletController.coinsFor(m));
    await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 1500));
    expect(ref.read(gameControllerProvider).isCompleted('m01'), isTrue);
    final coins = ref.read(walletProvider).balance;

    // The game starts again on the same storage: everything is there.
    await t.pumpWidget(const SizedBox());
    await wait(t, const Duration(milliseconds: 300));
    ref = await startGame(t, prefs);
    expect(find.text('Welcome back, Detective ANNA!'), findsOneWidget);
    expect(find.text('CONTINUE ADVENTURE'), findsOneWidget);
    expect(find.text('START ADVENTURE'), findsNothing);
    expect(ref.read(gameControllerProvider).isCompleted('m01'), isTrue);
    expect(ref.read(walletProvider).balance, coins);
    expect(ref.read(detectiveProfileProvider).avatar, DetectiveAvatar.girl);
    expect(ref.read(gameControllerProvider.notifier).createDetective('Ben', DetectiveAvatar.boy), isNotNull,
        reason: 'never a second detective');
    await prefs.clear();
  });
}
