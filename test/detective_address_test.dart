import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season1/season1_explores.dart';
import 'package:world_mystery/data/models/detective_name.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/widgets/detective_character.dart';
import 'package:world_mystery/widgets/letter_card.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'personalized_lines.dart';

/// The player is the detective: the letters and people that speak to them
/// call them by the name they chose ("Dear Detective Luna,"), only there,
/// and nothing a puzzle reads changes.
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode byId(String id) => season.firstWhere((e) => e.id == id);
  const p = DetectiveName.placeholder;

  group('the address', () {
    test('a name, a Hangul name, no name', () {
      const letter = 'Dear Detective $p,\n\nI took the Crown!';
      expect(DetectiveName.address(letter, 'Luna'), 'Dear Detective Luna,\n\nI took the Crown!');
      expect(DetectiveName.address(letter, '지우'), 'Dear Detective 지우,\n\nI took the Crown!');
      expect(DetectiveName.address(letter, null), 'Dear Detective,\n\nI took the Crown!');
      expect(DetectiveName.address(letter, ''), 'Dear Detective,\n\nI took the Crown!');
      expect(DetectiveName.address(letter, '   '), 'Dear Detective,\n\nI took the Crown!');
      expect(DetectiveName.address('Hello again, Detective $p," he says.', 'Luna'), 'Hello again, Detective Luna," he says.');
      expect(DetectiveName.address('You cannot prove it, Detective $p!"', null), 'You cannot prove it, Detective!"');
    });

    test('the name as typed: trimmed, its case kept, never titled twice', () {
      const letter = 'Dear Detective $p,';
      expect(DetectiveName.address(letter, '  Luna  '), 'Dear Detective Luna,');
      expect(DetectiveName.address(letter, 'Mary  Jo'), 'Dear Detective Mary Jo,');
      expect(DetectiveName.address(letter, 'alex'), 'Dear Detective alex,');
      expect(DetectiveName.address(letter, 'MIN'), 'Dear Detective MIN,');
      expect(DetectiveName.address(letter, 'Detective Lu'), 'Dear Detective Lu,');
      expect(DetectiveName.address(letter, 'detective'), 'Dear detective,');
      expect(DetectiveName.address(letter, 'Detectives'), 'Dear Detective Detectives,', reason: 'only the word itself');
    });

    test('a name is put in as it is, never read as a pattern', () {
      for (final odd in [r'$1', r'\n', r'$&', '.-.', 'A.B-C']) {
        expect(DetectiveName.address('Dear Detective $p,', odd), 'Dear Detective $odd,');
      }
    });

    test('the title on its own', () {
      expect(DetectiveName.title('Luna'), 'Detective Luna');
      expect(DetectiveName.title('지우'), 'Detective 지우');
      expect(DetectiveName.title(null), 'Detective');
      expect(DetectiveName.title(''), 'Detective');
      expect(DetectiveName.title('Detective Lu'), 'Detective Lu');
      expect(DetectiveName.title('DETECTIVE'), 'DETECTIVE', reason: "the report's stand-in, not titled twice");
    });
  });

  group('the season names the detective only where it speaks to them', () {
    /// Every string of [json], with where it is.
    Iterable<(String, String)> strings(Object? json, [String at = '']) sync* {
      switch (json) {
        case String s:
          yield (at, s);
        case Map m:
          for (final e in m.entries) {
            yield* strings(e.value, '$at/${e.key}');
          }
        case List l:
          for (final (i, v) in l.indexed) {
            yield* strings(v, '$at/$i');
          }
      }
    }

    test('exactly the lines chosen, each in its own field', () {
      final found = <String>[];
      for (final e in season) {
        for (final (at, s) in strings(e.toJson())) {
          if (s.contains(p)) found.add('${e.id}$at');
        }
      }
      expect(found, hasLength(personalizedLines.length));
      for (final (caseId, missionId, field, _, after) in personalizedLines) {
        final m = byId(caseId).missionById(missionId)!;
        final text = switch (field) {
          'letter' => m.letter,
          'successMessage' => m.successMessage,
          'story' => m.story.join('\n'),
          'transition' => m.transition.join('\n'),
          _ => throw StateError(field),
        };
        expect(text, contains(after), reason: '$missionId $field');
        expect(p.allMatches(text), hasLength(1), reason: '$missionId: once');
      }
    });

    test('always as "Detective {detectiveName}", never in what a puzzle reads', () {
      for (final e in season) {
        for (final m in e.allMissions) {
          final json = m.toJson();
          for (final (at, s) in strings(json)) {
            if (!s.contains(p)) continue;
            expect(at, anyOf(['/letter', '/successMessage'].map(equals).toList()..add(startsWith('/story/'))..add(startsWith('/transition/'))),
                reason: '${m.id}$at');
            expect(s.replaceAll('Detective $p', ''), isNot(contains(p)), reason: '${m.id}$at');
          }
          for (final s in [m.answer, ...m.acceptedAnswers, m.question, ?m.prompt, ...m.hints, ...m.feedback.values, ?m.orderFeedback]) {
            expect(s, isNot(contains(p)), reason: m.id);
          }
          for (final o in m.options) {
            expect('${o.label} ${o.feedback} ${o.altText}', isNot(contains(p)), reason: m.id);
          }
          expect(jsonEncode(m.clue?.toJson()), isNot(contains(p)), reason: m.id);
          expect(jsonEncode(m.evidence?.toJson()), isNot(contains(p)), reason: m.id);
        }
        expect('${e.intro} ${e.synopsis} ${e.objectives} ${e.hook} ${e.caseSummary} ${e.glossary}', isNot(contains(p)));
      }
    });

    test('the letters not written to this detective are as they were', () {
      // R. writes to whoever finds the letter; the door, to any true detective.
      expect(byId('ep04').missionById('ep04_m1')!.letter, startsWith('To the detective who finds this letter,\n'));
      expect(byId('ep04').intro, contains('On the envelope, it says: "For the detective."'));
      expect(byId('ep12').finalMission.letter, startsWith('Only a true detective can open me.'));
      // The whistle's words, as written on it; Mrs Bell's "Clever detective!".
      expect(byId('ep06').finalMission.evidence!.inscription, '"Blow it if you need help."');
      expect(byId('ep02').finalMission.letter, startsWith('Clever detective!'));
      // A note between the thieves, a guard's report, the witnesses.
      expect(byId('ep09').finalMission.letter, startsWith('Hide it in the thing of the one whose key you used.'));
      expect(byId('ep03').missionById('ep03_m1')!.letter, startsWith('GUARD REPORT'));
    });

    test('the answers of the lines that name the detective are as they were', () {
      final answers = {
        for (final (caseId, missionId, _, _, _) in personalizedLines) missionId: byId(caseId).missionById(missionId)!.answer,
      };
      expect(answers, {
        'm01': 'b',
        'ep02_m1': '817',
        'ep02_m2': 'c',
        'ep04_m3': 'b',
        'ep04_final': 'RAVEN',
        'ep06_final': 'c',
        'ep08_m1': 'b',
        'ep08_final': 'c',
        'ep11_final': 'd',
      });
    });
  });

  group('on screen', () {
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

    /// The app on a phone of [size], [name] the detective of Case [caseId]
    /// with [solved] of its missions solved (the cases before it closed).
    Future<ProviderContainer> start(
      WidgetTester t,
      Size size, {
      required String? name,
      String caseId = 'ep01',
      List<String> solved = const [],
      bool closed = false,
      double textScale = 1,
    }) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      t.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
      t.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final e = byId(caseId);
      final upTo = season.indexOf(e);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          AppConstants.progressKeyFor(caseId): jsonEncode(GameProgress(
            detectiveName: name,
            introSeen: true,
            completedMissionIds: solved,
            startedAt: DateTime(2026, 9, 29, 10),
            completedAt: closed ? DateTime(2026, 9, 29, 10, 30) : null,
            playMillis: 0,
          ).toJson()),
          if (caseId != AppConstants.currentEpisodeId)
            AppConstants.progressStorageKey: jsonEncode(GameProgress(detectiveName: name).toJson()),
          AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(
            activeEpisodeId: caseId,
            solvedEpisodeIds: [for (final c in season.take(closed ? upTo + 1 : upTo)) c.id],
          ).toJson()),
        }),
        child: const WorldMysteryApp(),
      ));
      await wait(t, const Duration(milliseconds: 300));
      return ProviderScope.containerOf(find.byType(WorldMysteryApp).evaluate().first);
    }

    /// Case 01's first letter, opened: found in the old suitcase on the
    /// bench at King's Cross, and its envelope opened there.
    Future<ProviderContainer> openFirstLetter(WidgetTester t, Size size, String? name, {double textScale = 1}) async {
      final app = await start(t, size, name: name, textScale: textScale);
      app.read(routerProvider).go(Routes.mission('m01'));
      await wait(t, const Duration(milliseconds: 1200));
      final investigate = find.text('INVESTIGATE');
      await t.scrollUntilVisible(investigate, 250, scrollable: find.byType(Scrollable).first);
      await t.tap(investigate);
      await wait(t, const Duration(milliseconds: 700));
      final picture = t.getRect(find.byKey(const ValueKey('explore-picture')));
      final suitcase = exploreOf(byId('ep01').missions.first)!.spot('suitcase').areas.first.center;
      await t.tapAt(Offset(picture.left + suitcase.dx * picture.width, picture.top + suitcase.dy * picture.height));
      await wait(t, const Duration(milliseconds: 600));
      await t.tap(find.text('TAP TO OPEN'));
      await wait(t, const Duration(milliseconds: 1600));
      expect(find.text('BACK TO THE STATION'), findsOneWidget);
      return app;
    }

    for (final (name, greeting) in const [
      ('Luna', 'Dear Detective Luna,'),
      ('지우', 'Dear Detective 지우,'),
      ('Mary-Jo Lee', 'Dear Detective Mary-Jo Lee,'),
      ('Detective Lu', 'Dear Detective Lu,'),
    ]) {
      testWidgets('the Shadow writes to $name: "$greeting"', (t) async {
        await openFirstLetter(t, const Size(390, 844), name);
        expect(t.takeException(), isNull);
        expect(findReadable(greeting), findsOneWidget);
        expect(findReadable('I took the Crown! Ha ha!'), findsOneWidget, reason: 'the rest as written');
        expect(findReadableContaining(p), findsNothing);
      });
    }

    testWidgets('without a name (a save from before names), the letter reads as it did', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(),
        child: MaterialApp(home: Scaffold(body: LetterCard(text: byId('ep01').missions.first.letter))),
      ));
      await t.pump();
      expect(t.takeException(), isNull);
      expect(findReadable('Dear Detective,'), findsOneWidget);
      expect(findReadableContaining(p), findsNothing);
    });

    for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
      for (final scale in const [1.0, 1.3]) {
        final tag = '${size.width.toInt()}x${size.height.toInt()}@$scale';
        testWidgets('the longest name $tag: inside the letter, clear of the seal', (t) async {
          const name = 'MMMMMMMMMMMM'; // 12 letters, the widest there are
          await openFirstLetter(t, size, name, textScale: scale);
          expect(t.takeException(), isNull, reason: 'no overflow');
          final line = findReadable('Dear Detective $name,');
          expect(line, findsOneWidget);
          final letter = t.getRect(find.byType(LetterCard));
          final r = t.getRect(line);
          expect(r.left, greaterThanOrEqualTo(letter.left));
          expect(r.right, lessThanOrEqualTo(letter.right));
          final seal = t.getRect(find.byType(WaxSeal));
          expect(r.overlaps(seal), isFalse, reason: 'the greeting and the seal');
          expect(t.getRect(find.text('BACK TO THE STATION')).width, greaterThan(0));
        });
      }
    }

    testWidgets('the name is never a dotted word, the same word elsewhere still is', (t) async {
      // "Crown" is a Case 01 word, and the letter's own Crown keeps its meaning.
      expect(byId('ep01').meaningOf('Crown'), isNotNull);
      await openFirstLetter(t, const Size(390, 844), 'Crown');
      final greeting = findReadable('Dear Detective Crown,');
      final crown = findReadable('I took the Crown! Ha ha!');
      List<TextSpan> spans(Finder f) => [
        for (final s in (t.widget<Text>(f).textSpan! as TextSpan).children!) s as TextSpan,
      ];
      expect(spans(greeting).firstWhere((s) => s.text == 'Crown').recognizer, isNull);
      expect(spans(crown).firstWhere((s) => s.text == 'Crown').recognizer, isNotNull);
      // A tap on the name opens no word card.
      await t.tap(greeting);
      await wait(t, const Duration(milliseconds: 400));
      expect(find.text('WORD CARD'), findsNothing);
    });

    testWidgets('a new name is in the letter at once', (t) async {
      final app = await openFirstLetter(t, const Size(390, 844), 'Luna');
      expect(findReadable('Dear Detective Luna,'), findsOneWidget);
      expect(app.read(gameControllerProvider.notifier).renameDetective('지우'), isNull);
      await wait(t, const Duration(milliseconds: 300));
      expect(findReadable('Dear Detective 지우,'), findsOneWidget);
      expect(findReadableContaining('Luna'), findsNothing);
    });

    testWidgets('the Shadow greets the detective by name, and nobody else does more', (t) async {
      final e = byId('ep11');
      final app = await start(t, const Size(360, 640), name: 'Luna', caseId: 'ep11', solved: [for (final m in e.missions) m.id]);
      app.read(routerProvider).go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1500));
      expect(t.takeException(), isNull);
      expect(findReadable('"Hello again, Detective Luna," he says. "Do you remember me?"'), findsOneWidget);
      expect(findReadableContaining('Detective Luna'), findsOneWidget, reason: 'once on the page');
    });

    testWidgets('the case file names the detective once', (t) async {
      final e = byId('ep01');
      final app = await start(t, const Size(360, 640),
          name: 'Luna', solved: [for (final m in e.allMissions) m.id], closed: true);
      app.read(routerProvider).go(Routes.solved);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await wait(t, const Duration(milliseconds: 3200));
      expect(t.takeException(), isNull);
      expect(find.text('CASE CLOSED'), findsOneWidget);
      expect(find.text('Luna'), findsOneWidget, reason: 'its DETECTIVE line, as before');
      expect(find.textContaining('Detective Luna'), findsNothing, reason: 'not again under it');
      expect(find.byWidgetPredicate((w) => w is PlayerDetective && w.semanticLabel == 'Detective Luna, case solved'), findsOneWidget);
    });
  });
}
