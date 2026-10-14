import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/mock/season1/season1_learning.dart';
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';

/// The learning design of Season 1 (TYPE B P0-C) is tied to the real
/// content: every mission has one, it only names English the child sees, and
/// it never records a picture or symbol match as understanding English.
void main() {
  final season = MockEpisodeRepository.bundled();
  final missions = {for (final e in season) for (final m in e.allMissions) m.id: m};

  String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Everything the mission puts on screen before and during its puzzle.
  String screenText(Mission m) => norm([
        ...m.story,
        m.letterIntro,
        m.letter,
        m.question,
        m.prompt ?? '',
        for (final o in m.options) o.label,
        ...m.hints,
      ].join(' \n '));

  /// What the detective keeps from a solved mission: its screens, its clue
  /// and its evidence (read again from the notebook or the Case Archive).
  String keptText(Mission m) => norm([
        screenText(m),
        m.clue?.title ?? '',
        m.clue?.note ?? '',
        m.evidence?.name ?? '',
        m.evidence?.description ?? '',
        m.evidence?.inscription ?? '',
      ].join(' \n '));

  test('Season 1 has 50 puzzles, and every one has a learning design', () {
    expect(missions, hasLength(50));
    expect(season1Learning.keys.toSet(), missions.keys.toSet(), reason: 'no mission without a design, no stray ids');
  });

  test('every case has a language topic', () {
    expect(season1LanguageTopics.keys.toSet(), {for (final e in season) e.id});
    for (final t in season1LanguageTopics.values) {
      expect(t.title.trim(), isNotEmpty);
      expect(t.titleKo.trim(), isNotEmpty);
    }
  });

  test('every expression is really in the case: on the mission, or in what it recalls', () {
    season1Learning.forEach((id, l) {
      final own = screenText(missions[id]!);
      final recalled = l.recallFrom == null ? '' : keptText(missions[l.recallFrom]!);
      for (final e in l.expressions) {
        expect(own.contains(norm(e)) || recalled.contains(norm(e)), isTrue, reason: '$id: "$e" is not in the content');
      }
    });
  });

  test('recall points to an earlier mission, and its level needs one', () {
    final order = missions.keys.toList();
    season1Learning.forEach((id, l) {
      final from = l.recallFrom;
      if (from != null) {
        expect(missions.containsKey(from), isTrue, reason: '$id recalls an unknown mission');
        expect(order.indexOf(from), lessThan(order.indexOf(id)), reason: '$id recalls a later mission');
      }
      if (l.level == LearningLevel.recall) expect(from, isNotNull, reason: '$id: recall without a source');
    });
  });

  test('only missions that need the English claim more than exposure', () {
    season1Learning.forEach((id, l) {
      expect(l.isHonest, isTrue, reason: '$id: ${l.level.name} needs an essential dependency');
      if (l.dependency == LanguageDependency.low) expect(l.skill, isNull, reason: '$id: no language skill when English barely matters');
      if (l.dependency == LanguageDependency.essential) {
        expect(l.expressions, isNotEmpty, reason: '$id: an essential mission names its deciding English');
      }
      expect(l.objective.trim(), isNotEmpty);
    });
  });

  test('picture and symbol matches are never recorded as understanding English', () {
    // Case 01 keeps its picture locks (the tutorial); Case 05 and 12 dropped them.
    for (final id in ['final']) {
      expect(season1Learning[id]!.dependency, LanguageDependency.low, reason: '$id: the locks match the clue symbols');
      expect(season1Learning[id]!.level, LearningLevel.exposure);
    }
    // Picture choices whose landmark name is under the picture and matches the letter.
    // Case 10 M3 keeps its names: making the name from two words is the puzzle.
    for (final id in ['ep10_m3']) {
      expect(season1Learning[id]!.level, LearningLevel.exposure, reason: '$id: the name tag gives it away');
    }
  });

  test('a lock without pictures, a picture without a name: only then more than exposure', () {
    for (final m in missions.values) {
      final l = season1Learning[m.id]!;
      if (m.dialSymbols.isNotEmpty) expect(l.level, LearningLevel.exposure, reason: '${m.id}: picture locks');
    }
    for (final id in ['m04', 'ep04_m3', 'ep11_m3']) {
      expect(missions[id]!.hideOptionNames, isTrue, reason: '$id is essential only because its pictures are unnamed');
    }
  });

  // After the representative-case pass (Case 01, 05, 12), Phase 2 (02-04), 3A (06-08) and 3B (09-11),
  // and Wave 1 (03-M1 played as a search: helpful → essential).
  test('the distribution matches the TYPE B design document', () {
    int count(LanguageDependency d) => season1Learning.values.where((l) => l.dependency == d).length;
    expect(count(LanguageDependency.essential), 42);
    expect(count(LanguageDependency.helpful), 5);
    expect(count(LanguageDependency.low), 3);
    expect(count(LanguageDependency.exposure), 0);
  });
}
