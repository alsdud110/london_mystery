import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/models/mission.dart';

import '../full_playthrough_test.dart' show reveal, tapText, wait;
import '../helpers.dart';

/// A generated sandbox case played in the real app as a child plays it
/// (STEP 3-9): from the map to each puzzle, its answer put in with the
/// puzzle's own controls (an option tapped, tiles in order, a word typed,
/// letter tiles, the final's dials turned), and on to the map again. The
/// answers are the mission's own data: nothing is solved behind the screen.
class SandboxPlay {
  SandboxPlay(this.t);

  final WidgetTester t;

  /// The final's dials as last turned (they start at 0 on its page).
  final _dials = <int>[];

  /// Every text on screen (for a failing step's reason).
  String texts() => [
    for (final e in find.byType(Text).evaluate()) (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText() ?? '',
  ].where((s) => s.trim().isNotEmpty).join(' | ');

  /// From the map to [m]'s place: GO TO it, its story, INVESTIGATE waiting.
  Future<void> toPlace(Mission m) async {
    await t.tap(find.bySemanticsLabel('GO TO ${m.location}'));
    await wait(t, const Duration(milliseconds: 2800));
    expect(find.text('INVESTIGATE'), findsOneWidget, reason: '${m.id}: ${texts()}');
  }

  /// From the map to [m]'s puzzle: GO TO the place, INVESTIGATE, the letter, SOLVE.
  Future<void> toPuzzle(Mission m) async {
    await toPlace(m);
    await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
    await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
    expect(findReadableContaining(m.letter.split('\n').first), findsWidgets, reason: '${m.id} letter: ${texts()}');
    await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
    expect(findReadable(m.question), findsOneWidget, reason: '${m.id}: ${texts()}');
  }

  /// The answer's Discovery Moment, the story after it, back to the map.
  Future<void> onToMap(Mission m) async {
    await wait(t, const Duration(milliseconds: 2800));
    await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 900));
    expect(findReadableContaining(m.transition.first), findsWidgets, reason: '${m.id} scene: ${texts()}');
    await t.tapAt(const Offset(200, 400)); // skip typing
    await wait(t, const Duration(milliseconds: 900));
    await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1200));
    await wait(t, const Duration(milliseconds: 3200)); // LOCKED → UNLOCKED
  }

  /// From the map to the final's page.
  Future<void> toFinal(Mission fin) async {
    await tapText(t, 'OPEN THE FINAL CASE', after: Duration.zero);
    await wait(t, const Duration(milliseconds: 2800));
    expect(findReadable(fin.question), findsWidgets, reason: texts());
    _dials
      ..clear()
      ..addAll(List.filled(fin.codeLength ?? fin.answer.length, 0));
  }

  /// [answer] put into [m]'s puzzle with its own controls, then checked.
  /// A choice's [answer] is an option id; a sequence's, ids joined by commas.
  Future<void> answer(Mission m, String answer) async {
    switch (m.type) {
      case MissionType.multipleChoice:
        await tapText(t, m.options.firstWhere((o) => o.id == answer).label, after: const Duration(milliseconds: 200));
        await tapText(t, 'CHECK ANSWER', after: Duration.zero);
      case MissionType.imageChoice:
        // Each picture as screen readers hear it: by its name, or by what it
        // shows when the names are hidden.
        final i = m.options.indexWhere((o) => o.id == answer);
        final o = m.options[i];
        final letter = String.fromCharCode(65 + i);
        final picture = find.bySemanticsLabel(
          m.hideOptionNames ? 'Picture $letter${o.altText == null ? '' : ': ${o.altText}'}' : 'Picture $letter, ${o.label}',
        );
        await reveal(t, picture);
        await t.tap(picture);
        await t.pump(const Duration(milliseconds: 200));
        await tapText(t, 'CHECK ANSWER', after: Duration.zero);
      case MissionType.sequence:
        for (final id in Mission.sequenceIds(answer)) {
          final step = find.text(m.options.firstWhere((o) => o.id == id).label).last;
          await reveal(t, step); // a long step can be below the fold
          await t.tap(step);
          await t.pump(const Duration(milliseconds: 150));
        }
        await tapText(t, 'CHECK ANSWER', after: Duration.zero);
      case MissionType.wordInput:
        await t.enterText(find.byType(TextField), answer);
        await t.pump();
        await tapText(t, 'CHECK ANSWER', after: Duration.zero);
      case MissionType.letterLock:
        for (final letter in answer.split('')) {
          final tile = find.bySemanticsLabel('Letter $letter').first;
          await reveal(t, tile);
          await t.tap(tile);
          await t.pump(const Duration(milliseconds: 150));
        }
        await tapText(t, 'OPEN THE LOCK', after: Duration.zero);
      case MissionType.finalCode:
        for (final (i, d) in answer.split('').map(int.parse).indexed) {
          final up = find.byTooltip('Lock ${i + 1} up');
          await reveal(t, up);
          for (; _dials[i] != d; _dials[i] = (_dials[i] + 1) % 10) {
            await t.tap(up);
            await t.pump(const Duration(milliseconds: 60));
          }
          await t.pump(const Duration(milliseconds: 300)); // the number rolled in
          expect(find.bySemanticsLabel(RegExp('Lock ${i + 1}, [^:]*: $d\$')), findsOneWidget, reason: 'dial ${i + 1}: ${texts()}');
        }
        await tapText(t, 'UNLOCK', after: Duration.zero);
      default:
        fail('${m.type} is not a puzzle the generator makes');
    }
    await wait(t, const Duration(milliseconds: 400));
  }

  /// A wrong answer: its line ([line], when the plan wrote one) on the
  /// try-again sheet, then TRY AGAIN.
  Future<void> wrong(Mission m, String answer, {String? line}) async {
    await this.answer(m, answer);
    expect(find.text('Not quite!'), findsOneWidget, reason: '${m.id} "$answer": ${texts()}');
    if (line != null) expect(findReadableContaining(line), findsWidgets, reason: '${m.id} "$answer": ${texts()}');
    await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
    // The steps laid stay on their lines: cleared to lay them again.
    if (m.type == MissionType.sequence) await tapText(t, 'Start again', after: const Duration(milliseconds: 300));
  }
}
