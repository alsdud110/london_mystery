import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season1/season1_dialogues.dart';
import 'package:london_mystery/data/mock/season1/season1_investigations.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/widgets/centered_scroll.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:london_mystery/widgets/letter_card.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// The place and the puzzle of every plain mission (not a search, a talk or
/// the final case) follow the letter page's rule: the page's group centred
/// under the bar when it fits, read from the top and scrolled when it does
/// not — whatever the case, the puzzle type, the phone or the text size.
void main() {
  final season = MockEpisodeRepository.bundled();
  final plain = [
    for (final e in season)
      for (final m in e.missions)
        if (!m.isFinal && investigationOf(m) == null && dialogueOf(m) == null)
          m,
  ];

  setUpAll(() async {
    for (final (family, files) in [
      ('Sentient', ['Sentient-Variable.ttf']),
      ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
      (
        'LibreBaskerville',
        ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf'],
      ),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  /// [missionId] open at its place ([puzzle] false) or its puzzle, earlier
  /// cases and missions solved, on a phone with a notch and a home bar.
  Future<Mission> open(
    WidgetTester t,
    String missionId, {
    required bool puzzle,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    t.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    final e = season.firstWhere(
      (x) => x.missions.any((m) => m.id == missionId),
    );
    final earlier = [
      for (final x in season)
        if (x.number < e.number) x,
    ];
    final start = DateTime.now().subtract(const Duration(minutes: 1));
    String progress(
      List<String> done, {
      bool solved = false,
      Map<String, DateTime> started = const {},
    }) => jsonEncode(
      GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: done,
        missionStartedAt: started,
        startedAt: start,
        completedAt: solved ? start : null,
        playMillis: 0,
      ).toJson(),
    );
    late WidgetRef ref;
    await t.pumpWidget(
      ProviderScope(
        overrides: await testOverrides(
          prefs: {
            for (final x in earlier)
              AppConstants.progressKeyFor(x.id): progress([
                for (final m in x.allMissions) m.id,
              ], solved: true),
            if (e.id != AppConstants.currentEpisodeId)
              AppConstants.progressStorageKey: jsonEncode(
                const GameProgress(detectiveName: 'MINYOUNG').toJson(),
              ),
            AppConstants.progressKeyFor(e.id): progress(
              [
                for (final m in e.missions.takeWhile((m) => m.id != missionId))
                  m.id,
              ],
              started: {if (puzzle) missionId: start},
            ),
            AppConstants.seasonStorageKey: jsonEncode(
              SeasonProgress(
                activeEpisodeId: e.id,
                solvedEpisodeIds: [for (final x in earlier) x.id],
              ).toJson(),
            ),
          },
        ),
        child: RepaintBoundary(
          key: const ValueKey('shot'),
          child: Consumer(
            builder: (context, r, _) {
              ref = r;
              return const LondonMysteryApp();
            },
          ),
        ),
      ),
    );
    await wait(t, const Duration(milliseconds: 300));
    ref.read(routerProvider).go(Routes.mission(missionId));
    await wait(t, const Duration(milliseconds: 1600));
    expect(
      puzzle ? find.textContaining('· THE PUZZLE') : find.text('INVESTIGATE'),
      findsOneWidget,
      reason: '$missionId at its ${puzzle ? 'puzzle' : 'place'}',
    );
    expect(t.takeException(), isNull);
    return e.missionById(missionId)!;
  }

  Finder page() => find.descendant(
    of: find.byType(CenteredScroll),
    matching: find.byType(SingleChildScrollView),
  );

  /// The page's group: from its first child's top to its last child's bottom.
  Rect group(WidgetTester t) {
    final flex = t.renderObject<RenderFlex>(
      find
          .descendant(
            of: find.byType(CenteredScroll),
            matching: find.byType(Column),
          )
          .first,
    );
    final first = flex.firstChild!, last = flex.lastChild!;
    final top = flex
        .localToGlobal((first.parentData! as FlexParentData).offset)
        .dy;
    final bottom =
        flex.localToGlobal((last.parentData! as FlexParentData).offset).dy +
        last.size.height;
    return Rect.fromLTRB(0, top, 1, bottom);
  }

  /// Centred when the group fits; otherwise read from the top, and scrolled
  /// to its end, the last of it above the page's bottom margin.
  Future<bool> expectCentredOrScrolled(WidgetTester t, String what) async {
    final view = t.getRect(page());
    final g = group(t);
    final fits = g.height + 2 * _margin <= view.height + 0.5;
    if (fits) {
      expect(
        (g.top - view.top) - (view.bottom - g.bottom),
        moreOrLessEquals(0, epsilon: 1),
        reason: '$what: centred',
      );
    } else {
      expect(
        g.top - view.top,
        moreOrLessEquals(_margin, epsilon: 0.5),
        reason: '$what: from the top',
      );
      await t.drag(page(), const Offset(0, -5000));
      await t.pumpAndSettle();
      expect(
        view.bottom - group(t).bottom,
        moreOrLessEquals(_margin, epsilon: 0.5),
        reason: '$what: its end reached',
      );
    }
    expect(t.takeException(), isNull, reason: what);
    return fits;
  }

  // Every plain mission of every case: its place and its puzzle, on the
  // smallest phone with large text and on the largest.
  for (final (size, scale) in const [
    (Size(360, 640), 1.3),
    (Size(430, 932), 1.0),
  ]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}@$scale';
    for (final m in plain) {
      for (final puzzle in [false, true]) {
        final step = puzzle ? 'puzzle (${m.type.name})' : 'place';
        testWidgets(
          '${m.id} $step $tag: centred when it fits, scrolled when not',
          (t) async {
            await open(t, m.id, puzzle: puzzle, size: size, textScale: scale);
            await expectCentredOrScrolled(t, '${m.id} $step $tag');
          },
        );
      }
    }
  }

  // The examples on the three phones, both text sizes, with pictures for
  // review (LM_SCREENSHOTS=<folder>).
  for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
    for (final scale in const [1.0, 1.3]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}@$scale';
      for (final (id, puzzle) in const [
        ('m02', false),
        ('m02', true),
        ('m03', true),
        ('m01', true),
        ('m04', true),
        ('ep03_m3', true),
      ]) {
        testWidgets('$id ${puzzle ? 'puzzle' : 'place'} $tag', (t) async {
          await open(t, id, puzzle: puzzle, size: size, textScale: scale);
          // A scrolled page is pictured from its top, as it opens.
          if (!await expectCentredOrScrolled(t, id)) {
            await t.drag(page(), const Offset(0, 5000));
            await t.pumpAndSettle();
          }
          await capture(t, 'after_${id}_${puzzle ? 'puzzle' : 'place'}_$tag');
        });
      }
    }
  }

  for (final (id, puzzle) in const [
    ('m02', false),
    ('m02', true),
    ('m03', true),
  ]) {
    testWidgets(
      '$id ${puzzle ? 'puzzle' : 'place'}: in the true middle on a large phone',
      (t) async {
        await open(t, id, puzzle: puzzle, size: const Size(430, 932));
        expect(
          await expectCentredOrScrolled(t, id),
          isTrue,
          reason: '$id fits on a large phone',
        );
      },
    );
  }

  testWidgets(
    'the place: the player detective beside INVESTIGATE, whole and on the page',
    (t) async {
      await open(
        t,
        'm02',
        puzzle: false,
        size: const Size(360, 640),
        textScale: 1.3,
      );
      final button = find.ancestor(
        of: find.text('INVESTIGATE'),
        matching: find.byType(GameButton),
      );
      await t.drag(page(), const Offset(0, -5000));
      await t.pumpAndSettle();
      final view = t.getRect(page());
      final detective = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == 'PlayerDetective',
      );
      expect(detective, findsOneWidget);
      final d = t.getRect(detective), b = t.getRect(button);
      expect(
        view.contains(d.topLeft) && view.contains(d.bottomRight),
        isTrue,
        reason: 'not cut',
      );
      expect(view.contains(b.topLeft) && view.contains(b.bottomRight), isTrue);
      expect(
        d.right,
        lessThanOrEqualTo(b.left),
        reason: 'beside the button, not over it',
      );
      await t.tap(button);
      await wait(t, const Duration(milliseconds: 800));
      expect(
        find.text('TAP TO OPEN'),
        findsOneWidget,
        reason: 'on to the letter',
      );
    },
  );

  testWidgets(
    'the word puzzle with the keyboard: the field and CHECK ANSWER in view, the word kept, centred again after',
    (t) async {
      await open(t, 'm02', puzzle: true, size: const Size(390, 844));
      expect(await expectCentredOrScrolled(t, 'keyboard down'), isTrue);
      final field = find.byType(TextField);
      await t.tap(field);
      await t.enterText(field, 'STO');
      // The keyboard comes up: the page is shorter than the group.
      t.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final view = t.getRect(page());
      final check = find.ancestor(
        of: find.text('CHECK ANSWER'),
        matching: find.byType(GameButton),
      );
      bool inView(Finder f) {
        final r = t.getRect(f);
        return r.top >= view.top - 0.5 && r.bottom <= view.bottom + 0.5;
      }

      expect(
        inView(field),
        isTrue,
        reason: 'the field is not under the keyboard',
      );
      expect(
        inView(check),
        isTrue,
        reason: 'CHECK ANSWER in reach with the keyboard up',
      );
      expect(t.widget<TextField>(field).controller!.text, 'STO');
      expect(t.testTextInput.hasAnyClients, isTrue, reason: 'still focused');
      await t.enterText(field, 'STOVE');
      // The keyboard goes: back in the middle, the word still there.
      t.view.resetViewInsets();
      await t.pumpAndSettle();
      expect(await expectCentredOrScrolled(t, 'keyboard gone'), isTrue);
      expect(t.widget<TextField>(field).controller!.text, 'STOVE');
      // A wrong word: the try-again sheet, as before.
      await t.tap(check);
      await wait(t, const Duration(milliseconds: 900));
      expect(find.text('Not quite!'), findsOneWidget);
    },
  );

  testWidgets(
    'the keypad on a small phone with large text: keys, Delete, Clear and UNLOCK work',
    (t) async {
      final m = await open(
        t,
        'm03',
        puzzle: true,
        size: const Size(360, 640),
        textScale: 1.3,
      );
      Future<void> press(String label) async {
        final f = find.text(label).last;
        await t.ensureVisible(f);
        await t.pumpAndSettle();
        await t.tap(f);
        await t.pump(const Duration(milliseconds: 200));
      }

      final unlock = find.ancestor(
        of: find.text('UNLOCK'),
        matching: find.byType(GameButton),
      );
      final length = m.codeLength ?? m.answer.length;
      for (var i = 0; i < length; i++) {
        await press('1');
      }
      expect(
        t.widget<GameButton>(unlock).onPressed,
        isNotNull,
        reason: 'full: UNLOCK is on',
      );
      await press('Delete');
      expect(
        t.widget<GameButton>(unlock).onPressed,
        isNull,
        reason: 'one gone',
      );
      await press('Clear');
      // A wrong code: the try-again sheet.
      for (var i = 0; i < length; i++) {
        await press(m.answer[i] == '9' ? '8' : '9');
      }
      await t.ensureVisible(unlock);
      await t.pumpAndSettle();
      await t.tap(unlock);
      await wait(t, const Duration(milliseconds: 900));
      expect(find.text('Not quite!'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Reread Letter and the free hint, scrolled to on a small phone', (
    t,
  ) async {
    final m = await open(
      t,
      'm02',
      puzzle: true,
      size: const Size(360, 640),
      textScale: 1.3,
    );
    final reread = find.text('Reread Letter');
    await t.ensureVisible(reread);
    await t.pumpAndSettle();
    // The two links, side by side or one under the other, never over each other.
    final hint = find.text('Get a Free Hint');
    final a = t.getRect(reread), b = t.getRect(hint);
    expect(a.overlaps(b), isFalse);
    await t.tap(reread);
    await wait(t, const Duration(milliseconds: 700));
    expect(find.byType(LetterCard), findsOneWidget);
    await t.ensureVisible(find.text('BACK TO THE PUZZLE'));
    await t.pumpAndSettle();
    await t.tap(find.text('BACK TO THE PUZZLE'));
    await wait(t, const Duration(milliseconds: 700));
    await t.ensureVisible(hint);
    await t.pumpAndSettle();
    await t.tap(hint);
    await wait(t, const Duration(milliseconds: 900));
    expect(
      findReadable(m.hints[0]),
      findsOneWidget,
      reason: 'the free hint on the page',
    );
    expect(t.takeException(), isNull);
  });
}

/// The page margin above and below a mission page's group.
const _margin = 24.0;
