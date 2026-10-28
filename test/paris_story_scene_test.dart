import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// Paris's story after a solve: MISSION (or CASE) COMPLETE, then the story
/// itself, with no "Great work, Detective …" between (the Discovery Moment
/// has just cheered the solve); the newest line in view above the unlocked
/// card, TO THE MAP on screen, on three phones. Season 1 keeps its
/// greeting (`story_scene_scenery_test.dart`).
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final paris = [for (final id in ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05']) inGame.firstWhere((e) => e.id == id)];

  setUpAll(() async {
    for (final (family, files) in [
      ('Sentient', ['Sentient-Variable.ttf']),
      ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  test('only Season 2 leaves the greeting out', () {
    for (final e in paris) {
      for (final m in e.allMissions) {
        expect(SeasonCatalog.storyGreeting(m), isFalse, reason: m.id);
      }
    }
    for (final e in s1) {
      for (final m in e.allMissions) {
        expect(SeasonCatalog.storyGreeting(m), isTrue, reason: m.id);
      }
    }
  });

  // The scenes whose last line was once under the card on a small phone,
  // Case 01's first, and a case's closing scene.
  const scenes = [('s2_ep01', 's2_ep01_m1'), ('s2_ep03', 's2_ep03_m2'), ('s2_ep04', 's2_ep04_m3'), ('s2_ep05', 's2_ep05_m1'), ('s2_ep05', 's2_ep05_m3'), ('s2_ep05', 's2_ep05_final')];

  for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('$tag: no greeting; the story, its newest line in view, and the way on', (t) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      GameProgress solved(Episode e) => GameProgress(
            detectiveName: 'MINYOUNG',
            introSeen: true,
            completedMissionIds: [for (final m in e.allMissions) m.id],
            startedAt: DateTime(2026, 10, 20, 10),
            completedAt: DateTime(2026, 10, 20, 10, 30),
            playMillis: 0,
          );
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: [
          ...await testOverrides(prefs: {
            AppConstants.progressStorageKey: jsonEncode(solved(s1.first).toJson()),
            for (final e in s1.skip(1)) AppConstants.progressKeyFor(e.id): jsonEncode(solved(e).toJson()),
            AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]).toJson()),
          }),
        ],
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const WorldMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      final router = ref.read(routerProvider);
      // The case open now (index in [paris]); the cases before it are solved.
      var at = -1;
      bool done(String id) => ref.read(gameControllerProvider).isCompleted(id);

      for (final (caseId, missionId) in scenes) {
        // Off the last story before the game moves on (as in the game: the
        // board, never a story page left open under another case).
        router.go(Routes.season);
        await wait(t, const Duration(milliseconds: 600));
        final ci = paris.indexWhere((c) => c.id == caseId);
        while (at < ci) {
          if (at >= 0) {
            for (final m in paris[at].allMissions) {
              if (!done(m.id)) game.submitAnswer(m, m.answer);
            }
          }
          at++;
          expect(game.openEpisode(paris[at].id), isTrue, reason: paris[at].id);
          game.startInvestigation();
        }
        final e = paris[ci];
        final m = e.missionById(missionId)!;
        for (final x in e.allMissions) {
          if (!done(x.id)) game.submitAnswer(x, x.answer);
          if (x.id == missionId) break;
        }

        router.go(Routes.story(m.id));
        await wait(t, const Duration(milliseconds: 600));
        await t.tapAt(Offset(size.width / 2, size.height / 2)); // the whole story at once
        await wait(t, const Duration(milliseconds: 1600));
        expect(t.takeException(), isNull, reason: '$tag $missionId');

        expect(find.text(m.isFinal ? 'CASE ${e.numberLabel} COMPLETE' : 'MISSION ${m.numberLabel} COMPLETE'), findsOneWidget, reason: missionId);
        expect(find.byKey(const ValueKey('scene-greeting')), findsNothing, reason: missionId);
        expect(find.textContaining('Great work'), findsNothing, reason: missionId);

        final cta = find.text(m.isFinal ? 'SEE MY CASE REPORT' : 'TO THE MAP');
        expect(cta, findsOneWidget, reason: missionId);
        expect(t.getRect(cta).bottom, lessThanOrEqualTo(size.height), reason: '$missionId: the way on, on screen');
        if (!m.isFinal) {
          // The newest line, whole, above the unlocked card.
          final last = findReadable(m.transition.last);
          expect(last, findsOneWidget, reason: missionId);
          final next = e.missionById(m.nextMissionId!)!;
          final card = find.text(next.location);
          expect(card, findsOneWidget, reason: '$missionId: the unlocked card');
          expect(t.getRect(last).bottom, lessThanOrEqualTo(t.getRect(card).top), reason: '$tag $missionId: the last line above the card');
          expect(t.getRect(last).top, greaterThanOrEqualTo(0));
        }
      }
    });
  }
}
