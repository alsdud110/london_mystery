import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/constants/app_constants.dart';

import '../../tool/season_gen/plan_check.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';
import '../../tool/season_gen/play_check.dart';

/// `PlayCheck` (STEP 3-8): what a plan lacks to be made into the game's
/// content, on the sandbox plans and on changed copies of them. A plan with
/// no words written still keeps its format and structure.
void main() {
  const seasonDir = 'content_pipeline/seasons/s9_sandbox';
  final seasonJson = PlanFiles.readJson('$seasonDir/season.plan.json') as Map<String, Object?>;
  final caseJson = PlanFiles.readJson('$seasonDir/cases/s9_ep01/case.plan.json') as Map<String, Object?>;
  final season = SeasonPlan.fromJson(seasonJson);

  Map<String, Object?> copy(Map<String, Object?> json) => jsonDecode(jsonEncode(json)) as Map<String, Object?>;
  Map<String, Object?> mission(Map<String, Object?> j, int i) => (j['missions'] as List)[i] as Map<String, Object?>;
  Map<String, Object?> words(Map<String, Object?> j, int i) => mission(j, i)['play'] as Map<String, Object?>;

  /// The findings on [change]d copies of the sandbox plans, as `[code] path`.
  List<String> found(void Function(Map<String, Object?> c) change, {void Function(Map<String, Object?> s)? inSeason}) {
    final c = copy(caseJson)..let(change);
    final s = copy(seasonJson)..let(inSeason ?? (_) {});
    return [for (final i in PlayCheck.casePlan(CasePlan.fromJson(c), SeasonPlan.fromJson(s))) '[${i.code}] ${i.path}'];
  }

  test('the sandbox case can be made: nothing missing', () {
    expect(PlayCheck.casePlan(CasePlan.fromJson(caseJson), season), isEmpty);
  });

  test('two missions in a row at one map pin (one room) are a case the game plays, not an error', () {
    final w = [for (final i in [0, 1]) words(caseJson, i)];
    expect((w[0]['mapX'], w[0]['mapY']), (w[1]['mapX'], w[1]['mapY']), reason: 'M1 and M2: the front desk');
  });

  test('saved and opened again, the plans are the same, written as they are', () {
    final tmp = Directory.systemTemp.createTempSync('play_check');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final plan = CasePlan.fromJson(caseJson);
    PlanFiles.saveCasePlan(plan, '${tmp.path}/case.plan.json');
    PlanFiles.saveSeasonPlan(season, '${tmp.path}/season.plan.json');
    expect(PlanFiles.loadCasePlan('${tmp.path}/case.plan.json').toJson(), plan.toJson());
    expect(PlanFiles.loadSeasonPlan('${tmp.path}/season.plan.json').toJson(), season.toJson());
    String onDisk(String path) => File(path).readAsStringSync().replaceAll('\r\n', '\n');
    expect(onDisk('${tmp.path}/case.plan.json'), onDisk('$seasonDir/cases/s9_ep01/case.plan.json'), reason: 'the canonical form');
    expect(onDisk('${tmp.path}/season.plan.json'), onDisk('$seasonDir/season.plan.json'), reason: 'the canonical form');
  });

  test('a plan with no words written keeps its format and structure, and is not playable', () {
    final bare = copy(caseJson)..remove('play');
    for (final m in [...bare['missions'] as List, bare['final']]) {
      (m as Map).remove('play');
    }
    final plan = CasePlan.fromJson(bare);
    expect(PlanCheck.casePlan(plan, season: season), isEmpty);
    expect([for (final i in PlayCheck.casePlan(plan, season)) '[${i.code}] ${i.path}'], [
      r'[play_missing] $.play',
      r'[play_missing] $.missions[0].play',
      r'[play_missing] $.missions[1].play',
      r'[play_missing] $.missions[2].play',
      r'[play_missing] $.final.play',
    ]);
  });

  test('each missing word is named by its path, every one at once', () {
    expect(
      found((c) {
        words(c, 1).remove('hints');
        words(c, 1).remove('mapX');
        (c['final'] as Map<String, Object?>)['play'] = {...(c['final'] as Map)['play'] as Map}..remove('transition');
        (c['play'] as Map).remove('caseSummary');
      }),
      [
        r'[play_field_missing] $.play.caseSummary',
        r'[play_field_missing] $.missions[1].play.hints',
        r'[play_field_missing] $.missions[1].play.mapX',
        r'[play_field_missing] $.final.play.transition',
      ],
    );
  });

  test('a choice of two options is refused here, as the game refuses it', () {
    expect(found((c) => ((mission(c, 0)['puzzle'] as Map)['answerSpec'] as Map)['options'] = [
      {'id': 'desk', 'label': 'On the front desk'},
      {'id': 'shelf', 'label': 'On the blue shelf by the window'},
    ]), [r'[play_choice_few] $.missions[0].puzzle.answerSpec.options']);
  });

  test('hints, clues, symbols, pins, lines for the wrong puzzle', () {
    expect(found((c) => words(c, 0)['hints'] = ['One.', 'Two.', 'Three.']), [r'[play_range] $.missions[0].play.hints']);
    expect(found((c) => words(c, 0).remove('clue')), [r'[play_field_missing] $.missions[0].play.clue']);
    expect(found((c) => (c['final'] as Map)['play'] = {...(c['final'] as Map)['play'] as Map, 'clue': {'title': 'T', 'value': 'V', 'note': 'N'}}),
        [r'[play_clue_mismatch] $.final.play.clue']);
    expect(found((c) => (words(c, 0)['evidence'] as Map)['icon'] = 'book'), [r'[play_symbol_unknown] $.missions[0].play.evidence.icon']);
    expect(found((c) => words(c, 0)['lockTitle'] = 'THE DESK LOCK'), [r'[play_range] $.missions[0].play.lockTitle'],
        reason: 'only a letter lock has a plate to name');
    expect(found((c) => words(c, 0)['feedback'] = {'desk': 'No.'}), [r'[play_range] $.missions[0].play.feedback']);
    expect(found((c) => words(c, 0)['orderFeedback'] = 'Wrong order.'), [r'[play_range] $.missions[0].play.orderFeedback']);
    expect(found((c) => words(c, 0)['recall'] = {'title': 'Find it'}), [r'[play_recall] $.missions[0].play.recall']);
  });

  test("places: each mission's registered, of the season, on disk", () {
    expect(found((_) {}, inSeason: (s) => (s['places'] as List).removeAt(1)), [r'[place_unregistered] $.missions[2].placeId']);
    final missing = PlayCheck.casePlan(
      CasePlan.fromJson(caseJson),
      SeasonPlan.fromJson(copy(seasonJson)..let((s) => ((s['places'] as List).first as Map)['file'] = 'assets/none/nothing.png')),
    );
    expect([for (final i in missing) (i.code, i.path, i.inSeason)], [('place_file_missing', r'$.places[0].file', true)]);
  });

  test('a puzzle the generator cannot make yet is named (Paris Case 10: its own engines)', () {
    const root = 'test/fixtures/season_gen/s2_paris';
    final paris = PlayCheck.casePlan(PlanFiles.loadCasePlan('$root/cases/s2_ep10/case.plan.json'), PlanFiles.loadSeasonPlan('$root/season.plan.json'));
    expect(paris.where((i) => i.code == 'generate_unsupported'), hasLength(4));
  });

  test("its numbers are the game's", () {
    expect(PlayCheck.maxHints, AppConstants.maxHints);
    final validator = File('lib/data/content/season_content_validator.dart').readAsStringSync();
    expect(validator, contains("if (ids.length < ${PlayCheck.minChoiceOptions}) out.add('\${ids.length} options: a guess, not a choice');"));
  });
}

extension<T> on T {
  T let(void Function(T) change) {
    change(this);
    return this;
  }
}
