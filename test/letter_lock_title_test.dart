import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/theme/app_theme.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/mission/widgets/letter_lock.dart';

/// The letter lock's plate names its own story's lock (`Mission.lockTitle`),
/// never another season's: Paris Case 01's keeps THE CLOCKMAKER'S LOCK, a
/// lock that names none is plain THE LOCK.
void main() {
  final paris = MockEpisodeRepository.bundled().firstWhere((e) => e.id == 's2_ep01').finalMission;

  /// Paris's lock, of another case: named [title], or nothing.
  Mission lock({String? title}) {
    final json = {...paris.toJson(), 'id': 's9_test_final'}..remove('lockTitle');
    return Mission.fromJson({...json, 'lockTitle': ?title});
  }

  Future<void> show(WidgetTester t, Mission m) => t.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: SingleChildScrollView(child: LetterLockQuestion(mission: m, onSubmit: (_) {}))),
  ));

  test("every letter lock of the game's seasons", () {
    final locks = [for (final e in MockEpisodeRepository.bundled()) for (final m in e.allMissions) if (m.type == MissionType.letterLock) m.id];
    expect(locks, ['s2_ep01_final'], reason: 'a new one names its lock (or is plain)');
    expect(paris.lockTitle, "THE CLOCKMAKER'S LOCK");
  });

  testWidgets("Paris Case 01's lock: THE CLOCKMAKER'S LOCK, as before", (t) async {
    await show(t, paris);
    expect(find.text("THE CLOCKMAKER'S LOCK"), findsOneWidget);
  });

  testWidgets('a lock with its own name shows it', (t) async {
    await show(t, lock(title: 'THE LIBRARY LOCK'));
    expect(find.text('THE LIBRARY LOCK'), findsOneWidget);
    expect(find.textContaining('CLOCKMAKER'), findsNothing);
  });

  testWidgets('a lock that names none is plain: never the Clockmaker', (t) async {
    final m = lock();
    expect(m.lockTitle, isNull);
    await show(t, m);
    expect(find.text(LetterLockQuestion.plainTitle), findsOneWidget);
    expect(find.textContaining('CLOCKMAKER'), findsNothing);
  });

  test('read back, a mission keeps its lock name; one with none writes none', () {
    expect(Mission.fromJson(paris.toJson()).lockTitle, paris.lockTitle);
    expect(lock().toJson().containsKey('lockTitle'), isFalse);
    expect(LetterLockReveal.spoken("THE CLOCKMAKER'S LOCK"), "The clockmaker's lock");
  });
}
