import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season2/season2_mock.dart';
import 'package:london_mystery/data/models/difficulty.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/features/game/game_providers.dart';

import 'difficulty_paris_7d_test.dart' show parisAt, pk;
import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

void main() {
  const scenes = ['lastClue', 'journey', 'arrival', 'missingHour', 'promise', 'firstCase'];

  /// Every spoken line of a scene (its `lines`, or the case file's `line`).
  List<String> spoken(Map<String, dynamic> words, String scene) {
    final s = words[scene] as Map<String, dynamic>;
    return [...(s['lines'] as List? ?? const []).cast<String>(), if (s['line'] != null) s['line'] as String];
  }

  group('the words at each level', () {
    test('Rookie is the base, as it was', () {
      expect(season2PrologueAt(Difficulty.rookie), season2PrologueJson);
    });

    test('the same six scenes, in order; only the lines change', () {
      for (final level in Difficulty.values) {
        final words = season2PrologueAt(level);
        expect(words.keys.toList(), scenes, reason: level.name);
        for (final scene in scenes) {
          final base = season2PrologueJson[scene] as Map<String, dynamic>;
          final at = words[scene] as Map<String, dynamic>;
          expect(at.keys.toSet(), base.keys.toSet(), reason: '$scene at ${level.name}');
          for (final key in base.keys.where((k) => k != 'lines' && k != 'line')) {
            expect(at[key], base[key], reason: '$scene.$key at ${level.name}');
          }
          expect(spoken(words, scene), hasLength(spoken(season2PrologueJson, scene).length), reason: '$scene at ${level.name}');
        }
      }
    });

    test('Junior and Master have words of their own in every scene', () {
      for (final scene in scenes) {
        expect({for (final level in Difficulty.values) spoken(season2PrologueAt(level), scene).join('|')}, hasLength(3), reason: scene);
      }
    });

    test('the same facts at every level, nothing told before its time', () {
      for (final level in Difficulty.values) {
        final words = season2PrologueAt(level);
        expect(spoken(words, 'journey').first, allOf(contains('London'), contains('11:40'), contains('from Paris')), reason: level.name);
        expect(spoken(words, 'promise').last, contains('Paris stands still'), reason: level.name);
        expect(spoken(words, 'missingHour').join(' '), contains('Paris'), reason: level.name);
        final all = [for (final scene in scenes) ...spoken(words, scene)].join(' ').toLowerCase();
        for (final banned in ['émile', 'emile', 'moreau', 'victor', 'delacroix', 'big ben', 'trial']) {
          expect(all, isNot(contains(banned)), reason: '$banned at ${level.name}');
        }
      }
    });
  });

  group('the level it is played at', () {
    late WidgetRef appRef;

    /// Case 01 not begun: the detective's name only.
    const named = {'s2_ep01': GameProgress(detectiveName: 'KIM')};

    Future<void> pumpApp(WidgetTester t, Map<String, Object> prefs) async {
      t.view.physicalSize = const Size(360, 640) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: prefs),
        child: Consumer(builder: (context, ref, _) {
          appRef = ref;
          return const LondonMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      appRef.read(routerProvider).go(Routes.parisPrologue);
      await wait(t, const Duration(milliseconds: 2000));
    }

    /// Walks all six scenes, finding [level]'s lines in each.
    Future<void> expectWords(WidgetTester t, Difficulty level) async {
      final words = season2PrologueAt(level);
      expect(appRef.read(routerProvider).routerDelegate.currentConfiguration.uri.toString(), Routes.parisPrologue);
      for (final (i, scene) in scenes.indexed) {
        for (final line in spoken(words, scene)) {
          expect(find.text(line), findsOneWidget, reason: '$scene at ${level.name}');
        }
        if (i < 4) {
          await t.tap(find.text('NEXT ›'));
          await wait(t, const Duration(milliseconds: 2400));
        } else if (i == 4) {
          await t.tap(find.text('ACCEPT THE CASE'));
          await wait(t, const Duration(milliseconds: 2000));
        }
      }
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    }

    for (final level in Difficulty.values) {
      testWidgets('Paris fixed at ${level.name}: its words, whatever the profile says', (t) async {
        final other = Difficulty.values[(level.index + 1) % Difficulty.values.length];
        await pumpApp(t, parisAt(level, active: 's2_ep01', profile: other, progress: named));
        expect(appRef.read(seasonDifficultyProvider(SeasonIds.paris)), level);
        await expectWords(t, level);
      });
    }

    testWidgets('Paris not begun yet: the level it will be fixed at (the detective\'s), not London\'s', (t) async {
      final prefs = parisAt(Difficulty.master, active: 's2_ep01', progress: named)
        ..[pk(AppConstants.seasonKeyFor(SeasonIds.paris))] = jsonEncode(const SeasonProgress(activeEpisodeId: 's2_ep01').toJson());
      await pumpApp(t, prefs);
      expect(appRef.read(seasonLevelProvider(SeasonIds.paris))!.begun, isFalse);
      expect(appRef.read(seasonDifficultyProvider(SeasonIds.london)), isNot(Difficulty.master), reason: 'London played at another level');
      await expectWords(t, Difficulty.master);
    });
  });
}
