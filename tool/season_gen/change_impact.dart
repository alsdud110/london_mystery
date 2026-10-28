import 'clue_graph_check.dart';
import 'content_approval.dart' show ApprovalStatus;
import 'content_hash.dart';
import 'plan_ids.dart';
import 'plan_models.dart';

/// The codes of what a change touches.
abstract final class ImpactCode {
  // ── A season plan changed ─────────────────────────────────────────────
  /// A case added to an act.
  static const caseAdded = 'case_added';

  /// A case taken out of the acts.
  static const caseRemoved = 'case_removed';

  /// A case at another place in the acts (its act, or its order).
  static const caseMoved = 'case_moved';

  /// A case given a clue of a case added, removed or moved: the order its
  /// clues are found in has changed.
  static const cluesOfMovedCase = 'clues_of_moved_case';

  static const characterChanged = 'character_changed';
  static const characterRemoved = 'character_removed';
  static const locationChanged = 'location_changed';
  static const locationRemoved = 'location_removed';
  static const mainMysteryChanged = 'main_mystery_changed';
  static const figuresChanged = 'figures_changed';

  /// Any other field: nothing else names it.
  static const seasonFieldChanged = 'season_field_changed';

  // ── A case plan changed ───────────────────────────────────────────────
  static const missionAdded = 'mission_added';
  static const missionRemoved = 'mission_removed';

  /// A mission's place, puzzle, clue inputs or outputs, learning or notes.
  static const missionChanged = 'mission_changed';

  /// A clue no mission leaves any more, given to a mission.
  static const clueRemoved = 'clue_removed';

  /// A clue now left by another mission, given to a mission.
  static const clueMoved = 'clue_moved';

  /// A picture a puzzle asks for now.
  static const assetNeeded = 'asset_needed';

  /// A picture no puzzle asks for any more.
  static const assetDropped = 'asset_dropped';

  /// Any other field of the case: nothing else names it.
  static const caseFieldChanged = 'case_field_changed';

  // ── A picture changed ─────────────────────────────────────────────────
  static const assetChanged = 'asset_changed';
}

/// One thing a change touches: what changed, and what to review again.
class ImpactItem {
  const ImpactItem(this.code, this.subject, this.message, {this.review, this.at});

  final String code;

  /// What changed: `case s3_ep03`, `clue s3_ep01_c2`, `mission s3_ep01_m2`,
  /// `character guide`, `field title`.
  final String subject;
  final String message;

  /// What to review again: `casePlan s3_ep02`, `mission s3_ep01_m2`,
  /// `asset s3_tokyo.asset.hall`. Null: nothing names it (said for the record).
  final String? review;

  /// Where in [review]'s plan (an input's path).
  final String? at;

  Map<String, Object?> toJson() => {'code': code, 'subject': subject, 'message': message, if (review != null) 'review': review, if (at != null) 'at': at};

  @override
  String toString() => '[$code] $subject: $message${review == null ? '' : ' → review $review${at == null ? '' : ' $at'}'}';
}

