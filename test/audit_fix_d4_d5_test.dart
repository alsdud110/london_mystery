import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/widgets/glossary_text.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'mission_play.dart';
import 'personalized_lines.dart';

/// Season 1 audit fixes D4 (word meanings where a child gets stuck: answer
/// cards, tips, the try-again line, the final case's question) and D5 (the
/// words a deduction turns on are in the glossary).
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode byId(String id) => season.firstWhere((e) => e.id == id);

  group('D5 — the words a deduction turns on have a meaning', () {
    // Each word as the sentence writes it (case, punctuation, plural).
    final words = <(String, String, String)>[
      ('ep03', 'The boot smells of trains and smoke.', 'smells'),
      ('ep03', 'The boot smells of trains and smoke.', 'smoke.'),
      (
        'ep03',
        "Open your notebook and look closer at the footprint. 'Smells of …' tells you where she had been. Which clock tower fits?",
        "'Smells",
      ),
      ('ep03', "KING'S CROSS — LOST PROPERTY", 'PROPERTY'),
      ('ep03', 'Luggage Tag', 'Luggage'),
      (
        'ep03',
        'You started with the driest step. Her first step was the wettest.',
        'wettest.',
      ),
      // Mrs Robin speaks to the detective by name (2026-10-17).
      ('ep08', 'You cannot prove it, Detective {detectiveName}!"', 'prove'),
      ('ep08', 'Which evidence shows that she was in Gallery 8?', 'evidence'),
      ('ep08', 'Think back to an earlier case.', 'earlier'),
      // 06-M3's question names the five details (2026-10-15 wording); its
      // ticket's raven mark (2026-10-16); 09-F's umbrella line.
      ('ep06', 'Compare the five details: height, person, coat, hat, and bag. How many are different?', 'Compare'),
      ('ep06', 'Compare the five details: height, person, coat, hat, and bag. How many are different?', 'details'),
      ('ep06', 'Compare the five details: height, person, coat, hat, and bag. How many are different?', 'height,'),
      ('ep06', 'Compare the five details: height, person, coat, hat, and bag. How many are different?', 'person,'),
      ('ep06', 'On the back, a black raven is stamped: the mark of the Raven Society.', 'stamped'),
      ('ep06', 'On the back, a black raven is stamped: the mark of the Raven Society.', 'mark'),
      ('ep09', "Anna borrowed the key, but the note says WHOSE key you used. Was it Anna's own key?", 'borrowed'),
      ('ep05', "'The other way' is the opposite way.", 'opposite'),
      (
        'ep10',
        "'Put together' means two words side by side make one name.",
        'together',
      ),
    ];

    // Every string a case shows (its glossary aside).
    List<String> strings(Object? x) => switch (x) {
      String s => [s],
      Map m => [
        for (final e in m.entries)
          if (e.key != 'glossary') ...strings(e.value),
      ],
      List l => [for (final v in l) ...strings(v)],
      _ => const [],
    };

    test('each one is in its sentence, and its case explains it', () {
      for (final (caseId, sentence, word) in words) {
        final e = byId(caseId);
        expect(
          strings(e.toJson()).any((s) => s.contains(sentence)),
          isTrue,
          reason: '$caseId: "$sentence"',
        );
        expect(sentence, contains(word));
        expect(
          e.meaningOf(word.replaceAll(RegExp(r"^'|[.,!?]+$"), '')),
          isNotNull,
          reason: '$caseId: $word',
        );
        expect(
          glossaryWordsOf(e, sentence).map((w) => w.word),
          contains(word.replaceAll(RegExp(r"^'|[.,!?]+$"), '')),
          reason: '$caseId: $word, as it is written',
        );
      }
    });

    test('the words that read two ways keep the sense the tips use', () {
      // Case 05: "the right number of left and right turns" — both senses in
      // one line, 맞는 first (2026-10-15 wording).
      expect(byId('ep05').meaningOf('right'), allOf(contains('오른쪽'), contains('맞는')));
      expect(byId('ep05').missionById('ep05_m2')!.orderFeedback, allOf(contains('the right number'), contains('right turns')));
      // Case 07: "Inspector Grey was right", "the right spot" — and still
      // "Turn right at the bridge".
      final c07 = byId('ep07');
      expect(c07.intro, contains('Inspector Grey was right.'));
      expect(
        c07.missionById('ep07_m1')!.question,
        'Which map shows the right spot?',
      );
      expect(
        c07.missionById('ep07_m1')!.letter,
        contains('Turn right at the bridge.'),
      );
      expect(c07.meaningOf('right'), allOf(contains('오른쪽'), contains('맞는')));
      // Case 01: King's Cross, a station; Case 02: Mrs Bell, a person.
      expect(byId('ep01').meaningOf("King's"), contains("King's Cross"));
      expect(byId('ep02').meaningOf("Bell's"), contains('Mrs Bell'));
      // Case 04: "Open your notebook".
      expect(byId('ep04').meaningOf('Open'), contains('열다'));
    });

    test('no new meaning hands over an answer', () {
      final answers = {
        for (final e in season)
          for (final m in e.allMissions)
            if (m.type == MissionType.wordInput)
              ...[m.answer, ...m.acceptedAnswers].map((a) => a.toLowerCase()),
      };
      const added = [
        'complete', 'sentences', 'opposites', 'moment', 'smells', 'smoke', 'wettest', 'driest', 'luggage', 'property',
        'describes', 'opposite', 'compare', 'matches', 'upside', 'prove', 'evidence', 'earlier', 'counts', 'together',
        'enough', 'shapes', 'tunnel',
        // 2026-10-16: 06-M3's details and the ticket's mark, 09-F's umbrella line.
        'details', 'height', 'person', 'stamped', 'mark', 'borrowed',
      ];
      for (final w in added) {
        expect(answers, isNot(contains(w)), reason: w);
      }
      // A word only the right card has would point at it.
      for (final e in season) {
        for (final m in e.allMissions.where(
          (m) => m.type == MissionType.multipleChoice,
        )) {
          final right = m.options
              .firstWhere((o) => o.id == m.answer)
              .label
              .toLowerCase();
          final others = m.options
              .where((o) => o.id != m.answer)
              .map((o) => o.label.toLowerCase())
              .join(' ');
          for (final w in added) {
            if (RegExp('\\b$w\\b').hasMatch(right)) {
              expect(others, contains(w), reason: '${m.id}: $w');
            }
          }
        }
      }
    });

    test('only the glossaries changed: every other field of every case is as before', () {
      // FNV-1a of each case's JSON without its glossary, before this pass.
      int fnv(String s) {
        var h = 0x811c9dc5;
        for (final c in utf8.encode(s)) {
          h = ((h ^ c) * 0x01000193) & 0xffffffff;
        }
        return h;
      }

      // The lines that speak to the detective by name are read as they were
      // (2026-10-17, see personalized_lines.dart).
      expect({for (final e in season) e.id: fnv(withoutNames(jsonEncode(e.toJson()..remove('glossary'))))}, const {
        // Case 01 M4 matches the palace artwork (commit 3ea9964: letter 2
        // lines, option a feedback, 2 tips). See test/case01_m4_scope_test.dart.
        // Every case below, again (2026-10-16, approved): the season copy
        // pass of commit 0c169cd (success lines, scenes, wrong-answer lines
        // and tips that point to what was misread without the answer), with
        // its follow-up — 01-M1 tip 2, 02-F '817' line and tip 2, 03-M3 tip 2,
        // 05-M2 the Direction Note keeps its turns, 06-M3 lines, tip 2 and the
        // ticket's raven mark, 06-F option a, 09-F umbrella line.
        'ep01': 2429473966,
        'ep02': 1023821448,
        // Wave 1 (2026-10-14): 03-M1 is searched; its tip 2 reads the place
        // words. Wave 1.1: the report says 'I noticed three things in the
        // gallery' (not all on the floor). Wave 1.2: 'GALLERY 8' in its title
        // never breaks (a no-break space). See test/case03_investigation_test.dart.
        'ep03': 494843145,
        'ep04': 3227171614,
        'ep05': 3809709994,
        'ep06': 878804669,
        'ep07': 923859634,
        'ep08': 932948487,
        'ep09': 3984906767,
        'ep10': 1240895729,
        'ep11': 2763911661,
        'ep12': 3222189086,
      });
    });
  });

  group('D4 — meanings where a child gets stuck', () {
    for (final (size, tag) in const [
      (Size(360, 640), '360x640'),
      (Size(390, 844), '390x844'),
    ]) {
      testWidgets(
        'answer cards $tag: a tap chooses first; on the chosen card a word shows its meaning',
        (t) async {
          final play = MissionPlay();
          final m = await play.openPuzzle(t, size, 'm01');
          const label = 'The Science Museum (rockets and machines)';
          final card = findReadable(label);
          expect(card, findsOneWidget, reason: 'not chosen: plain words');

          // A tap on a word of a card not yet chosen chooses the card.
          await reveal(t, card);
          await t.tapOnText(find.textRange.ofSubstring('rockets'));
          await wait(t, const Duration(milliseconds: 400));
          expect(
            find.text('WORD CARD'),
            findsNothing,
            reason: 'choosing comes first',
          );
          expect(_chosen(t, label), isTrue);

          // On the chosen card, the same word shows its meaning, and nothing else.
          await t.tapOnText(find.textRange.ofSubstring('rockets'));
          await wait(t, const Duration(milliseconds: 600));
          expect(
            find.text('= ${byId('ep01').meaningOf('rockets')}'),
            findsOneWidget,
          );
          expect(
            find.text('Not quite!'),
            findsNothing,
            reason: 'no answer was checked',
          );
          await tapText(t, 'GOT IT!', after: const Duration(milliseconds: 500));
          expect(
            _chosen(t, label),
            isTrue,
            reason: 'the card stays chosen after the word card closes',
          );
          expect(play.path(), Routes.mission('m01'));

          // Every card: inside the screen and a comfortable target.
          for (final o in m.options) {
            final r = t.getRect(findReadable(o.label));
            expect(r.left, greaterThanOrEqualTo(0), reason: o.label);
            expect(r.right, lessThanOrEqualTo(size.width), reason: o.label);
          }
          expect(t.takeException(), isNull);
        },
      );

      testWidgets('tips and the try-again line $tag: a word shows its meaning; the sheet and tips stay', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep05_m2');
        // Wrong order: two lefts and two rights, so the order line shows.
        for (final step in ['TURN LEFT', 'TURN LEFT', 'TURN RIGHT', 'TURN RIGHT']) {
          final tile = find.text(step).last;
          await reveal(t, tile);
          await t.tap(tile);
          await t.pump(const Duration(milliseconds: 150));
        }
        await tapText(t, 'CHECK ANSWER');
        expect(find.text('Not quite!'), findsOneWidget);
        final line = byId('ep05').missionById('ep05_m2')!.orderFeedback!;
        expect(findReadable(line), findsOneWidget);
        // "You have the right number of left and right turns…" — the first
        // "right" (맞는), the sense the line is about.
        await t.tapOnText(find.textRange.ofSubstring('right').first);
        await wait(t, const Duration(milliseconds: 600));
        expect(find.text('= ${byId('ep05').meaningOf('right')}'), findsOneWidget);
        await tapText(t, 'GOT IT!', after: const Duration(milliseconds: 500));
        expect(find.text('Not quite!'), findsOneWidget, reason: 'the try-again sheet is still open');
        await tapText(t, 'GET MORE HINTS', after: const Duration(milliseconds: 700));
        await takeTipFromSheet(t);

          final tip = byId('ep05').missionById('ep05_m2')!.hints.last;
          // The first tip opened from the sheet; open the second from the page.
          await tapText(
            t,
            'Get More Hints',
            after: const Duration(milliseconds: 600),
          );
          await takeTipFromSheet(t);
          await reveal(t, findReadable(tip));
          await t.tapOnText(find.textRange.ofSubstring('opposite'));
          await wait(t, const Duration(milliseconds: 600));
          expect(
            find.text('= ${byId('ep05').meaningOf('opposite')}'),
            findsOneWidget,
          );
          await tapText(t, 'GOT IT!', after: const Duration(milliseconds: 500));
          expect(
            findReadable(tip),
            findsOneWidget,
            reason: 'the tips stay open',
          );
          expect(play.path(), Routes.mission('ep05_m2'));
          expect(t.takeException(), isNull);
        },
      );

      testWidgets(
        'the final question $tag: its words show their meaning on the dark desk',
        (t) async {
          await _openFinal(t, size, season, 'ep08');
          final q = byId('ep08').finalMission.question;
          await reveal(t, findReadable(q));
          await t.tapOnText(find.textRange.ofSubstring('evidence'));
          await wait(t, const Duration(milliseconds: 600));
          expect(find.text('= 증거'), findsOneWidget);
          await tapText(t, 'GOT IT!', after: const Duration(milliseconds: 500));
          expect(findReadable(q), findsOneWidget);
          expect(t.takeException(), isNull);
        },
      );
    }

    testWidgets('text 1.3×: a chosen card with its dotted words still fits', (
      t,
    ) async {
      final play = MissionPlay();
      final m = await play.openPuzzle(
        t,
        const Size(360, 640),
        'm01',
        textScale: 1.3,
      );
      for (final o in m.options) {
        await reveal(t, findReadable(o.label));
        await t.tap(findReadable(o.label));
        await wait(t, const Duration(milliseconds: 200));
        final r = t.getRect(findReadable(o.label));
        expect(r.right, lessThanOrEqualTo(360), reason: o.label);
        expect(t.takeException(), isNull, reason: o.label);
      }
    });

    testWidgets(
      'screen readers: an answer card is one answer, with its words as actions',
      (t) async {
        final semantics = t.ensureSemantics();
        final play = MissionPlay();
        await play.openPuzzle(t, const Size(390, 844), 'm01');
        const label = 'C. The London Transport Museum (old buses and trains)';
        final node = t.getSemantics(find.bySemanticsLabel(label));
        final actions = [
          for (final id
              in node.getSemanticsData().customSemanticsActionIds ??
                  const <int>[])
            CustomSemanticsAction.getAction(id)!.label,
        ];
        expect(
          actions,
          containsAll([
            'Meaning of Transport',
            'Meaning of Museum',
            'Meaning of buses',
            'Meaning of trains',
          ]),
        );
        semantics.dispose();
      },
    );

    testWidgets('the story text keeps its dotted words (unchanged)', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm01');
      await tapText(
        t,
        'Reread Letter',
        after: const Duration(milliseconds: 600),
      );
      await t.tapOnText(find.textRange.ofSubstring('museum').first);
      await wait(t, const Duration(milliseconds: 600));
      expect(find.text('= 박물관'), findsOneWidget);
    });
  });
}

