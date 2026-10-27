import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/content/difficulty_content.dart';
import 'package:london_mystery/data/content/learning_check.dart';
import 'package:london_mystery/data/mock/season1/season1_clocks.dart';
import 'package:london_mystery/data/mock/season1/season1_difficulty.dart';
import 'package:london_mystery/data/mock/season1/season1_learning.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/clock_puzzle.dart';
import 'package:london_mystery/data/models/difficulty.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/game_master/dev_session.dart';
import 'package:london_mystery/features/result/detective_report.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'mission_play.dart' show prefsAt;

/// Difficulty PART 5: the words of the game at each level — one engine for
/// the cases' JSON (field by field) and the puzzles' own objects, read in
/// each session at its seasons' levels, with nothing falling back unseen
/// (see docs/DIFFICULTY_IMPLEMENTATION.md).

final base = MockEpisodeRepository.bundled();
Episode baseCase(String id) => base.firstWhere((e) => e.id == id);
Mission baseMission(String id) => base.expand((e) => e.allMissions).firstWhere((m) => m.id == id);
Mission at(String missionId, Difficulty level) {
  final e = base.firstWhere((e) => e.allMissions.any((m) => m.id == missionId));
  return DifficultyContent.episodeAt(e, level).missionById(missionId)!;
}

const id = 'abcdef0123456789abcdef0123456789';
String pk(String legacyKey) => AppConstants.profileKey(id, legacyKey);
String profile(Difficulty level) => jsonEncode({
      'schema': 1,
      'profile': {'id': id, 'origin': 'fresh', 'walletBackfill': 'never', 'detectiveName': 'KIM', 'avatar': 'girl', 'difficulty': level.storageId},
    });

Future<ProviderContainer> containerWith(Map<String, Object> prefs) async {
  final c = ProviderContainer(overrides: await testOverrides(prefs: prefs));
  addTearDown(c.dispose);
  return c;
}

Mission played(ProviderContainer c, String missionId) =>
    c.read(playedEpisodesProvider).expand((e) => e.allMissions).firstWhere((m) => m.id == missionId);

/// Synthetic levels over Case 02, for the rules themselves.
const synthetic = <Difficulty, Map<String, Map<String, Object?>>>{
  Difficulty.rookie: {
    'ep02': {
      'missions': {
        'ep02_m1': {'story': ['ROOKIE STORY']},
      },
    },
  },
  Difficulty.junior: {
    'ep02': {
      'missions': {
        'ep02_m1': {'story': ['JUNIOR STORY'], 'question': 'JUNIOR QUESTION'},
      },
    },
  },
  Difficulty.master: {
    'ep02': {
      'missions': {
        'ep02_m1': {'story': ['MASTER STORY']},
      },
    },
  },
};