/// What a change of an approved plan or picture touches (STEP 3-5): the
/// plans and pictures to review again before the change is approved. Only
/// what the plans name is followed: case ids in a season's acts, the
/// characters and locations a case plan lists, the clues a mission is given
/// (`ClueGraphCheck`'s consumers), the assets a puzzle asks for. Nothing is
/// changed here: it says what to look at, never what to do.
abstract final class ChangeImpact {
  /// What changing season plan [before] into [after] touches, among the
  /// season's case plans [cases].
  static List<ImpactItem> season(SeasonPlan before, SeasonPlan after, {Iterable<CasePlan> cases = const []}) {
    final out = <ImpactItem>[];

    // Its cases: added, removed, moved; and who is given their clues.
    String? actOf(SeasonPlan s, String id) => s.acts.where((a) => a.caseIds.contains(id)).firstOrNull?.actId;
    final shifted = <String>{};
    for (final id in before.caseIds) {
      if (after.caseIds.contains(id)) continue;
      shifted.add(id);
      out.add(ImpactItem(ImpactCode.caseRemoved, 'case $id', 'no longer in an act (was in ${actOf(before, id)})', review: 'casePlan $id'));
    }
    for (final (i, id) in after.caseIds.indexed) {
      if (!before.caseIds.contains(id)) {
        shifted.add(id);
        out.add(ImpactItem(ImpactCode.caseAdded, 'case $id', 'added to ${actOf(after, id)}', review: 'casePlan $id'));
      } else if (before.caseIds.indexOf(id) != i || actOf(before, id) != actOf(after, id)) {
        shifted.add(id);
        out.add(ImpactItem(
          ImpactCode.caseMoved,
          'case $id',
          'case ${before.caseIds.indexOf(id) + 1} of ${actOf(before, id)} is now case ${i + 1} of ${actOf(after, id)}',
          review: 'casePlan $id',
        ));
      }
    }
    if (shifted.isNotEmpty) {
      for (final c in cases) {
        if (shifted.contains(c.caseId)) continue;
        for (final MapEntry(key: clue, value: sites) in ClueGraphCheck.casePlan(c).consumers.entries) {
          final from = PlanIds.caseOfChild(clue);
          if (!shifted.contains(from)) continue;
          for (final s in sites) {
            out.add(ImpactItem(ImpactCode.cluesOfMovedCase, 'clue $clue', '${s.missionId} is given a clue of $from, which moved', review: 'casePlan ${c.caseId}', at: s.path));
          }
        }
      }
    }

    // Its people and places, and the case plans that list them.
    final beforeChars = {for (final c in before.characters) c.charId: c};
    final afterChars = {for (final c in after.characters) c.charId: c};
    for (final MapEntry(key: id, value: was) in beforeChars.entries) {
      final now = afterChars[id];
      if (now != null && _same(was.toJson(), now.toJson())) continue;
      final named = {
        for (final c in cases) if (c.characters.contains(id)) c.caseId,
        for (final x in [was, ?now]) ...[x.firstCase, ?x.revealCase, ?x.secretUntil],
      };
      out.addAll(_reviewing(
        now == null ? ImpactCode.characterRemoved : ImpactCode.characterChanged,
        'character $id',
        now == null ? 'no longer a character of the season' : 'changed',
        named,
      ));
    }
    final beforeLocs = {for (final l in before.locations) l.locId: l};
    final afterLocs = {for (final l in after.locations) l.locId: l};
    for (final MapEntry(key: id, value: was) in beforeLocs.entries) {
      final now = afterLocs[id];
      if (now != null && _same(was.toJson(), now.toJson())) continue;
      out.addAll(_reviewing(
        now == null ? ImpactCode.locationRemoved : ImpactCode.locationChanged,
        'location $id',
        now == null ? 'no longer a location of the season' : 'changed',
        {for (final c in cases) if (c.locations.contains(id)) c.caseId},
      ));
    }

    if (!_same(before.mainMystery.toJson(), after.mainMystery.toJson())) {
      out.addAll(_reviewing(ImpactCode.mainMysteryChanged, 'mainMystery', 'changed', {before.mainMystery.revealCase, after.mainMystery.revealCase}));
    }
    final beforeFigures = {for (final f in before.figures) ContentHash.canonicalJson(f.toJson()): f.after};
    final afterFigures = {for (final f in after.figures) ContentHash.canonicalJson(f.toJson()): f.after};
    final figures = {
      for (final e in beforeFigures.entries) if (!afterFigures.containsKey(e.key)) e.value,
      for (final e in afterFigures.entries) if (!beforeFigures.containsKey(e.key)) e.value,
    };
    if (figures.isNotEmpty) out.addAll(_reviewing(ImpactCode.figuresChanged, 'figures', 'changed', figures));

    const followed = {'acts', 'characters', 'locations', 'mainMystery', 'figures'};
    out.addAll(_fields(before.toJson(), after.toJson(), followed, ImpactCode.seasonFieldChanged));
    return out;
  }