/// Whether the answer card showing [label] is the chosen one.
bool _chosen(WidgetTester t, String label) {
  final semantics = find
      .ancestor(of: findReadable(label), matching: find.byType(Semantics))
      .first;
  return t.widget<Semantics>(semantics).properties.selected ?? false;
}

/// The final case of [caseId] open on its puzzle (earlier cases and its
/// missions solved).
Future<void> _openFinal(
  WidgetTester t,
  Size size,
  List<Episode> season,
  String caseId,
) async {
  t.view.physicalSize = size * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final e = season.firstWhere((x) => x.id == caseId);
  final earlier = [
    for (final x in season)
      if (x.number < e.number) x,
  ];
  final start = DateTime.now().subtract(const Duration(minutes: 1));
  String progress(List<String> done, {bool solved = false}) => jsonEncode(
    GameProgress(
      detectiveName: 'MINYOUNG',
      introSeen: true,
      completedMissionIds: done,
      startedAt: start,
      completedAt: solved ? start : null,
      playMillis: 0,
    ).toJson(),
  );
  await t.pumpWidget(
    ProviderScope(
      overrides: await testOverrides(
        prefs: {
          for (final x in earlier)
            AppConstants.progressKeyFor(x.id): progress([
              for (final m in x.allMissions) m.id,
            ], solved: true),
          AppConstants.progressKeyFor(e.id): progress([
            for (final m in e.missions) m.id,
          ]),
          AppConstants.seasonStorageKey: jsonEncode(
            SeasonProgress(
              activeEpisodeId: e.id,
              solvedEpisodeIds: [for (final x in earlier) x.id],
            ).toJson(),
          ),
        },
      ),
      child: const LondonMysteryApp(),
    ),
  );
  await wait(t, const Duration(milliseconds: 300));
  ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first)
      .read(routerProvider)
      .go(Routes.finalMission);
  await wait(t, const Duration(milliseconds: 1200));
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 500)),
  );
  await t.pump();
}
