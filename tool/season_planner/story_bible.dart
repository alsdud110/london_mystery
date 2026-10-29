import '../season_gen/plan_ids.dart';
import '../season_gen/plan_models.dart';
import 'finding.dart';

/// A season's story bible (STEP 3-11): `planning/story_bible.json`, the
/// writer's whole truth the plans are written from. The plans hold what the
/// game shows; the bible holds why: who each person is, what each place is
/// for, how the acts turn, every question the season asks and the case that
/// answers it, the clues that run between cases, and Claude's review of the
/// English. The game never reads it.
///
/// Checked against the season and case plans: the same people, places,
/// acts and case titles, its questions answered in the season, its clue
/// threads present in the missions' clue inputs.
abstract final class StoryBible {
  static const path = 'planning/story_bible.json';
  static const schemaVersion = 1;

  static const _top = {
    'schemaVersion', 'seasonId', 'city', 'title', 'tagline', 'logline', 'coreMystery', 'themes', 'startingSituation', 'ending', //
    'characters', 'locations', 'acts', 'cases', 'mysteryQuestions', 'clueThreads', 'timeline', 'englishReview', 'notes',
  };
  static const _required = {
    'schemaVersion', 'seasonId', 'city', 'title', 'tagline', 'logline', 'coreMystery', 'themes', 'startingSituation', 'ending', //
    'characters', 'locations', 'acts', 'cases', 'mysteryQuestions', 'clueThreads', 'englishReview',
  };
  static const _mystery = ['question', 'truth', 'culprit', 'motive', 'method', 'revealCase', 'resolvedCase'];
  static const _character = ['charId', 'name', 'role', 'personality', 'purpose', 'appearance', 'relationships', 'cases'];
  static const _location = ['locId', 'name', 'cityArea', 'visual', 'storyRole', 'cases', 'placeIds'];
  static const _act = ['actId', 'title', 'summary', 'caseIds', 'turningPoint'];
  static const _case = ['caseId', 'title', 'question', 'solution', 'fromPrevious', 'toNext'];