  /// What changing case plan [before] into [after] touches: its missions,
  /// the missions (of the case, or of [others], the season's other case
  /// plans) given a clue it no longer leaves or leaves from another
  /// mission, the pictures asked for now ([assets]: their approval status).
  static List<ImpactItem> casePlan(
    CasePlan before,
    CasePlan after, {
    Iterable<CasePlan> others = const [],
    Map<String, ApprovalStatus> assets = const {},
  }) {
    final out = <ImpactItem>[];
    const followed = {'missions', 'final'};
    out.addAll(_fields(before.toJson(), after.toJson(), followed, ImpactCode.caseFieldChanged));

    final was = {for (final m in before.allMissions) m.missionId: m};
    final now = {for (final m in after.allMissions) m.missionId: m};
    for (final id in was.keys) {
      if (!now.containsKey(id)) out.add(ImpactItem(ImpactCode.missionRemoved, 'mission $id', 'no longer in the case'));
    }
    for (final MapEntry(key: id, value: m) in now.entries) {
      final old = was[id];
      if (old == null) {
        out.add(ImpactItem(ImpactCode.missionAdded, 'mission $id', 'added: its puzzle and clue links are new', review: 'mission $id'));
        continue;
      }
      final (a, b) = (old.toJson(), m.toJson());
      final parts = [
        for (final k in {...a.keys, ...b.keys}) if (!_same(a[k], b[k])) k,
      ];
      if (parts.isEmpty) continue;
      final what = [
        if (parts.contains('puzzle')) 'its puzzle (PuzzleSelectionCheck)',
        if (parts.contains('clueInputs') || parts.contains('clueOutputs')) 'its clue links (ClueGraphCheck)',
      ];
      out.add(ImpactItem(ImpactCode.missionChanged, 'mission $id', '${parts.join(', ')} changed${what.isEmpty ? '' : '; review ${what.join(' and ')}'}', review: 'mission $id'));
    }

    // Clues it no longer leaves, or leaves from another mission, and the
    // missions given them.
    final left = ClueGraphCheck.casePlan(after);
    final readers = [left, for (final c in others) if (c.caseId != after.caseId) ClueGraphCheck.casePlan(c)];
    for (final MapEntry(key: clue, value: sites) in ClueGraphCheck.casePlan(before).producers.entries) {
      final from = sites.first.missionId;
      final to = left.producersOf(clue).firstOrNull?.missionId;
      if (to == from) continue;
      final code = to == null ? ImpactCode.clueRemoved : ImpactCode.clueMoved;
      final how = to == null ? 'no longer left (was by $from)' : 'left by $to, not $from';
      final given = [for (final r in readers) ...r.consumersOf(clue)];
      if (given.isEmpty) out.add(ImpactItem(code, 'clue $clue', '$how; no mission is given it'));
      for (final s in given) {
        out.add(ImpactItem(code, 'clue $clue', '$how; ${s.missionId} is given it', review: 'casePlan ${s.caseId}', at: s.path));
      }
    }

    // The pictures its puzzles ask for.
    Set<String> needs(CasePlan p) => {for (final m in p.allMissions) ...m.puzzle.assetNeeds};
    final (had, has) = (needs(before), needs(after));
    for (final id in has.difference(had).toList()..sort()) {
      out.add(ImpactItem(ImpactCode.assetNeeded, 'asset $id', 'asked for now; its approval is ${(assets[id] ?? ApprovalStatus.draft).name}', review: 'asset $id'));
    }
    for (final id in had.difference(has).toList()..sort()) {
      out.add(ImpactItem(ImpactCode.assetDropped, 'asset $id', 'no puzzle of ${after.caseId} asks for it any more'));
    }
    return out;
  }

  /// What a change of picture [assetId] touches: every mission of [cases]
  /// whose puzzle asks for it.
  static List<ImpactItem> asset(String assetId, Iterable<CasePlan> cases) => [
    for (final c in cases)
      for (final (i, m) in c.allMissions.indexed)
        for (final (j, a) in m.puzzle.assetNeeds.indexed)
          if (a == assetId)
            ImpactItem(
              ImpactCode.assetChanged,
              'asset $assetId',
              'the picture changed; ${m.missionId} asks for it',
              review: 'mission ${m.missionId}',
              at: '${i == c.missions.length ? r'$.final' : '\$.missions[$i]'}.puzzle.assetNeeds[$j]',
            ),
  ];

  static bool _same(Object? a, Object? b) => ContentHash.canonicalJson(a) == ContentHash.canonicalJson(b);

  /// One item for each case of [caseIds] to review, or one for the record.
  static List<ImpactItem> _reviewing(String code, String subject, String message, Set<String> caseIds) => [
    if (caseIds.isEmpty) ImpactItem(code, subject, '$message; no case plan given names it'),
    for (final id in caseIds.toList()..sort()) ImpactItem(code, subject, message, review: 'casePlan $id'),
  ];

  /// The fields of [a] and [b] (but [followed]) that differ, for the record.
  static List<ImpactItem> _fields(Map<String, Object?> a, Map<String, Object?> b, Set<String> followed, String code) => [
    for (final k in {...a.keys, ...b.keys})
      if (!followed.contains(k) && !_same(a[k], b[k])) ImpactItem(code, 'field $k', 'changed'),
  ];
}
