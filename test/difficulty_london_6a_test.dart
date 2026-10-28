import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/content/learning_check.dart';
import 'package:world_mystery/data/mock/season1/season1_difficulty.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/features/game_master/dev_session.dart';
import 'package:world_mystery/features/mission/widgets/lens_inspect.dart' show noteLines;
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'mission_play.dart' show prefsAt;

/// Difficulty PART 6A: London Cases 01–03 written at Rookie, Junior and
/// Master — the same case at every level (answers, order, hints, rewards),
/// every reasoning guard of the base kept at each level, the parent
/// report's English on each level's pages, and nothing left to fall back.

final base = MockEpisodeRepository.bundled();
const cases = ['ep01', 'ep02', 'ep03'];
Episode baseCase(String id) => base.firstWhere((e) => e.id == id);
Episode caseAt(String id, Difficulty level) => DifficultyContent.episodeAt(baseCase(id), level);
Mission at(String missionId, Difficulty level) =>
    caseAt(base.firstWhere((e) => e.allMissions.any((m) => m.id == missionId)).id, level).missionById(missionId)!;

/// What the player reads of [m] before answering it (its puzzle page and
/// tips; option names only where they show).
List<String> pageOf(Mission m) => [
      m.title,
      m.location,
      ...m.story,
      m.letterIntro,
      m.letter,
      m.question,
      ?m.prompt,
      for (final o in m.options)
        if (!m.hideOptionNames) o.label,
      ...m.hints,
    ];

/// What solving [m] shows and keeps.
List<String> keptOf(Mission m) => [
      m.successMessage,
      if (m.clue case final c?) ...[c.title, c.value, c.note],
      if (m.evidence case final e?) ...[e.name, e.description, ?e.inscription],
      ...m.transition,
    ];

bool hasWord(String text, String w) => RegExp('\\b$w\\b', caseSensitive: false).hasMatch(text);