  /// Checks [json] against [season] and [cases] (in play order). Returns the
  /// summary the quality report keeps.
  static Map<String, Object?> check(Object? json, SeasonPlan season, List<CasePlan> cases, Findings out) {
    void error(String code, String at, String m) => out.error(code, '$path $at', m, source: Source.bible);
    void warning(String code, String at, String m) => out.warning(code, '$path $at', m, source: Source.bible);

    if (json is! Map) {
      error('bible_invalid', r'$', 'not a JSON object');
      return const {};
    }
    for (final k in json.keys) {
      if (!_top.contains(k)) error('bible_field_unknown', '\$.$k', 'not a field of the story bible');
    }
    for (final k in _required) {
      if (!json.containsKey(k)) error('bible_field_missing', '\$.$k', 'missing');
    }
    if (json['schemaVersion'] != schemaVersion) error('bible_invalid', r'$.schemaVersion', 'must be $schemaVersion');
    if (json['seasonId'] != season.seasonId) error('bible_invalid', r'$.seasonId', '${json['seasonId']}, not ${season.seasonId}');
    for (final k in ['city', 'title', 'tagline']) {
      final mine = switch (k) { 'city' => season.city, 'title' => season.title, _ => season.tagline };
      if (json[k] != mine) error('bible_season_mismatch', '\$.$k', '"${json[k]}", but season.plan.json has "$mine"');
    }

    List<Map> objects(String key, List<String> fields) {
      final v = json[key];
      if (v is! List) return const [];
      final list = <Map>[];
      for (final (i, o) in v.indexed) {
        if (o is! Map) {
          error('bible_invalid', '\$.$key[$i]', 'not an object');
          continue;
        }
        for (final f in fields) {
          final x = o[f];
          if (x == null || x is String && x.trim().isEmpty) error('bible_field_missing', '\$.$key[$i].$f', 'missing');
        }
        list.add(o);
      }
      return list;
    }

    final caseIds = season.caseIds;
    int order(Object? id) => id is String ? caseIds.indexOf(id) : -1;
    final byCase = {for (final c in cases) c.caseId: c};

    // The core mystery: the season plan's, revealed and resolved within it.
    final core = json['coreMystery'];
    if (core is Map) {
      for (final f in _mystery) {
        if (core[f] is! String || (core[f] as String).isEmpty) error('bible_field_missing', '\$.coreMystery.$f', 'missing');
      }
      if (core['revealCase'] != season.mainMystery.revealCase) {
        error('bible_season_mismatch', r'$.coreMystery.revealCase', '${core['revealCase']}, but season.plan.json reveals it in ${season.mainMystery.revealCase}');
      }
      if (order(core['resolvedCase']) < 0) {
        error('mystery_unresolved', r'$.coreMystery.resolvedCase', '${core['resolvedCase']} is not a case of the season: the core mystery is never resolved');
      } else if (order(core['resolvedCase']) < order(core['revealCase'])) {
        error('mystery_order', r'$.coreMystery.resolvedCase', 'resolved before it is revealed (${core['revealCase']})');
      }
      if (order(season.mainMystery.revealCase) < 2 * casesPerAct) {
        warning('mystery_early', r'$.coreMystery.revealCase', '${season.mainMystery.revealCase}: the culprit is shown before Act 3');
      }
    }

    // People: the season plan's, the same names, in the cases that name them.
    final people = {for (final c in season.characters) c.charId: c};
    final named = <String>{};
    for (final (i, c) in objects('characters', _character).indexed) {
      final at = '\$.characters[$i]';
      final id = c['charId'];
      final plan = people[id];
      if (plan == null) {
        error('bible_character_unknown', '$at.charId', '$id is not a character of season.plan.json');
        continue;
      }
      named.add(id as String);
      if (c['name'] != plan.name) error('bible_season_mismatch', '$at.name', '"${c['name']}", but season.plan.json names $id "${plan.name}"');
      final listed = {for (final x in (c['cases'] is List ? c['cases'] as List : const [])) x};
      for (final x in listed) {
        if (order(x) < 0) error('bible_case_unknown', '$at.cases', '$x is not a case of the season');
      }
      final inPlans = {for (final p in cases) if (p.characters.contains(id)) p.caseId};
      final missing = inPlans.difference(listed);
      final extra = listed.difference(inPlans).where((x) => byCase.containsKey(x));
      if (missing.isNotEmpty) warning('bible_character_cases', '$at.cases', 'the case plans of ${missing.join(', ')} name $id too');
      if (extra.isNotEmpty) warning('bible_character_cases', '$at.cases', '${extra.join(', ')} do not name $id in their case plans');
      final first = inPlans.isEmpty ? null : caseIds.firstWhere(inPlans.contains);
      if (first != null && first != plan.firstCase) {
        warning('character_first_case', '$at.cases', '$id first appears in $first, but season.plan.json says ${plan.firstCase}');
      }
      for (final (j, r) in (c['relationships'] is List ? c['relationships'] as List : const []).indexed) {
        if (r is! Map || !people.containsKey(r['charId']) || r['relation'] is! String) {
          error('bible_character_unknown', '$at.relationships[$j]', 'a relationship is {charId of the season, relation}');
        }
      }
    }
    for (final id in people.keys) {
      if (!named.contains(id)) error('bible_character_missing', r'$.characters', '$id (season.plan.json) has no entry');
    }

    // Places.
    final locs = {for (final l in season.locations) l.locId: l};
    final placeIds = {for (final p in season.places) p.placeId};
    final describedPlaces = <String>{};
    final seenLocs = <String>{};
    for (final (i, l) in objects('locations', _location).indexed) {
      final at = '\$.locations[$i]';
      final id = l['locId'];
      final plan = locs[id];
      if (plan == null) {
        error('bible_location_unknown', '$at.locId', '$id is not a location of season.plan.json');
        continue;
      }
      seenLocs.add(id as String);
      if (l['name'] != plan.name) error('bible_season_mismatch', '$at.name', '"${l['name']}", but season.plan.json has "${plan.name}"');
      for (final p in (l['placeIds'] is List ? l['placeIds'] as List : const [])) {
        if (!placeIds.contains(p)) error('bible_place_unknown', '$at.placeIds', '$p is not a place of season.plan.json');
        if (p is String) describedPlaces.add(p);
      }
      final inPlans = {for (final p in cases) if (p.locations.contains(id)) p.caseId};
      final listed = {for (final x in (l['cases'] is List ? l['cases'] as List : const [])) x};
      if (!listed.containsAll(inPlans)) warning('bible_location_cases', '$at.cases', 'the case plans of ${inPlans.difference(listed).join(', ')} name $id too');
    }
    for (final id in locs.keys) {
      if (!seenLocs.contains(id)) error('bible_location_missing', r'$.locations', '$id (season.plan.json) has no entry');
    }
    for (final p in placeIds) {
      if (!describedPlaces.contains(p)) warning('bible_place_missing', r'$.locations', '$p belongs to no location');
    }

    // Acts and cases: the season plan's, in its order, with the case plans' titles.
    final acts = objects('acts', _act);
    if (acts.length != season.acts.length) error('bible_season_mismatch', r'$.acts', '${acts.length} acts, season.plan.json has ${season.acts.length}');
    for (final (i, a) in acts.indexed) {
      if (i >= season.acts.length) break;
      final want = season.acts[i];
      if (a['actId'] != want.actId || '${a['caseIds']}' != '${want.caseIds}') {
        error('bible_season_mismatch', '\$.acts[$i]', '${a['actId']} ${a['caseIds']}, but season.plan.json has ${want.actId} ${want.caseIds}');
      }
    }
    final outline = objects('cases', _case);
    if ('${[for (final c in outline) c['caseId']]}' != '$caseIds') {
      error('bible_season_mismatch', r'$.cases', 'the outline is not Case 01-12 in the season\'s order');
    }
    for (final (i, c) in outline.indexed) {
      final plan = byCase[c['caseId']];
      if (plan != null && c['title'] != plan.title) {
        error('bible_case_mismatch', '\$.cases[$i].title', '"${c['title']}", but the case plan is "${plan.title}"');
      }
    }

    // Every question asked is answered, after it is asked.
    final questions = objects('mysteryQuestions', ['question', 'raisedIn', 'answeredIn', 'answer']);
    for (final (i, q) in questions.indexed) {
      final (raised, answered) = (order(q['raisedIn']), order(q['answeredIn']));
      if (raised < 0) error('bible_case_unknown', '\$.mysteryQuestions[$i].raisedIn', '${q['raisedIn']} is not a case of the season');
      if (answered < 0) {
        error('mystery_unresolved', '\$.mysteryQuestions[$i].answeredIn', '"${q['question']}" is never answered in the season');
      } else if (answered < raised) {
        error('mystery_order', '\$.mysteryQuestions[$i].answeredIn', '"${q['question']}" is answered in ${q['answeredIn']}, before it is asked');
      }
    }

    // Clue threads: a clue of one case that a later mission uses (its clue inputs say so).
    final producer = <String, String>{};
    final missions = <String, MissionPlan>{};
    for (final c in cases) {
      for (final m in c.allMissions) {
        missions[m.missionId] = m;
        for (final id in [?m.clueOutputs.clue, m.clueOutputs.evidence, ...m.clueOutputs.facts]) {
          producer[id] = m.missionId;
        }
      }
    }
    final threads = objects('clueThreads', ['from', 'to', 'meaning']);
    var longRange = 0;
    for (final (i, t) in threads.indexed) {
      final at = '\$.clueThreads[$i]';
      final from = t['from'];
      if (from is! String || !PlanIds.clueRef.hasMatch(from)) {
        error('bible_thread_invalid', '$at.from', '$from is not a clue, evidence or fact id');
        continue;
      }
      final made = producer[from];
      if (made == null) {
        error('bible_thread_invalid', '$at.from', 'no mission leaves $from');
        continue;
      }
      final to = t['to'] is List ? (t['to'] as List).whereType<String>().toList() : const <String>[];
      if (to.isEmpty) error('bible_field_missing', '$at.to', 'the missions that use it');
      for (final id in to) {
        final m = missions[id];
        if (m == null) {
          error('bible_thread_invalid', '$at.to', '$id is not a mission of the cases');
        } else if (!m.clueInputs.any((c) => c.ref == from)) {
          error('bible_thread_unlinked', '$at.to', '$id does not use $from (its clueInputs do not name it)');
        } else {
          final gap = order(PlanIds.caseOfChild(id)) - order(PlanIds.caseOfChild(from));
          if (gap < 0) error('clue_used_before_discovery', '$at.to', '$id comes before $from is found');
          if (gap >= 2) longRange++;
        }
      }
    }

    // Claude's reading of each case's English, beside the heuristics.
    final reviews = objects('englishReview', ['caseId', 'level', 'verdict', 'notes']);
    final reviewed = {for (final r in reviews) r['caseId']};
    for (final r in reviews) {
      out.info('english_review', '$path ${r['caseId']}', '${r['level']}: ${r['verdict']}', source: Source.claudeReview);
    }
    for (final c in cases) {
      if (!reviewed.contains(c.caseId)) warning('english_review_missing', r'$.englishReview', '${c.caseId} has no review of its English');
    }

    return {
      'characters': named.length,
      'locations': seenLocs.length,
      'mysteryQuestions': questions.length,
      'clueThreads': threads.length,
      'longRangeThreads': longRange,
      'englishReviews': reviews.length,
    };
  }
}
