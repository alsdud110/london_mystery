import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/mission/widgets/question_widgets.dart';

/// Case 12, Mission 3: the door is UNDER ___ ___ — one blank per word of
/// BIG BEN — and the typed words take both blanks' place, once.
void main() {
  final missions = [for (final e in MockEpisodeRepository.bundled()) ...e.allMissions];
  Mission mission(String id) => missions.firstWhere((m) => m.id == id);

  Future<List<String>> pump(WidgetTester t, Mission m) async {
    final submitted = <String>[];
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: WordInputQuestion(mission: m, onSubmit: submitted.add))),
    ));
    return submitted;
  }

  test('the prompt has two blanks, 3 + 3, and the answers still check', () {
    final m = mission('ep12_m3');
    expect(m.prompt, 'UNDER ___ ___');
    for (final typed in ['BIG BEN', 'big ben', 'BIGBEN', 'Clock Tower']) {
      expect(AnswerChecker.isCorrect(m, typed), isTrue, reason: typed);
    }
    expect(AnswerChecker.isCorrect(m, 'BIG'), isFalse);
  });

  testWidgets('empty: UNDER ___ ___; typing: the words in their place, once', (t) async {
    final submitted = await pump(t, mission('ep12_m3'));
    expect(find.text('UNDER ___ ___'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'big ben');
    await t.pump();
    expect(find.text('UNDER BIG BEN'), findsOneWidget, reason: 'not once per blank');
    await t.tap(find.text('CHECK ANSWER'));
    await t.pump();
    expect(submitted, ['big ben'], reason: 'what the child typed, checked as before');
  });

  testWidgets('a one-word prompt is as before (Case 01: ROSETTA _____)', (t) async {
    final m = missions.firstWhere((m) => m.prompt == 'ROSETTA _____');
    await pump(t, m);
    await t.enterText(find.byType(TextField), 'stone');
    await t.pump();
    expect(find.text('ROSETTA STONE'), findsOneWidget);
  });
}
