import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/puzzle_palette.dart';
import 'package:world_mystery/data/mock/season2/season2_learning.dart';
import 'package:world_mystery/data/mock/season2/season2_mock.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';

import '../../tool/season_gen/plan_check.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';

/// Paris Season 2 and its Case 10 written as plans (test fixtures, never
/// read by the game): a real season and case can be told in the plans'
/// terms. Every value the plan takes from the game is checked against the
/// game's own content; the test supplements are named in the plans' notes.
void main() {
  const root = 'test/fixtures/season_gen/s2_paris';
  const seasonFile = '$root/season.plan.json';
  const caseFile = '$root/cases/s2_ep10/case.plan.json';
  final season = PlanFiles.loadSeasonPlan(seasonFile);
  final plan = PlanFiles.loadCasePlan(caseFile);
  final game = Episode.fromJson({...season2Json['s2_ep10']!, 'seasonId': SeasonIds.paris});

  test('both load, keep their structure, and are written in the canonical form', () {
    expect(PlanCheck.season(season), isEmpty);
    expect(PlanCheck.casePlan(plan, season: season), isEmpty);
    // As committed (LF): a Windows checkout (core.autocrlf) has CRLF on disk.
    String onDisk(String path) => File(path).readAsStringSync().replaceAll('\r\n', '\n');
    expect(PlanFiles.encode(season.toJson()), onDisk(seasonFile));
    expect(PlanFiles.encode(plan.toJson()), onDisk(caseFile));
  });

  test("the season plan is the game's Season 2", () {
    final s = Season.fromJson(season2InfoJson);
    expect((season.seasonId, season.number, season.city, season.title, season.tagline), (s.id, s.number, s.city, s.title, s.tagline));
    expect(season.plannedCases, s.plannedCases);
    expect(season.caseIds, season2Json.keys.toList());
    expect(season.outro, s.outro);
    expect(season.finale, s.finale);
    expect([for (final f in season.figures) (f.after, f.figure, f.label)], [for (final f in s.figures) (f.afterCase, f.figure, f.label)]);
    // A landmark's key is its enum value's own name (`ParisLandmark.name` is its label).
    String key(Object landmark) => landmark.toString().split('.').last;
    expect({for (final l in season.locations) l.landmarkKey: l.name}, {for (final l in ParisLandmark.values) key(l): l.name});
    // Case 10's location is the landmark the game puts it at.
    final at = season.locations.firstWhere((l) => l.locId == plan.locations.single);
    expect(at.landmarkKey, key(ParisLandmark.cases['s2_ep10']!));
  });

  test("Case 10's missions and final, in the game's order, ids and types", () {
    expect(plan.title, game.title);
    expect(plan.synopsis, game.synopsis);
    expect(plan.hook, game.hook);
    expect([for (final m in plan.allMissions) m.missionId], [for (final m in game.allMissions) m.id]);
    expect(plan.finalMission.missionId, game.finalMission.id);
    for (final (p, m) in [for (var i = 0; i < game.allMissions.length; i++) (plan.allMissions[i], game.allMissions[i])]) {
      expect(p.puzzle.missionType, m.type.name, reason: m.id);
      expect(p.puzzle.surface, m.isFinal ? PlanSurface.finalMission : PlanSurface.mission, reason: m.id);
      expect(p.clueOutputs.clue, m.clue?.id, reason: m.id);
      expect(p.clueOutputs.evidence, m.evidence?.id, reason: m.id);
    }
  });

  test("its answers are the game's, as written", () {
    for (final (p, m) in [for (var i = 0; i < game.allMissions.length; i++) (plan.allMissions[i], game.allMissions[i])]) {
      final a = p.puzzle.answerSpec;
      expect(a.answer, m.answer, reason: m.id);
      expect(a.acceptedAnswers, m.acceptedAnswers, reason: m.id);
      expect([for (final o in a.options) (o.id, o.label, o.feedback)], [for (final o in m.options) (o.id, o.label, o.feedback)], reason: m.id);
      expect([a.codeLength, a.codeFormat, a.dialSymbols], [m.codeLength, m.codeFormat, m.dialSymbols], reason: m.id);
    }
  });

  test("its engines are the game's tables, none of them in the palette", () {
    for (final m in plan.allMissions) {
      final table = m.puzzle.engineTable!;
      expect(season2Content.missionTables[table], contains(m.missionId), reason: '$table/${m.missionId}');
      expect(PuzzlePalette.all.any((p) => p.engines.any((e) => e.table == table)), isFalse, reason: table);
      expect((m.puzzle.paletteId, m.puzzle.status), (null, PuzzleStatus.devRequest), reason: m.missionId);
    }
  });

  test("its clue inputs are the game's evidence links", () {
    final links = season2Content.evidenceLinks;
    for (final m in plan.allMissions) {
      for (final c in m.clueInputs.where((c) => c.use == ClueUse.evidenceLink)) {
        expect(links[m.clueOutputs.evidence]?.to, c.ref, reason: m.missionId);
      }
    }
  });

  test("its learning is the game's", () {
    expect((plan.learningGoal.title, plan.learningGoal.titleKo), (season2LanguageTopics['s2_ep10']!.title, season2LanguageTopics['s2_ep10']!.titleKo));
    for (final m in plan.allMissions) {
      final l = season2Learning[m.missionId]!;
      expect(
        [m.learning.dependency, m.learning.level, m.learning.skill, m.learning.objective, m.learning.expressions, m.learning.recallFrom],
        [l.dependency.name, l.level.name, l.skill?.name, l.objective, l.expressions, l.recallFrom],
        reason: m.missionId,
      );
    }
  });
}