void main() {
  group('A. choosing the words', () {
    Mission pick(Difficulty level, Map<Difficulty, Map<String, Map<String, Object?>>> patches) =>
        DifficultyContent.episodeAt(baseCase('ep02'), level, patches: patches).missionById('ep02_m1')!;

    test('1. Rookie with no words of its own: the base', () {
      final m = pick(Difficulty.rookie, const {});
      expect(m.story, baseMission('ep02_m1').story);
      expect(m.difficulty, Difficulty.rookie);
    });
    test('2–4. Each level its own words', () {
      expect(pick(Difficulty.rookie, synthetic).story, ['ROOKIE STORY']);
      expect(pick(Difficulty.junior, synthetic).story, ['JUNIOR STORY']);
      expect(pick(Difficulty.master, synthetic).story, ['MASTER STORY']);
    });
    test('5. Junior without its own words for a field: the base', () {
      expect(pick(Difficulty.junior, synthetic).letter, baseMission('ep02_m1').letter);
    });
    test('6. Master without its own: Junior\'s', () {
      expect(pick(Difficulty.master, synthetic).question, 'JUNIOR QUESTION');
      // And in the game's real words (PART 6A: Case 01's words are all
      // written, so the chain shows in its glossary): a word only Junior
      // adds is Master's too.
      final words = {for (final l in Difficulty.values) l: DifficultyContent.episodeAt(baseCase('ep01'), l).glossary};
      expect(baseCase('ep01').glossary.containsKey('alone'), isFalse);
      expect(season1CasePatches[Difficulty.master]!['ep01']!['glossary'] as Map, isNot(contains('alone')));
      expect(words[Difficulty.junior]!['alone'], '혼자, 홀로');
      expect(words[Difficulty.master]!['alone'], '혼자, 홀로', reason: "Master falls back on Junior's");
      expect(words[Difficulty.rookie]!.containsKey('alone'), isFalse, reason: "Rookie never takes Junior's");
    });
    test('7. Master with neither: the base', () {
      expect(pick(Difficulty.master, synthetic).letterIntro, baseMission('ep02_m1').letterIntro);
      expect(pick(Difficulty.rookie, synthetic).question, baseMission('ep02_m1').question, reason: 'Rookie never takes Junior\'s');
    });
    test('8. A save from before levels plays the base (Rookie)', () async {
      final c = await containerWith(prefsAt(base, 'ep02_m1'));
      expect(c.read(currentDifficultyProvider), Difficulty.rookie);
      final m = played(c, 'ep02_m1');
      expect(m.story, baseMission('ep02_m1').story);
      expect(m.toJson(), baseMission('ep02_m1').toJson(), reason: 'the very same words');
    });
  });

  group('B. the cases\' JSON', () {
    test('9–10. One field changed, the rest kept', () {
      final m = DifficultyContent.episodeAt(baseCase('ep02'), Difficulty.rookie, patches: synthetic).missionById('ep02_m1')!;
      final b = baseMission('ep02_m1');
      expect(m.story, ['ROOKIE STORY']);
      expect(m.toJson()..remove('story'), b.toJson()..remove('story'));
    });
    test('11. The base is never changed', () {
      final json = baseCase('ep02').toJson();
      final before = jsonEncode(json);
      for (final level in Difficulty.values) {
        DifficultyContent.apply(json, level, synthetic);
        DifficultyContent.apply(json, level, season1CasePatches);
      }
      expect(jsonEncode(json), before);
      expect(jsonEncode(MockEpisodeRepository.bundled().firstWhere((e) => e.id == 'ep02').toJson()), before);
    });
    test('12–13. Ids, answers, order, hints, rewards and XP the same at every level; the game\'s words pass every check', () {
      expect(DifficultyContent.problems(), isEmpty);
      for (final e in base) {
        for (final level in Difficulty.values) {
          final p = DifficultyContent.episodeAt(e, level);
          expect(DifficultyContent.structureOfEpisode(p), DifficultyContent.structureOfEpisode(e), reason: '${e.id} ${level.name}');
          expect(p.allMissions.length, e.allMissions.length);
          for (final (i, m) in p.allMissions.indexed) {
            final b = e.allMissions[i];
            expect((m.id, m.answer, m.hints.length), (b.id, b.answer, b.hints.length));
            expect(m.options.map((o) => o.id).toList(), b.options.map((o) => o.id).toList(), reason: '${m.id}: options in order');
            expect(m.acceptedAnswers, b.acceptedAnswers);
            expect(WalletController.coinsFor(m), WalletController.coinsFor(b));
            expect(m.isFinal, b.isFinal);
          }
        }
      }
    });
    test('13. What may not change is caught, never laid on', () {
      final bad = SeasonContent(
        info: season1Content.info,
        episodes: season1Content.episodes,
        clocks: season1Content.clocks,
        casePatches: const {
          Difficulty.master: {
            'ep02': {
              'id': 'ep99',
              'missions': {
                'ep02_m1': {
                  'answer': '999',
                  'hints': ['only one'],
                  'feedback': {'123': 'a line for an answer the base has none for'},
                  'evidence': {'inscription': 'STOPPED AT 9:17'},
                  'options': {'zz': {'label': 'x'}},
                },
                'ep02_m9': {'story': ['x']},
              },
            },
            'ep77': {'title': 'x'},
          },
        },
        variants: const {
          Difficulty.junior: SeasonContent(info: {}, episodes: {}, clocks: {'ep02_m2': _clock}, dialogues: {}),
        },
      );
      final found = DifficultyContent.problemsOf(bad).join('\n');
      for (final want in [
        'ep02.id: may not change',
        'ep02_m1.answer: may not change',
        'ep02_m1.hints: 1 hints',
        'feedback: "123"',
        'ep02_m1.evidence.inscription: may not change',
        'options.zz: no such option',
        'ep02_m9: no such mission',
        'ep77: no such case',
        'clocks/ep02_m2: the base has no such entry',
      ]) {
        expect(found, contains(want));
      }
      // Laid on anyway, none of it takes.
      final m = DifficultyContent.episodeAt(baseCase('ep02'), Difficulty.master, patches: bad.casePatches).missionById('ep02_m1')!;
      final b = baseMission('ep02_m1');
      expect((m.answer, m.evidence!.inscription), (b.answer, b.evidence!.inscription));
      expect(m.hints, b.hints, reason: 'one hint for two: not taken');
      expect(m.feedback, b.feedback);
    });
  });

  group('C. the puzzles\' own objects', () {
    test('14. Each level its own clock puzzle, read through the same lookup', () {
      final leads = {for (final level in Difficulty.values) level: SeasonCatalog.clock(at('ep02_m1', level))!.lead};
      expect(leads[Difficulty.rookie], season1Clocks['ep02_m1']!.lead);
      expect(leads.values.toSet(), hasLength(3));
      // Master never borrows a field: its own object, whole.
      expect(SeasonCatalog.clock(at('ep02_m1', Difficulty.master)), same(season1Variants[Difficulty.master]!.clocks['ep02_m1']));
    });
    test('15–17. The answer judged the same; options as many, in the same order', () {
      for (final level in Difficulty.values) {
        final m = at('ep02_m1', level);
        expect(AnswerChecker.isCorrect(m, '817'), isTrue, reason: level.name);
        expect(AnswerChecker.isCorrect(m, '917'), isFalse);
        expect(AnswerChecker.feedbackFor(m, '917'), isNotNull, reason: 'its line for a known wrong answer');
        final c = SeasonCatalog.clock(m)!;
        final b = season1Clocks['ep02_m1']!;
        expect((c.face, c.start), (b.face, b.start));
        final p = at('s2_ep01_m1', level);
        expect(p.options.map((o) => o.id), ['a', 'b', 'c']);
        expect(p.answer, 'c');
        expect(AnswerChecker.isCorrect(p, 'c'), isTrue);
      }
    });
    test('18. Every lookup still answers a mission with no level (as all callers had it)', () {
      final m = baseMission('ep02_m1');
      expect(SeasonCatalog.clock(m), same(clockPuzzleOf(m)));
      expect(SeasonCatalog.learning(m), same(learningOf(m)));
      expect(SeasonCatalog.clock(baseMission('ep02_m2')), isNull);
    });
    test('A puzzle object of another kind, or of a kind with no structure check, is caught', () {
      final bad = SeasonContent(
        info: season1Content.info,
        episodes: season1Content.episodes,
        clocks: season1Content.clocks,
        dialogues: season1Content.dialogues,
        variants: {
          Difficulty.master: SeasonContent(info: const {}, episodes: const {}, dialogues: {'ep06_m1': season1Content.dialogues['ep06_m1']!}),
        },
      );
      expect(DifficultyContent.problemsOf(bad).join('\n'), contains('no structure check for DialogueScene'));
    });
  });

  group('D. each session its own words', () {
    ProviderContainer session(WidgetTester t) => ProviderScope.containerOf(t.element(find.byType(LondonMysteryApp)));

    testWidgets('19–24. The player at Junior, TESTER at Master: never mixed; a new test session starts at Rookie', (t) async {
      t.view.physicalSize = const Size(390, 844) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({AppConstants.detectiveStorageKey: profile(Difficulty.junior)});
      final prefs = await SharedPreferences.getInstance();
      await t.pumpWidget(DevSessionHost(overrides: await testOverridesFor(prefs), child: const LondonMysteryApp()));
      await wait(t, const Duration(milliseconds: 300));
      final own = session(t);
      expect(played(own, 'ep02_m1').story, at('ep02_m1', Difficulty.junior).story);
      final ownWords = jsonEncode([for (final e in own.read(playedEpisodesProvider)) e.toJson()]);

      own.read(gameMasterAccessProvider.notifier).grant();
      own.read(routerProvider).go(Routes.gameMaster);
      await wait(t, const Duration(milliseconds: 600));
      await tapText(t, 'START DEVELOPER MODE', after: const Duration(milliseconds: 900));
      final test1 = session(t);
      expect(played(test1, 'ep02_m1').story, baseMission('ep02_m1').story, reason: 'TESTER starts at Rookie');
      await reveal(t, find.byKey(const ValueKey('difficulty-master')));
      await t.tap(find.byKey(const ValueKey('difficulty-master')));
      await wait(t, const Duration(milliseconds: 600));
      expect(played(test1, 'ep02_m1').story, at('ep02_m1', Difficulty.master).story, reason: 'recomputed in the test session');
      expect(played(test1, 's2_ep01_m1').question, at('s2_ep01_m1', Difficulty.master).question);
      expect(played(own, 'ep02_m1').story, at('ep02_m1', Difficulty.junior).story, reason: 'the player\'s words untouched');
      expect(jsonEncode([for (final e in own.read(playedEpisodesProvider)) e.toJson()]), ownWords);

      await tapText(t, 'EXIT DEVELOPER MODE', after: const Duration(milliseconds: 900));
      expect(identical(session(t), own), isTrue);
      expect(played(own, 'ep02_m1').story, at('ep02_m1', Difficulty.junior).story);
      own.read(routerProvider).go(Routes.gameMaster);
      await wait(t, const Duration(milliseconds: 600));
      await tapText(t, 'START DEVELOPER MODE', after: const Duration(milliseconds: 900));
      expect(played(session(t), 'ep02_m1').story, baseMission('ep02_m1').story, reason: 'a new session: Rookie again');
      await wait(t, const Duration(seconds: 2));
    });
  });

  group('E. hints', () {
    test('25–27. Each level its own hints: Rookie direct, Junior in steps, Master indirect; none tells the answer', () {
      final hints = {for (final level in Difficulty.values) level: at('ep02_m1', level).hints};
      expect(hints.values.map((h) => h.join()).toSet(), hasLength(3));
      for (final h in hints.values) {
        for (final line in h) {
          expect(line, isNot(contains('817')));
          expect(line, isNot(contains('8:17')));
          expect(line, isNot(contains('9:17')), reason: 'Case 02: 9:17 is nowhere before its final');
          expect(line, isNot(contains('{detectiveName}')));
        }
      }
      expect({for (final level in Difficulty.values) at('s2_ep01_m1', level).hints.join()}, hasLength(3));
    });
    test('28–30. Hints as many and at the same price at every level; one bought is the detective\'s at every level', () async {
      final c = await containerWith({AppConstants.detectiveStorageKey: profile(Difficulty.junior), ...prefsAt(base, 'ep02_m1')});
      final wallet = c.read(walletProvider.notifier);
      for (final level in Difficulty.values) {
        expect(at('ep02_m1', level).hints, hasLength(baseMission('ep02_m1').hints.length));
      }
      expect([WalletController.priceOf(1), WalletController.priceOf(2)], AppConstants.tipPrices);
      expect(wallet.unlockTip(at('ep02_m1', Difficulty.junior), 1), TipUnlock.free);
      for (final level in Difficulty.values) {
        expect(c.read(walletProvider).ownsTip(at('ep02_m1', level).id, 1), isTrue, reason: 'kept by mission id, whatever the level');
        expect(wallet.unlockTip(at('ep02_m1', level), 1), TipUnlock.alreadyYours);
      }
    });
  });

  group('F. the parent report\'s English', () {
    Map<String, Object> seasonAt({Difficulty? london, Difficulty? paris, String selected = SeasonIds.london, Difficulty profileLevel = Difficulty.rookie}) => {
          AppConstants.detectiveStorageKey: profile(profileLevel),
          pk(AppConstants.progressKeyFor('ep01')): jsonEncode(GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: [for (final m in baseCase('ep01').allMissions) m.id]).toJson()),
          pk(AppConstants.progressKeyFor('ep02')):
              jsonEncode(const GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: ['ep02_m1']).toJson()),
          pk(AppConstants.seasonKeyFor(SeasonIds.london)): jsonEncode(SeasonProgress(
            activeEpisodeId: 'ep02',
            solvedEpisodeIds: selected == SeasonIds.paris ? [for (final e in base) if (e.seasonId == SeasonIds.london) e.id] : const ['ep01'],
            difficulty: london,
          ).toJson()),
          if (paris != null)
            pk(AppConstants.seasonKeyFor(SeasonIds.paris)):
                jsonEncode(SeasonProgress(activeEpisodeId: 's2_ep01', prologueSeen: true, difficulty: paris).toJson()),
          if (paris != null)
            pk(AppConstants.progressKeyFor('s2_ep01')):
                jsonEncode(const GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: ['s2_ep01_m1']).toJson()),
          pk(AppConstants.selectedSeasonKey): jsonEncode({'seasonId': selected}),
        };

    List<String> reportExpressions(ProviderContainer c, String missionId) => DetectiveReport.from(
          c.read(currentEpisodeProvider),
          c.read(gameControllerProvider),
        ).performances.firstWhere((p) => p.mission.id == missionId).learning!.expressions;

    for (final level in Difficulty.values) {
      test('31–33. London played at ${level.label}: its report names ${level.label}\'s English', () async {
        final c = await containerWith(seasonAt(london: level));
        expect(c.read(currentEpisodeProvider).id, 'ep02');
        expect(reportExpressions(c, 'ep02_m1'), SeasonCatalog.learning(at('ep02_m1', level))!.expressions);
      });
    }
    test('31–33. The three levels name different English', () {
      expect({for (final level in Difficulty.values) SeasonCatalog.learning(at('ep02_m1', level))!.expressions.join()}, hasLength(3));
    });

    test('34–35. Paris at Master while London was Rookie; the detective now Master: each season its own', () async {
      final c = await containerWith(seasonAt(london: Difficulty.rookie, paris: Difficulty.master, selected: SeasonIds.paris, profileLevel: Difficulty.master));
      expect(c.read(selectedSeasonIdProvider), SeasonIds.paris);
      expect(reportExpressions(c, 's2_ep01_m1'), SeasonCatalog.learning(at('s2_ep01_m1', Difficulty.master))!.expressions);
      final london = played(c, 'ep02_m1');
      expect(london.difficulty, Difficulty.rookie, reason: 'London kept its level');
      expect(SeasonCatalog.learning(london)!.expressions, learningOf(baseMission('ep02_m1'))!.expressions);
      await c.read(detectiveProfileProvider.notifier).setDifficulty(Difficulty.junior);
      expect(SeasonCatalog.learning(played(c, 'ep02_m1'))!.expressions, learningOf(baseMission('ep02_m1'))!.expressions,
          reason: 'a fixed season\'s report never follows the profile');
      expect(reportExpressions(c, 's2_ep01_m1'), SeasonCatalog.learning(at('s2_ep01_m1', Difficulty.master))!.expressions);
    });

    test('36. Every learning design, at every level, names English really on its pages (both seasons)', () {
      for (final level in Difficulty.values) {
        final missions = {
          for (final e in base)
            for (final m in DifficultyContent.episodeAt(e, level).allMissions) m.id: m,
        };
        for (final m in missions.values) {
          final l = SeasonCatalog.learning(m);
          if (l == null) continue;
          final recalled = l.recallFrom == null ? null : missions[l.recallFrom];
          expect(LearningCheck.unmatched(l, m, recalled: recalled), isEmpty, reason: '${m.id} at ${level.name}');
        }
      }
    });

    test('37. English named at a level that only another level\'s words have is caught', () {
      const rookieOnly = LearningObjective(
        dependency: LanguageDependency.essential,
        level: LearningLevel.comprehension,
        objective: 'x',
        expressions: ['The hour hand was between eight and nine'],
      );
      expect(LearningCheck.unmatched(rookieOnly, at('ep02_m1', Difficulty.rookie)), isEmpty);
      expect(LearningCheck.unmatched(rookieOnly, at('ep02_m1', Difficulty.master)), ['The hour hand was between eight and nine']);
      expect(LearningCheck.unmatched(rookieOnly.copyWithExpressions(['hour hand wa']), at('ep02_m1', Difficulty.rookie)), isNotEmpty,
          reason: 'whole words only');
    });
  });

  group('G. Paris Discovery Moments', () {
    test('38–39. The title is the line of the level played — never the base\'s left behind', () {
      final titles = {for (final level in Difficulty.values) level: SeasonCatalog.discovery(at('s2_ep01_m1', level)).title};
      expect(titles[Difficulty.rookie], baseMission('s2_ep01_m1').successMessage);
      expect(titles[Difficulty.junior], 'The old clock is running one hour behind!');
      expect(titles[Difficulty.master], 'The old clock has fallen one hour behind!');
      for (final level in Difficulty.values) {
        for (final e in base.where((e) => e.seasonId == SeasonIds.paris)) {
          for (final m in DifficultyContent.episodeAt(e, level).missions) {
            expect(SeasonCatalog.discovery(m).title, m.successMessage, reason: '${m.id} at ${level.name}');
          }
        }
      }
    });
  });

  group('Coverage: nothing falls back unseen', () {
    test('A case marked written has every word of its level; the sample (not marked) shows what it lacks', () {
      for (final s in SeasonCatalog.all) {
        s.writtenLevels.forEach((caseId, levels) {
          for (final level in levels) {
            expect(DifficultyContent.missingAt(caseId, level), isEmpty, reason: '$caseId at ${level.name}');
          }
        });
      }
      // PART 6A wrote Cases 01–03 whole (the PART 5 sample of Case 02 is
      // finished); a case not written yet still shows what it lacks — Case
      // 06 since PART 6B: all but M1's witness talk, which has no level
      // structure check.
      for (final caseId in ['ep01', 'ep02', 'ep03']) {
        expect(season1Content.writtenLevels[caseId], Difficulty.values.toSet(), reason: caseId);
      }
      final junior = DifficultyContent.missingAt('ep06', Difficulty.junior);
      expect(junior, ['dialogues/ep06_m1']);
      expect(DifficultyContent.missingAt('ep06', Difficulty.master), containsAll(junior));
      expect(DifficultyContent.missingAt('ep06', Difficulty.rookie), isEmpty);
      expect(season1Content.writtenLevels['ep06'], isNot(contains(Difficulty.junior)));
    });
  });

  group('On screen', () {
    for (final level in Difficulty.values) {
      testWidgets('Case 02 M1 at ${level.label}: its clock puzzle in ${level.label}\'s words', (t) async {
        t.view.physicalSize = const Size(390, 844) * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        final prefs = {
          ...prefsAt(base, 'ep02_m1'),
          AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep02', solvedEpisodeIds: const ['ep01'], difficulty: level).toJson()),
        };
        late WidgetRef ref;
        await t.pumpWidget(ProviderScope(
          overrides: await testOverrides(prefs: prefs),
          child: Consumer(builder: (context, r, _) {
            ref = r;
            return const LondonMysteryApp();
          }),
        ));
        await wait(t, const Duration(milliseconds: 300));
        ref.read(routerProvider).go(Routes.mission('ep02_m1'));
        await wait(t, const Duration(milliseconds: 1200));
        expect(find.byKey(const ValueKey('clock-dial')), findsOneWidget);
        final clock = SeasonCatalog.clock(at('ep02_m1', level))!;
        expect(findReadable(clock.question), findsOneWidget, reason: level.name);
        expect(findReadable(clock.lead), findsOneWidget);
        for (final other in Difficulty.values.where((l) => l != level)) {
          final q = SeasonCatalog.clock(at('ep02_m1', other))!.question;
          if (q != clock.question) expect(findReadable(q), findsNothing);
        }
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 2));
      });
    }
  });
}

const _clock = ClockPuzzle(
  face: Artwork.clockFace,
  question: 'x',
  lead: 'x',
  guide: 'x',
  dialLabel: 'x',
);

extension on LearningObjective {
  LearningObjective copyWithExpressions(List<String> expressions) => LearningObjective(
        dependency: dependency,
        level: level,
        objective: objective,
        skill: skill,
        expressions: expressions,
        recallFrom: recallFrom,
      );
}
