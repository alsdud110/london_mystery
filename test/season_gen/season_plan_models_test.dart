import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/season_gen/plan_check.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';
import 'plan_samples.dart';

/// The season content pipeline's plan models (STEP 3-2): read, written,
/// and checked for their structure.
void main() {
  Matcher rejects(String path, [String? why]) => throwsA(
    isA<PlanFormatException>()
        .having((e) => e.path, 'path', path)
        .having((e) => e.message, 'message', why == null ? anything : contains(why)),
  );

  List<String> issues(List<PlanIssue> found) => [for (final i in found) i.path];

  group('reads', () {
    test('a season plan', () {
      final plan = SeasonPlan.fromJson(sampleSeasonJson());
      expect(plan.seasonId, 's3_sample');
      expect(plan.caseIds, hasLength(12));
      expect(plan.characters.first.secretUntil, 's3_ep11');
      expect(plan.characters.last.secretUntil, isNull, reason: 'secretUntil is optional');
      expect(plan.prologue?.firstCase?.line, 'It starts at the station.');
      expect(PlanCheck.season(plan), isEmpty);
    });

    test('a case plan: its missions in order, then its final', () {
      final plan = CasePlan.fromJson(sampleCaseJson());
      expect([for (final m in plan.allMissions) m.slot], ['m1', 'm2', 'm3', 'final']);
      expect(plan.finalMission.isFinal, isTrue);
      expect(PlanCheck.casePlan(plan, season: SeasonPlan.fromJson(sampleSeasonJson())), isEmpty);
    });

    test('a mission plan: its clues in and out, its learning', () {
      final m = MissionPlan.fromJson(sampleMissionJson(2), r'$');
      expect(m.clueInputs.single.use, ClueUse.recall);
      expect(m.clueOutputs.clue, 's3_ep01_c2');
      expect(m.clueOutputs.facts, ['s3_ep01_f2']);
      expect(m.learning.recallFrom, 's3_ep01_m1');
    });

    test('a puzzle plan: nullable engine table, its answer', () {
      final p = PuzzlePlan.fromJson(sampleMissionJson(1)['puzzle'], r'$');
      expect(p.paletteId, 'text_choice');
      expect(p.engineTable, isNull);
      expect(p.status, PuzzleStatus.ready);
      expect(p.answerSpec.options.map((o) => o.id), ['a', 'b', 'c']);
      final last = PuzzlePlan.fromJson(sampleFinalJson()['puzzle'], r'$');
      expect((last.surface, last.answerSpec.codeLength), (PlanSurface.finalMission, 4));
    });
  });

  group('writes', () {
    test('JSON → plan → JSON loses nothing', () {
      expect(SeasonPlan.fromJson(sampleSeasonJson()).toJson(), sampleSeasonJson());
      expect(CasePlan.fromJson(sampleCaseJson()).toJson(), sampleCaseJson());
    });

    test('the same plan writes the same bytes, and reads back the same', () {
      final dir = Directory.systemTemp.createTempSync('season_gen');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/cases/s3_ep01/case.plan.json';
      final plan = CasePlan.fromJson(sampleCaseJson());
      PlanFiles.saveCasePlan(plan, path);
      final first = File(path).readAsStringSync();
      PlanFiles.saveCasePlan(PlanFiles.loadCasePlan(path), path);
      expect(File(path).readAsStringSync(), first);
      expect(first, endsWith('}\n'));
      expect(File('$path.part').existsSync(), isFalse);
    });

    test('a file that is not JSON is a format error', () {
      final dir = Directory.systemTemp.createTempSync('season_gen');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/season.plan.json';
      File(path).writeAsStringSync('{"schemaVersion": 1,');
      expect(() => PlanFiles.loadSeasonPlan(path), rejects(path, 'not JSON'));
    });
  });

  group('rejects', () {
    test('a missing field, where it is', () {
      expect(() => SeasonPlan.fromJson(sampleSeasonJson()..remove('acts')), rejects(r'$.acts', 'missing'));
      final c = sampleCaseJson();
      ((c['final'] as Map)['puzzle'] as Map).remove('status');
      expect(() => CasePlan.fromJson(c), rejects(r'$.final.puzzle.status', 'missing'));
      // A field that is required with a null value (paletteId) must still be there.
      final p = sampleMissionJson(1)['puzzle'] as Map<String, Object?>..remove('paletteId');
      expect(() => PuzzlePlan.fromJson(p, r'$'), rejects(r'$.paletteId', 'missing'));
    });

    test('an id not of its form', () {
      expect(() => SeasonPlan.fromJson(sampleSeasonJson()..['seasonId'] = 'tokyo'), rejects(r'$.seasonId'));
      expect(() => CasePlan.fromJson(sampleCaseJson()..['caseId'] = 's3_ep1'), rejects(r'$.caseId'));
      final m = sampleMissionJson(1)..['missionId'] = 's3_ep01_mission1';
      expect(() => MissionPlan.fromJson(m, r'$'), rejects(r'$.missionId'));
      final place = sampleMissionJson(1)..['placeId'] = 'station';
      expect(() => MissionPlan.fromJson(place, r'$'), rejects(r'$.placeId'));
    });

    test('a wrong enum value', () {
      for (final (key, value) in [('surface', 'final'), ('status', 'done'), ('missionType', 'quiz')]) {
        final p = sampleMissionJson(1)['puzzle'] as Map<String, Object?>..[key] = value;
        expect(() => PuzzlePlan.fromJson(p, r'$'), rejects('\$.$key', 'is not one of'), reason: key);
      }
      final m = sampleMissionJson(2);
      ((m['clueInputs'] as List).single as Map)['use'] = 'remember';
      expect(() => MissionPlan.fromJson(m, r'$'), rejects(r'$.clueInputs[0].use'));
      final l = sampleMissionJson(1);
      (l['learning'] as Map)['level'] = 'mastery';
      expect(() => MissionPlan.fromJson(l, r'$'), rejects(r'$.learning.level'));
    });

    test('another schemaVersion', () {
      expect(() => SeasonPlan.fromJson(sampleSeasonJson()..['schemaVersion'] = 2), rejects(r'$.schemaVersion', 'not supported'));
      expect(() => CasePlan.fromJson(sampleCaseJson()..remove('schemaVersion')), rejects(r'$.schemaVersion', 'missing'));
    });

    test('an unknown field, at any depth', () {
      expect(() => SeasonPlan.fromJson(sampleSeasonJson()..['villain'] = 'x'), rejects(r'$.villain', 'not a field'));
      final c = sampleCaseJson();
      ((c['missions'] as List).first as Map)['answer'] = 'b';
      expect(() => CasePlan.fromJson(c), rejects(r'$.missions[0].answer', 'not a field'));
    });

    test('acts not three of four cases', () {
      final two = sampleSeasonJson();
      (two['acts'] as List).removeLast();
      expect(() => SeasonPlan.fromJson(two), rejects(r'$.acts', 'at least 3'));
      final short = sampleSeasonJson();
      (((short['acts'] as List).first as Map)['caseIds'] as List).removeLast();
      expect(() => SeasonPlan.fromJson(short), rejects(r'$.acts[0].caseIds', 'at least 4'));
    });

    test('a case id twice in one act', () {
      final s = sampleSeasonJson();
      (((s['acts'] as List).first as Map)['caseIds'] as List)[1] = 's3_ep01';
      expect(() => SeasonPlan.fromJson(s), rejects(r'$.acts[0].caseIds', 'twice'));
    });

    test('more missions than a case has', () {
      final c = sampleCaseJson()..['missions'] = [for (var n = 1; n <= 6; n++) sampleMissionJson(n)];
      expect(() => CasePlan.fromJson(c), rejects(r'$.missions', 'at most 5'));
    });
  });

  group('structure', () {
    test('a case in two acts, or out of order', () {
      final s = sampleSeasonJson();
      (((s['acts'] as List)[1] as Map)['caseIds'] as List)[0] = 's3_ep01';
      expect(issues(PlanCheck.season(SeasonPlan.fromJson(s))), [r'$.acts[1].caseIds[0]']);
      final swapped = sampleSeasonJson();
      final ids = ((swapped['acts'] as List).first as Map)['caseIds'] as List;
      ids.insert(0, ids.removeAt(1));
      expect(issues(PlanCheck.season(SeasonPlan.fromJson(swapped))), [r'$.acts[0].caseIds[0]', r'$.acts[0].caseIds[1]']);
    });

    test('acts out of order, and a number its id does not say', () {
      final s = sampleSeasonJson()..['number'] = 4;
      final acts = s['acts'] as List;
      (acts[0] as Map)['actId'] = 'act2';
      expect(issues(PlanCheck.season(SeasonPlan.fromJson(s))), containsAll([r'$.number', r'$.acts[0].actId']));
    });

    test('people and reveals of cases the season has', () {
      final s = sampleSeasonJson();
      ((s['characters'] as List).first as Map)['secretUntil'] = 's3_ep00';
      ((s['characters'] as List).last as Map)['revealCase'] = 's3_ep01';
      expect(issues(PlanCheck.season(SeasonPlan.fromJson(s))), [r'$.characters[0].secretUntil', r'$.characters[1].revealCase']);
    });

    test('a case id, number, act and season that agree', () {
      final c = sampleCaseJson()
        ..['caseId'] = 's4_ep02'
        ..['actId'] = 'act2';
      final found = issues(PlanCheck.casePlan(CasePlan.fromJson(c)));
      expect(found.where((p) => !p.startsWith(r'$.missions') && !p.startsWith(r'$.final')), [r'$.caseId', r'$.number', r'$.actId']);
      // Its missions are still named after s3_ep01: each is reported.
      expect(found, contains(r'$.missions[0].missionId'));
    });

    test('missions out of order, and ids not their slot\'s', () {
      final c = sampleCaseJson();
      final missions = c['missions'] as List;
      missions.insert(0, missions.removeAt(1));
      expect(issues(PlanCheck.casePlan(CasePlan.fromJson(c))), [r'$.missions[0].slot', r'$.missions[1].slot']);
      final renamed = sampleCaseJson();
      ((renamed['missions'] as List).first as Map)['missionId'] = 's3_ep01_m2';
      expect(issues(PlanCheck.casePlan(CasePlan.fromJson(renamed))), [r'$.missions[0].missionId', r'$.missions[1].missionId']);
    });

    test('one final, last: a final slot among the missions is not the final', () {
      final c = sampleCaseJson();
      (c['missions'] as List).add({...sampleFinalJson(), 'puzzle': (sampleMissionJson(1)['puzzle'] as Map)});
      expect(issues(PlanCheck.casePlan(CasePlan.fromJson(c))), contains(r'$.missions[3].slot'));
      final noFinal = sampleCaseJson();
      (noFinal['final'] as Map)['slot'] = 'm4';
      expect(issues(PlanCheck.casePlan(CasePlan.fromJson(noFinal))), contains(r'$.final.slot'));
    });

    test("a mission's own parts: its case's ids, its slot's page, its season's places", () {
      final c = sampleCaseJson();
      final m = (c['missions'] as List).first as Map;
      (m['clueOutputs'] as Map).remove('clue');
      (m['clueOutputs'] as Map)['evidence'] = 's3_ep02_e1';
      m['placeId'] = 's2_paris.station';
      (m['puzzle'] as Map)
        ..['surface'] = 'finalMission'
        ..['paletteId'] = null;
      expect(issues(PlanCheck.casePlan(CasePlan.fromJson(c))), [
        r'$.missions[0].placeId',
        r'$.missions[0].clueOutputs.clue',
        r'$.missions[0].clueOutputs.evidence',
        r'$.missions[0].puzzle.surface',
        r'$.missions[0].puzzle.paletteId',
      ]);
    });

    test('a development request says what to develop', () {
      final c = sampleCaseJson();
      ((c['missions'] as List).first as Map)['puzzle'] = {
        ...(sampleMissionJson(1)['puzzle'] as Map<String, Object?>),
        'paletteId': null,
        'status': 'devRequest',
      };
      expect(issues(PlanCheck.casePlan(CasePlan.fromJson(c))), [r'$.missions[0].puzzle.devNote']);
    });

    test('with its season: its act, people and places', () {
      final c = sampleCaseJson()
        ..['characters'] = ['detective']
        ..['locations'] = ['harbour'];
      final s = sampleSeasonJson();
      ((s['acts'] as List)[0] as Map)['caseIds'] = ['s3_ep02', 's3_ep03', 's3_ep04', 's3_ep05'];
      expect(issues(PlanCheck.casePlan(CasePlan.fromJson(c), season: SeasonPlan.fromJson(s))), [
        r'$.caseId',
        r'$.characters[0]',
        r'$.locations[0]',
      ]);
    });

    test('clue inputs are only read: their graph is STEP 3-4\'s', () {
      final c = sampleCaseJson();
      ((c['final'] as Map)['clueInputs'] as List).add({'ref': 's3_ep09_c9', 'use': 'answerDerivation'});
      expect(PlanCheck.casePlan(CasePlan.fromJson(c)), isEmpty);
    });
  });
}
