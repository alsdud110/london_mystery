import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/season_gen/change_impact.dart';
import '../../tool/season_gen/content_approval.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';
import 'plan_samples.dart';

/// What a change of an approved plan or picture touches (STEP 3-5): only
/// what the plans name, and nothing changed.
void main() {
  String idOf(int n) => 's3_ep${n.toString().padLeft(2, '0')}';

  /// The sample case as Case [n]; [extra] clue inputs added to its slots.
  Map<String, Object?> caseJson(int n, [Map<String, List<String>> extra = const {}]) {
    final json = jsonDecode(jsonEncode(sampleCaseJson()).replaceAll('s3_ep01', idOf(n))) as Map<String, Object?>;
    json['number'] = n;
    json['actId'] = 'act${(n - 1) ~/ 4 + 1}';
    for (final m in [...json['missions']! as List, json['final']]) {
      final mission = m as Map<String, Object?>;
      (mission['clueInputs']! as List).addAll([
        for (final ref in extra[mission['slot']] ?? const <String>[]) {'ref': ref, 'use': 'answerDerivation'},
      ]);
    }
    return json;
  }

  CasePlan plan(Map<String, Object?> json) => CasePlan.fromJson(json);

  List<String> lines(List<ImpactItem> items) => [for (final i in items) '${i.code} ${i.subject}${i.review == null ? '' : ' → ${i.review}'}${i.at == null ? '' : ' ${i.at}'}'];

  group('a season plan changed', () {
    final before = SeasonPlan.fromJson(sampleSeasonJson());
    final cases = [plan(caseJson(1)), plan(caseJson(4, {'m1': ['s3_ep02_e4']}))];

    test('unchanged: nothing', () {
      expect(ChangeImpact.season(before, SeasonPlan.fromJson(sampleSeasonJson()), cases: cases), isEmpty);
    });

    test('its cases moved: those cases, and the cases given their clues', () {
      final json = sampleSeasonJson();
      final acts = json['acts']! as List;
      (acts[0] as Map<String, Object?>)['caseIds'] = ['s3_ep01', 's3_ep03', 's3_ep02', 's3_ep04'];
      expect(lines(ChangeImpact.season(before, SeasonPlan.fromJson(json), cases: cases)), [
        'case_moved case s3_ep03 → casePlan s3_ep03',
        'case_moved case s3_ep02 → casePlan s3_ep02',
        r'clues_of_moved_case clue s3_ep02_e4 → casePlan s3_ep04 $.missions[0].clueInputs[0]',
      ]);
    });

    test('a case taken out and another added', () {
      final json = sampleSeasonJson();
      final act3 = (json['acts']! as List)[2] as Map<String, Object?>;
      act3['caseIds'] = ['s3_ep09', 's3_ep10', 's3_ep11', 's3_ep13'];
      expect(lines(ChangeImpact.season(before, SeasonPlan.fromJson(json), cases: cases)), [
        'case_removed case s3_ep12 → casePlan s3_ep12',
        'case_added case s3_ep13 → casePlan s3_ep13',
      ]);
    });

    test('a character changed or removed: the case plans that list them, and the cases they are named at', () {
      final json = sampleSeasonJson();
      final chars = json['characters']! as List;
      (chars[0] as Map<String, Object?>)['role'] = 'Hides the late train';
      chars.removeAt(1);
      json['title'] = 'Another Title';
      expect(lines(ChangeImpact.season(before, SeasonPlan.fromJson(json), cases: cases)), [
        'character_changed character guide → casePlan s3_ep01',
        'character_changed character guide → casePlan s3_ep04',
        'character_changed character guide → casePlan s3_ep11',
        'character_changed character guide → casePlan s3_ep12',
        'character_removed character porter → casePlan s3_ep02',
        'season_field_changed field title',
      ]);
    });

    test('a location changed, the main mystery revealed elsewhere', () {
      final json = sampleSeasonJson();
      ((json['locations']! as List)[0] as Map<String, Object?>)['name'] = 'Old Station';
      (json['mainMystery']! as Map<String, Object?>)['revealCase'] = 's3_ep11';
      expect(lines(ChangeImpact.season(before, SeasonPlan.fromJson(json), cases: cases)), [
        'location_changed location station → casePlan s3_ep01',
        'location_changed location station → casePlan s3_ep04',
        'main_mystery_changed mainMystery → casePlan s3_ep11',
        'main_mystery_changed mainMystery → casePlan s3_ep12',
      ]);
    });
  });

  group('a case plan changed', () {
    final before = plan(caseJson(1));
    final next = plan(caseJson(2, {'m1': ['s3_ep01_c1', 's3_ep01_e4']}));

    test('unchanged: nothing', () {
      expect(ChangeImpact.casePlan(before, plan(caseJson(1)), others: [next]), isEmpty);
    });

    test("a clue's id changed: its mission, and every mission given it, of the case or another", () {
      final json = caseJson(1);
      final m1 = (json['missions']! as List)[0] as Map<String, Object?>;
      (m1['clueOutputs']! as Map<String, Object?>)['clue'] = 's3_ep01_c9';
      final items = ChangeImpact.casePlan(before, plan(json), others: [next, plan(caseJson(1))]);
      expect(lines(items), [
        'mission_changed mission s3_ep01_m1 → mission s3_ep01_m1',
        r'clue_removed clue s3_ep01_c1 → casePlan s3_ep01 $.missions[1].clueInputs[0]',
        r'clue_removed clue s3_ep01_c1 → casePlan s3_ep01 $.final.clueInputs[0]',
        r'clue_removed clue s3_ep01_c1 → casePlan s3_ep02 $.missions[0].clueInputs[0]',
      ], reason: "the case's own old plan among the others is not read twice");
      expect(items.first.message, 'clueOutputs changed; review its clue links (ClueGraphCheck)');
    });

    test('a clue left by another mission: the missions given it', () {
      final json = caseJson(1);
      final [m1, m2, ...] = json['missions']! as List;
      final (o1, o2) = ((m1 as Map)['clueOutputs'] as Map, (m2 as Map)['clueOutputs'] as Map);
      final e1 = o1['evidence'];
      o1['evidence'] = o2['evidence'];
      o2['evidence'] = e1;
      expect(lines(ChangeImpact.casePlan(before, plan(json), others: [next])), [
        'mission_changed mission s3_ep01_m1 → mission s3_ep01_m1',
        'mission_changed mission s3_ep01_m2 → mission s3_ep01_m2',
        'clue_moved clue s3_ep01_e1',
        r'clue_moved clue s3_ep01_e2 → casePlan s3_ep01 $.final.clueInputs[1]',
      ]);
    });

    test('a puzzle asking for a picture, a mission taken out, the words changed', () {
      final json = caseJson(1);
      final missions = json['missions']! as List;
      ((missions[0] as Map)['puzzle'] as Map)['assetNeeds'] = ['s3_sample.asset.clock_face'];
      missions.removeAt(2);
      json['hook'] = 'Another hook.';
      final items = ChangeImpact.casePlan(before, plan(json), assets: {'s3_sample.asset.clock_face': ApprovalStatus.approved});
      expect(lines(items), [
        'case_field_changed field hook',
        'mission_removed mission s3_ep01_m3',
        'mission_changed mission s3_ep01_m1 → mission s3_ep01_m1',
        'clue_removed clue s3_ep01_c3',
        'clue_removed clue s3_ep01_e3',
        r'clue_removed clue s3_ep01_f3 → casePlan s3_ep01 $.final.clueInputs[2]',
        'asset_needed asset s3_sample.asset.clock_face → asset s3_sample.asset.clock_face',
      ]);
      expect(items[2].message, 'puzzle changed; review its puzzle (PuzzleSelectionCheck)');
      expect(items.last.message, 'asked for now; its approval is approved');
      expect(items[3].message, 'no longer left (was by s3_ep01_m3); no mission is given it');
    });
  });

  test("a picture changed: Paris Case 10's missions that ask for it", () {
    final case10 = PlanFiles.loadCasePlan('test/fixtures/season_gen/s2_paris/cases/s2_ep10/case.plan.json');
    expect(lines(ChangeImpact.asset('s2_paris.asset.roof_photo', [case10])), [
      r'asset_changed asset s2_paris.asset.roof_photo → mission s2_ep10_m2 $.missions[1].puzzle.assetNeeds[0]',
      r'asset_changed asset s2_paris.asset.roof_photo → mission s2_ep10_m3 $.missions[2].puzzle.assetNeeds[0]',
    ]);
    expect(ChangeImpact.asset('s2_paris.asset.unused', [case10]), isEmpty);
  });
}