void main() {
  group('the same case at every level', () {
    for (final id in cases) {
      test('$id: structure, answers, options, hints and rewards as the base', () {
        final b = baseCase(id);
        for (final level in Difficulty.values) {
          final e = caseAt(id, level);
          expect(DifficultyContent.structureOfEpisode(e), DifficultyContent.structureOfEpisode(b), reason: level.name);
          for (final m in e.allMissions) {
            final bm = b.missionById(m.id)!;
            expect(m.answer, bm.answer);
            expect(m.acceptedAnswers, bm.acceptedAnswers);
            expect([for (final o in m.options) o.id], [for (final o in bm.options) o.id], reason: '${m.id} options in order');
            expect([for (final o in m.options) o.label], [for (final o in bm.options) o.label],
                reason: '${m.id}: the choices are named as before');
            expect(m.hints, hasLength(bm.hints.length), reason: m.id);
            expect(m.feedback.keys, bm.feedback.keys, reason: m.id);
            expect(m.clue?.value, bm.clue?.value);
            expect(m.evidence?.id, bm.evidence?.id);
            expect(m.evidence?.inscription, bm.evidence?.inscription, reason: '${m.id}: evidence words are puzzle data');
            expect(WalletController.coinsFor(m), WalletController.coinsFor(bm));
            // The answer is judged the same; each wrong answer gets this
            // level's own line.
            expect(AnswerChecker.isCorrect(m, bm.answer), isTrue, reason: '${m.id} at ${level.name}');
            for (final wrong in bm.feedback.keys) {
              expect(AnswerChecker.isCorrect(m, wrong), isFalse);
              expect(AnswerChecker.feedbackFor(m, wrong), m.feedback[wrong]);
            }
          }
        }
        expect(DifficultyContent.problemsOf(season1Content), isEmpty);
      });
    }

    test('tips: as many, at the same price, kept by mission id at every level', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: prefsAt(base, 'ep03_m2')));
      addTearDown(c.dispose);
      final wallet = c.read(walletProvider.notifier);
      expect([WalletController.priceOf(1), WalletController.priceOf(2)], AppConstants.tipPrices);
      expect(wallet.unlockTip(at('ep03_m2', Difficulty.master), 1), TipUnlock.free);
      for (final level in Difficulty.values) {
        expect(wallet.unlockTip(at('ep03_m2', level), 1), TipUnlock.alreadyYours, reason: level.name);
      }
    });

    test('no tip, at any level, gives its answer', () {
      for (final id in cases) {
        for (final level in Difficulty.values) {
          for (final m in caseAt(id, level).allMissions) {
            final answer = switch (m.type) {
              MissionType.multipleChoice || MissionType.imageChoice => m.answerLabel,
              MissionType.sequence || MissionType.examine => null,
              _ => m.answer,
            };
            if (answer == null) continue;
            for (final h in m.hints) {
              expect(AnswerChecker.normalize(h).contains(AnswerChecker.normalize(answer)), isFalse,
                  reason: '${m.id} at ${level.name}: "$h"');
              expect(h, isNot(contains('{detectiveName}')));
            }
          }
        }
      }
    });
  });

  group('each level its own words', () {
    test('Junior and Master write every page; neither is the base nor the other', () {
      // Kept the same on purpose: how a puzzle is played, and what is drawn
      // on a picture (the crown card's message).
      const same = {'m02.prompt', 'm05.letter', 'm05.question', 'final.question', 'ep02_final.question'};
      for (final id in cases) {
        final b = baseCase(id);
        final j = caseAt(id, Difficulty.junior), m = caseAt(id, Difficulty.master);
        expect(j.intro, isNot(b.intro));
        expect(m.intro, isNot(j.intro));
        expect(m.synopsis, isNot(j.synopsis));
        for (final bm in b.allMissions) {
          final (jm, mm) = (j.missionById(bm.id)!, m.missionById(bm.id)!);
          final fields = <String, List<Object?>>{
            'story': [bm.story, jm.story, mm.story],
            'letterIntro': [bm.letterIntro, jm.letterIntro, mm.letterIntro],
            'letter': [bm.letter, jm.letter, mm.letter],
            'question': [bm.question, jm.question, mm.question],
            'hints': [bm.hints, jm.hints, mm.hints],
            'successMessage': [bm.successMessage, jm.successMessage, mm.successMessage],
            'transition': [bm.transition, jm.transition, mm.transition],
          };
          fields.forEach((field, v) {
            final key = '${bm.id}.$field';
            if (same.contains(key)) {
              expect(v.toSet(), hasLength(1), reason: '$key is the same at every level, on purpose');
            } else {
              expect(v.map(jsonEncode).toSet(), hasLength(3), reason: '$key: base, Junior and Master all differ');
            }
          });
          // The story keeps its steps: as many lines at every level.
          expect(jm.story, hasLength(bm.story.length));
          expect(mm.story, hasLength(bm.story.length));
          expect(jm.transition, hasLength(bm.transition.length));
          expect(mm.transition, hasLength(bm.transition.length));
        }
        expect(j.intro, hasLength(b.intro.length));
        expect(m.intro, hasLength(b.intro.length));
      }
    });

    test('Rookie: the base, but for the lines made shorter', () {
      Map<String, dynamic> withoutRookie(String id) => baseCase(id).toJson();
      for (final id in cases) {
        final r = caseAt(id, Difficulty.rookie).toJson();
        final b = withoutRookie(id);
        final patch = season1CasePatches[Difficulty.rookie]![id]!;
        // Every field Rookie does not write is the base's, word for word.
        for (final key in b.keys) {
          if (key == 'missions' || key == 'finalMission' || patch.containsKey(key)) continue;
          expect(r[key], b[key], reason: '$id.$key');
        }
        final missions = patch['missions'] as Map? ?? const {};
        for (final bm in baseCase(id).allMissions) {
          final rm = caseAt(id, Difficulty.rookie).missionById(bm.id)!.toJson();
          final own = missions[bm.id] as Map? ?? const {};
          for (final key in bm.toJson().keys) {
            if (own.containsKey(key)) {
              expect(rm[key], isNot(bm.toJson()[key]), reason: '${bm.id}.$key: Rookie\'s own');
            } else {
              expect(rm[key], bm.toJson()[key], reason: '${bm.id}.$key: the base');
            }
          }
        }
      }
      // The lines Rookie writes are short: one idea each.
      expect(caseAt('ep01', Difficulty.rookie).finalMission.story.first, 'Behind the secret door, you find a heavy golden box.');
      for (final h in at('ep03_m3', Difficulty.rookie).hints.last.split('. ')) {
        expect(h.split(' ').length, lessThanOrEqualTo(9), reason: h);
      }
    });

    test('nothing at Junior or Master falls back on another level\'s words; all three levels marked written', () {
      for (final id in cases) {
        expect(season1Content.writtenLevels[id], Difficulty.values.toSet());
        for (final level in [Difficulty.junior, Difficulty.master]) {
          expect(DifficultyContent.missingAt(id, level), isEmpty, reason: '$id at ${level.name}');
        }
      }
    });

    test('a scene at Junior and Master: its own words, the base\'s picture, places and answer', () {
      for (final level in [Difficulty.junior, Difficulty.master]) {
        final variant = season1Content.variants[level]!;
        for (final MapEntry(key: table, value: entries) in variant.missionTables.entries) {
          for (final MapEntry(key: id, value: entry) in entries.entries) {
            final b = season1Content.missionTables[table]![id];
            expect(entry.runtimeType, b.runtimeType);
            expect(DifficultyContent.structureOf(entry), isNotNull, reason: '$table/$id');
            expect(DifficultyContent.structureOf(entry), DifficultyContent.structureOf(b), reason: '$table/$id at ${level.name}');
          }
        }
        final m01 = at('m01', level);
        expect(SeasonCatalog.explore(m01)!.task, isNot(SeasonCatalog.explore(baseCase('ep01').missionById('m01')!)!.task));
        expect(SeasonCatalog.investigation(at('ep03_m1', level))!.arrival,
            isNot(SeasonCatalog.investigation(baseCase('ep03').missionById('ep03_m1')!)!.arrival));
      }
    });
  });

  group('Case 01 guards, at every level', () {
    for (final level in Difficulty.values) {
      test('${level.label}: the letter\'s two things, the word never written, the stone never named', () {
        final m01 = at('m01', level), m02 = at('m02', level), m03 = at('m03', level), m05 = at('m05', level);
        final fin = caseAt('ep01', level).finalMission;
        // M1: the museum is read from the letter; no choice repeats it.
        expect(m01.letter, contains('a famous stone'), reason: "M2's tip reads it again");
        expect(m01.letter, contains('Egypt'));
        expect(m01.letter, contains('{detectiveName}'));
        for (final o in m01.options) {
          for (final w in ['mummies', 'egypt', 'stone']) {
            expect(o.label.toLowerCase(), isNot(contains(w)));
          }
        }
        final explore = SeasonCatalog.explore(m01)!;
        expect(explore.spot('platform').line, m01.clue!.note, reason: "the sign's card is the clue's note");
        // M2: STONE is never written before it is answered.
        final inspect = SeasonCatalog.inspection(m02)!;
        final said = [
          ...m02.story, m02.letterIntro, m02.letter, m02.question, m02.prompt!, ...m02.hints,
          inspect.task, inspect.nextTask, inspect.missLine, inspect.labelWorn,
          for (final s in inspect.spots) ...[s.line, s.lockedLine],
        ];
        for (final line in said) {
          expect(line.toLowerCase(), isNot(contains('stone')), reason: line);
        }
        expect(noteLines(m02), hasLength(4), reason: 'the note: four lines, the last the one to answer');
        expect(noteLines(m02)[inspect.taskLine], contains('a hard piece of rock'));
        expect(inspect.spot('plinth').line, contains("'My next stop is where London's biggest bell rings.'"));
        // M3: the notes are the letter; nothing says where the box is.
        final deduction = SeasonCatalog.deduction(m03)!;
        expect(deduction.clues.map((c) => c.line).toList(), m03.letter.split('\n'));
        for (final line in [
          ...m03.story, m03.question, m03.letterIntro, m03.letter, ...m03.hints,
          deduction.task, deduction.chooseTask, deduction.missLine, deduction.notPlaceLine,
          for (final c in deduction.clues) ...[c.label, c.line],
          for (final o in deduction.others) ...[o.label, o.line],
        ]) {
          expect(line.toLowerCase(), isNot(contains('behind')), reason: line);
          expect(line.toLowerCase(), isNot(contains(m03.answerLabel.toLowerCase())), reason: line);
        }
        // M5: the card's message is drawn on it — the same words.
        expect(m05.letter, baseCase('ep01').missionById('m05')!.letter);
        // The final: four locks, read from the notebook; Case 11's line kept.
        expect(fin.answer, '7924');
        expect(fin.letter, contains('Notebook'));
        expect(fin.transition, contains('"P.S. I love trains!"'));
        expect(m01.evidence!.inscription, 'Signed: The Shadow\nP.S. I love trains!');
      });
    }
  });

  group('Case 02 guards, at every level', () {
    final finalTime = RegExp(r'9\s*[:.·]\s*17|\b917\b|nine\s+seventeen', caseSensitive: false);
    for (final level in Difficulty.values) {
      test('${level.label}: 8:17 read from the note, the plan\'s rule word for word, 9:17 nowhere before the lock', () {
        final e = caseAt('ep02', level);
        final m1 = e.missionById('ep02_m1')!, m2 = e.missionById('ep02_m2')!, m3 = e.missionById('ep02_m3')!;
        final fin = e.finalMission;
        // Before the lock: the case's pages, every mission's pages and what
        // they keep, their clock puzzle and Discovery Moments, the final's
        // page and tips.
        final before = [
          ...e.synopsis, ...e.intro, ...e.objectives,
          for (final m in e.missions) ...[...pageOf(m), ...keptOf(m), ...m.feedback.values,
            for (final o in m.options) ?o.feedback,
            SeasonCatalog.discovery(m).title, SeasonCatalog.discovery(m).detail],
          if (SeasonCatalog.clock(m1) case final c?) ...[c.question, c.lead, c.guide],
          ...fin.story, fin.letterIntro, fin.letter, fin.question, ...fin.hints, ...fin.feedback.values,
        ];
        for (final line in before) {
          expect(finalTime.hasMatch(line), isFalse, reason: '${level.name}: "$line"');
        }
        // M1: the stopped time is worked out, not written.
        for (final line in [...m1.story, m1.letterIntro, m1.letter, m1.question, ...m1.hints]) {
          expect(line, isNot(contains('8:17')));
          expect(line, isNot(contains('817')));
        }
        expect(m1.answer, '817');
        expect(m1.feedback.keys, ['815', '832', '917']);
        // M2: the note's "not" and "opposite"; the answer's word never on it.
        expect(m2.letter.toLowerCase(), contains('not'));
        expect(m2.letter, contains('opposite'));
        expect(m2.letter.toLowerCase(), isNot(contains('smallest')));
        // M3: the rule, and the plan's "after" (Case 12 reads it again).
        expect(m3.letter, contains('stopped clock'));
        expect(m3.letter, contains('The hour is the gallery. The minutes are the picture.'));
        expect(m3.letter, contains('One hour after the clock stops'));
        for (final n in ['Gallery 8', 'Picture 17']) {
          expect([...m3.story, m3.letter, m3.question, ...m3.hints].join(' '), isNot(contains(n)));
          expect(m3.transition.join(' '), isNot(contains(n)), reason: 'the scene never works it out for the player');
        }
        expect(m3.evidence!.inscription, 'GALLERY 8 · PICTURE 17\nOne hour after the clock stops.');
        // The final points to the notebook and the plan.
        expect(fin.letter.toLowerCase(), contains('notebook'));
        expect(fin.letter, contains('Time Card'));
        expect(fin.answer, '917');
        expect(fin.hints.first, isNot(contains('8:17')), reason: 'tip 1 gives a direction only');
      });
    }
  });

  group('Case 03 guards, at every level', () {
    for (final level in Difficulty.values) {
      test('${level.label}: the report\'s places, the two colours, the order, and only the boot says where', () {
        final e = caseAt('ep03', level);
        final m1 = e.missionById('ep03_m1')!, m2 = e.missionById('ep03_m2')!, m3 = e.missionById('ep03_m3')!;
        final fin = e.finalMission;
        final boot = m3.evidence!;
        expect(e.intro.join(' '), allOf(contains('9:18'), contains('Gallery 8'), contains('one minute too late')));
        // M1: each thing where its report line says, word for word.
        final search = SeasonCatalog.investigation(m1)!;
        for (final f in search.finds) {
          expect(m1.letter, contains(f.reportLine), reason: f.id);
        }
        final line = {for (final f in search.finds) f.id: f.reportLine};
        expect(line['button'], allOf(contains('red'), contains('under the bench')));
        expect(line['cloth'], allOf(contains('blue'), contains('on the frame')));
        expect(line['footprint'], allOf(contains('wet'), contains('next to the door')));
        expect(search.arrival, hasLength(2));
        expect(search.arrival.last, contains('report'));
        expect(search.arrival.join(' '), isNot(contains('empty golden frame')));
        expect(m1.evidence!.name, 'Red Button', reason: 'Case 08');
        expect(m1.evidence!.description, contains('coat'));
        // M2: the colours come from M1; the letter never repeats them.
        expect(m2.letter, allOf(contains('red coat and a blue scarf'), contains('black coat and a red scarf')));
        expect(m2.letter, isNot(contains('button')));
        expect(m2.story.join(' '), contains('blue cloth'));
        expect(AnswerChecker.feedbackFor(m2, 'c'), contains('scarf'));
        // M3: how wet each one was.
        expect(m3.letter, allOf(contains('café'), contains('shop'), contains('north door'), contains('stairs')));
        expect(m3.letter, allOf(contains('very wet'), contains('a little wet'), contains('almost dry')));
        expect(m3.letter.toLowerCase(), contains('wet shoes get drier with every step'));
        expect(m3.answer, 'shop,stairs,cafe,door');
        // Nothing before the final names where she went, but the boot.
        final before = [
          ...e.synopsis, ...e.intro, ...e.objectives,
          for (final m in e.missions) ...[...pageOf(m), ...keptOf(m), ...m.feedback.values, ?m.orderFeedback,
            for (final o in m.options) ?o.feedback,
            SeasonCatalog.discovery(m).title, SeasonCatalog.discovery(m).detail, ?SeasonCatalog.discovery(m).note],
          search.task, search.missLine, search.doneLine, ...search.arrival,
          for (final f in search.finds) ...[f.reportLine, f.foundLine],
          for (final s in search.spots) s.line,
          ...fin.story, fin.letterIntro, fin.letter, fin.question, ...fin.hints,
        ].where((l) => l != boot.inscription).join('\n');
        expect(hasWord(before, 'stations?'), isFalse, reason: level.name);
        expect(hasWord(before, 'trains?'), isFalse, reason: level.name);
        expect(before, isNot(contains("King's Cross")));
        expect(boot.inscription, 'The boot smells of trains and smoke.');
        // The final: the driver's words fit two pictures; the boot decides.
        expect(fin.letter, contains('north'));
        expect(fin.letter, contains('clock tower'));
        expect(fin.letter, isNot(contains('arches')));
        expect(fin.hints.last, allOf(contains('footprint'), contains('notebook')));
        for (final h in fin.hints) {
          expect(hasWord(h, 'stations?|trains?'), isFalse, reason: h);
          expect(h, isNot(contains("King's Cross")));
        }
        expect(fin.transition, contains("KING'S CROSS\nLOST PROPERTY"), reason: 'Case 04');
        expect(fin.transition.join(' '), contains('full of ravens'));
      });
    }
  });

  group("the parent report's English", () {
    test('every expression of Cases 01–03 is on its own level\'s pages', () {
      for (final level in Difficulty.values) {
        final missions = {
          for (final id in cases)
            for (final m in caseAt(id, level).allMissions) m.id: m,
        };
        for (final m in missions.values) {
          final l = SeasonCatalog.learning(m);
          if (l == null) continue;
          final recalled = l.recallFrom == null ? null : missions[l.recallFrom];
          expect(LearningCheck.unmatched(l, m, recalled: recalled), isEmpty, reason: '${m.id} at ${level.name}');
          // The design itself (what it asks of English) is the same at every level.
          final b = SeasonCatalog.learning(base.expand((e) => e.allMissions).firstWhere((x) => x.id == m.id))!;
          expect(DifficultyContent.structureOf(l), DifficultyContent.structureOf(b));
        }
      }
    });

    test('Junior and Master name their own English where their words differ', () {
      // "One hour after the clock stops" is the plan's own rule at every
      // level (Case 12 reads it again): the final's report names it alike.
      const sameEverywhere = {'ep02_final'};
      for (final id in cases) {
        for (final bm in baseCase(id).allMissions) {
          final names = {
            for (final level in Difficulty.values) SeasonCatalog.learning(at(bm.id, level))?.expressions.join('|'),
          };
          // M05 and the final of Case 01 name no English at any level.
          if (names.every((n) => n == null || n.isEmpty)) continue;
          if (sameEverywhere.contains(bm.id)) {
            expect(names, hasLength(1), reason: bm.id);
          } else {
            expect(names.length, greaterThan(1), reason: bm.id);
          }
        }
      }
    });
  });

  group('saves and sessions', () {
    test('a save from before levels plays Cases 01–03 in Rookie\'s words, its progress kept', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: prefsAt(base, 'm03')));
      addTearDown(c.dispose);
      expect(c.read(currentDifficultyProvider), Difficulty.rookie);
      final played = c.read(playedEpisodesProvider).firstWhere((e) => e.id == 'ep01');
      expect(played.toJson(), caseAt('ep01', Difficulty.rookie).toJson());
      final p = c.read(gameControllerProvider);
      expect(p.completedMissionIds, ['m01', 'm02']);
      expect(p.collectedClues(played).map((x) => x.id), ['c01', 'c02']);
      expect(p.collectedEvidence(played).map((x) => x.id), ['e01', 'e02']);
    });

    test('the same save at Junior: the same progress, clues and evidence, Junior\'s words', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: {
        ...prefsAt(base, 'm03'),
        AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep01', difficulty: Difficulty.junior).toJson()),
      }));
      addTearDown(c.dispose);
      final played = c.read(playedEpisodesProvider).firstWhere((e) => e.id == 'ep01');
      expect(played.missionById('m01')!.story, at('m01', Difficulty.junior).story);
      final p = c.read(gameControllerProvider);
      expect(p.completedMissionIds, ['m01', 'm02']);
      expect(p.collectedClues(played).map((x) => '${x.id}:${x.value}'), ['c01:9', 'c02:4']);
      expect(p.collectedClues(played).first.note, 'The suitcase was on a bench next to Platform 9.');
      expect(p.isUnlocked(played, 'm03'), isTrue);
    });

    testWidgets('TESTER: each level chosen plays Cases 01–03 in its words; the player\'s own untouched', (t) async {
      t.view.physicalSize = const Size(390, 844) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({
        AppConstants.detectiveStorageKey: jsonEncode({
          'schema': 1,
          'profile': {'id': 'abcdef0123456789abcdef0123456789', 'origin': 'fresh', 'walletBackfill': 'never', 'detectiveName': 'KIM', 'avatar': 'girl', 'difficulty': 'rookie'},
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      await t.pumpWidget(DevSessionHost(overrides: await testOverridesFor(prefs), child: const WorldMysteryApp()));
      await wait(t, const Duration(milliseconds: 300));
      ProviderContainer session() => ProviderScope.containerOf(t.element(find.byType(WorldMysteryApp)));
      Mission played(ProviderContainer c, String id) =>
          c.read(playedEpisodesProvider).expand((e) => e.allMissions).firstWhere((m) => m.id == id);
      final own = session();
      expect(played(own, 'm01').story, at('m01', Difficulty.rookie).story);

      own.read(gameMasterAccessProvider.notifier).grant();
      own.read(routerProvider).go(Routes.gameMaster);
      await wait(t, const Duration(milliseconds: 600));
      await tapText(t, 'START DEVELOPER MODE', after: const Duration(milliseconds: 900));
      for (final level in [Difficulty.junior, Difficulty.master, Difficulty.rookie]) {
        await reveal(t, find.byKey(ValueKey('difficulty-${level.storageId}')));
        await t.tap(find.byKey(ValueKey('difficulty-${level.storageId}')));
        await wait(t, const Duration(milliseconds: 600));
        for (final id in ['m01', 'ep02_m2', 'ep03_final']) {
          expect(played(session(), id).toJson(), at(id, level).toJson(), reason: '$id at ${level.name}');
        }
        expect(SeasonCatalog.explore(played(session(), 'm01'))!.task, SeasonCatalog.explore(at('m01', level))!.task);
      }
      expect(played(own, 'm01').story, at('m01', Difficulty.rookie).story, reason: "the player's words untouched");
      await tapText(t, 'EXIT DEVELOPER MODE', after: const Duration(milliseconds: 900));
      await wait(t, const Duration(seconds: 2));
    });
  });

  group('on screen', () {
    Future<void> open(WidgetTester t, String missionId, Difficulty level) async {
      t.view.physicalSize = const Size(390, 844) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final e = base.firstWhere((e) => e.missions.any((m) => m.id == missionId));
      final prefs = {
        ...prefsAt(base, missionId),
        AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(
          activeEpisodeId: e.id,
          solvedEpisodeIds: [for (final x in base) if (x.seasonId == e.seasonId && x.number < e.number) x.id],
          difficulty: level,
        ).toJson()),
      };
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: prefs),
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const WorldMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      ref.read(routerProvider).go(Routes.mission(missionId));
      await wait(t, const Duration(milliseconds: 1200));
    }

    for (final level in Difficulty.values) {
      testWidgets('Case 01 M1 at ${level.label}: the station in ${level.label}\'s words', (t) async {
        await open(t, 'm01', level);
        expect(find.byKey(const ValueKey('explore-picture')), findsOneWidget);
        final scene = SeasonCatalog.explore(at('m01', level))!;
        expect(findReadable(scene.task), findsOneWidget, reason: level.name);
        for (final other in Difficulty.values.where((l) => l != level)) {
          final task = SeasonCatalog.explore(at('m01', other))!.task;
          if (task != scene.task) expect(findReadable(task), findsNothing);
        }
        await wait(t, const Duration(seconds: 2));
      });

      testWidgets('Case 03 M2 at ${level.label}: its question and choices', (t) async {
        await open(t, 'ep03_m2', level);
        final m = at('ep03_m2', level);
        expect(findReadable(m.question), findsOneWidget, reason: level.name);
        for (final o in m.options) {
          expect(find.textContaining(o.label), findsWidgets);
        }
        await wait(t, const Duration(seconds: 2));
      });
    }
  });

  test('the old save JSON of a case is read the same at every level (the levels are never saved)', () {
    final progress = GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: const ['ep03_m1', 'ep03_m2']);
    final json = jsonEncode(progress.toJson());
    for (final level in Difficulty.values) {
      final e = caseAt('ep03', level);
      final p = GameProgress.fromJson(jsonDecode(json) as Map<String, dynamic>);
      expect(p.collectedEvidence(e).map((x) => x.id), ['ep03_e1', 'ep03_e2']);
      expect(jsonEncode(p.toJson()), json);
    }
  });
}
