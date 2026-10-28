import 'plan_ids.dart';
import 'plan_models.dart';
import 'puzzle_selection_check.dart' show Severity;

/// The codes of the clue graph check's findings.
abstract final class ClueCode {
  // ── Errors: a clue the player cannot have when it is asked for ────────
  /// A clue input no mission of the season leaves (nor given from outside).
  static const notFound = 'clue_not_found';

  /// A clue input left only by a later mission, or a later case.
  static const usedBeforeDiscovery = 'clue_used_before_discovery';

  /// The same clue id left by two missions.
  static const duplicateOutput = 'clue_duplicate_output';

  /// A clue needed to find itself: a mission given what it leaves.
  static const dependencyCycle = 'clue_dependency_cycle';

  /// A case plan of another season, or of no act of it.
  static const caseNotInSeason = 'case_not_in_season';

  /// Two case plans of one case.
  static const caseGivenTwice = 'case_given_twice';

  // ── Warnings ──────────────────────────────────────────────────────────
  /// A clue left that no later mission is given.
  static const neverUsed = 'clue_never_used';
}

/// Where a clue is named: a mission's output (left) or input (given).
class ClueSite {
  const ClueSite(this.clue, this.caseId, this.missionId, this.path, {this.use});

  final String clue;
  final String caseId;
  final String missionId;

  /// Its place in its case plan (`$.missions[0].clueInputs[1]`).
  final String path;

  /// How it is used: an input's only.
  final ClueUse? use;

  Map<String, Object?> toJson() => {'clue': clue, 'caseId': caseId, 'missionId': missionId, 'path': path, if (use != null) 'use': use!.name};

  @override
  String toString() => '$missionId at $path';
}

/// One finding: how much it weighs, its code, the clue, where it is asked
/// for and where it is left.
class ClueIssue {
  const ClueIssue(
    this.severity,
    this.code,
    this.caseId,
    this.path,
    this.message, {
    this.clue,
    this.requiredAt,
    this.producedAt = const [],
    this.cycle = const [],
    this.acrossCases = false,
  });

  final Severity severity;
  final String code;

  /// The case plan and the place in it the finding is at: the input's, or
  /// (a duplicate, an unused clue) the output's.
  final String caseId;
  final String path;
  final String message;
  final String? clue;

  /// The input that asks for [clue].
  final ClueSite? requiredAt;

  /// The outputs that leave [clue], in play order.
  final List<ClueSite> producedAt;

  /// The missions, in play order, of a dependency cycle this finding closes.
  final List<String> cycle;

  /// A finding of the season (between cases, or of the cases given), not
  /// of one case plan alone.
  final bool acrossCases;

  bool get isError => severity == Severity.error;

  Map<String, Object?> toJson() => {
    'severity': severity.name,
    'code': code,
    'caseId': caseId,
    'path': path,
    if (clue != null) 'clue': clue,
    'message': message,
    if (requiredAt != null) 'requiredAt': requiredAt!.toJson(),
    if (producedAt.isNotEmpty) 'producedAt': [for (final s in producedAt) s.toJson()],
    if (cycle.isNotEmpty) 'cycle': cycle,
  };

  @override
  String toString() {
    final left = producedAt.isEmpty ? '' : ' (left by ${producedAt.join(', ')})';
    final loop = cycle.isEmpty ? '' : ' [in a cycle of ${cycle.length} missions: ${cycle.join(', ')}]';
    return '[$code] $caseId $path: $message$left$loop';
  }
}

/// The clue graph of one case plan or of a season's case plans.
class ClueGraphReport {
  const ClueGraphReport(this.issues, {required this.producers, required this.consumers, required this.unresolved, this.complete = false});

  final List<ClueIssue> issues;

  /// Every clue left, and where (more than one: a duplicate), in play order.
  final Map<String, List<ClueSite>> producers;

  /// Every clue asked for, and where, in play order.
  final Map<String, List<ClueSite>> consumers;

  /// Inputs not judged here: of another case (a case plan checked alone,
  /// with no clues given it), or of a case of the season whose plan is not
  /// given. The season, with that case's plan, judges them.
  final List<ClueSite> unresolved;

  /// Every case of the season given: the season's verdict is whole.
  final bool complete;

  List<ClueIssue> get errors => [for (final i in issues) if (i.isError) i];
  List<ClueIssue> get warnings => [for (final i in issues) if (!i.isError) i];
  bool get hasErrors => issues.any((i) => i.isError);

  List<ClueSite> producersOf(String clue) => producers[clue] ?? const [];
  List<ClueSite> consumersOf(String clue) => consumers[clue] ?? const [];

  /// Inputs asking for a clue: all, the [unresolved] among them.
  int get inputs => consumers.values.fold(0, (n, l) => n + l.length);
}

/// An input and the output it is answered by.
typedef _Link = ({ClueSite input, ClueSite output});

/// One case plan's graph, before it is judged with the season's.
class _CaseGraph {
  _CaseGraph(this.report, this.links, this.backward);

  final ClueGraphReport report;

  /// Inputs answered by an output (forward, backward, self).
  final List<_Link> links;

  /// Inputs answered only by a later output of the case (or the same mission's).
  final List<_Link> backward;
}

/// Whether the clues a plan's missions are given are found before them
/// (STEP 3-4): the clue graph, its producers (`clueOutputs`) and its
/// consumers (`clueInputs`), in play order.
///
/// The play order is the plans' own: a case's missions as listed, then its
/// final (`CasePlan.allMissions`); the cases as the season plan's acts list
/// them (`SeasonPlan.caseIds`), never by their numbers. A plan has no
/// optional mission and no branch: every player finds every clue, in that
/// one order. A clue's id names its case (`s3_ep03_c1`, as `PlanCheck`
/// keeps every output of its case's own), so an id is one clue in the whole
/// season. A use is what the plan's `clueInputs` say, of every kind, a
/// story mention (`textMention`) too; story words are never read.
///
/// In one order, every dependency cycle of more than one mission runs
/// through an input asked for before it is found, already reported as
/// [ClueCode.usedBeforeDiscovery] (the cycle is named on it); only a
/// mission given its own output is a [ClueCode.dependencyCycle] of its own.
///
/// Runs on plans whose format and structure hold (`PlanCheck`).
abstract final class ClueGraphCheck {
  /// The clue graph of [plan] alone: its own clues, judged whole. A clue of
  /// another case is judged against [available] (the clues the cases
  /// before it leave), or, with none given, left [ClueGraphReport.unresolved]
  /// for the season. A clue never used is not judged: a later case may use it.
  static ClueGraphReport casePlan(CasePlan plan, {Set<String>? available}) => _case(plan, available).report;

  static _CaseGraph _case(CasePlan plan, Set<String>? available) {
    final issues = <ClueIssue>[];
    final producers = <String, List<ClueSite>>{};
    final consumers = <String, List<ClueSite>>{};
    final unresolved = <ClueSite>[];
    final links = <_Link>[];
    final backward = <_Link>[];
    final missions = plan.allMissions;
    String at(int i) => i == plan.missions.length ? r'$.final' : '\$.missions[$i]';

    // What each mission leaves, in play order.
    final index = <String, int>{};
    for (final (i, m) in missions.indexed) {
      index[m.missionId] = i;
      final o = m.clueOutputs;
      for (final (key, id) in [
        ('clue', o.clue),
        ('evidence', o.evidence),
        for (final (k, f) in o.facts.indexed) ('facts[$k]', f),
      ]) {
        if (id == null) continue;
        final site = ClueSite(id, plan.caseId, m.missionId, '${at(i)}.clueOutputs.$key');
        final earlier = producers[id] ??= [];
        if (earlier.isNotEmpty) {
          issues.add(ClueIssue(Severity.error, ClueCode.duplicateOutput, plan.caseId, site.path, '$id is left again: a clue is found once', clue: id, producedAt: [...earlier]));
        }
        earlier.add(site);
      }
    }

    // What each mission is given.
    for (final (i, m) in missions.indexed) {
      for (final (j, c) in m.clueInputs.indexed) {
        final site = ClueSite(c.ref, plan.caseId, m.missionId, '${at(i)}.clueInputs[$j]', use: c.use);
        (consumers[c.ref] ??= []).add(site);
        if (PlanIds.caseOfChild(c.ref) != plan.caseId) {
          if (available == null) {
            unresolved.add(site);
          } else if (!available.contains(c.ref)) {
            issues.add(ClueIssue(Severity.error, ClueCode.notFound, plan.caseId, site.path, '${c.ref} is not among the clues given to ${plan.caseId}', clue: c.ref, requiredAt: site));
          }
          continue;
        }
        final left = producers[c.ref];
        if (left == null) {
          issues.add(ClueIssue(Severity.error, ClueCode.notFound, plan.caseId, site.path, 'no mission of ${plan.caseId} leaves ${c.ref}', clue: c.ref, requiredAt: site));
          continue;
        }
        final link = (input: site, output: left.first);
        links.add(link);
        if (index[left.first.missionId]! >= i) backward.add(link);
      }
    }

    final cycles = _cycles(links);
    for (final l in backward) {
      final self = l.output.missionId == l.input.missionId;
      issues.add(ClueIssue(
        Severity.error,
        self ? ClueCode.dependencyCycle : ClueCode.usedBeforeDiscovery,
        plan.caseId,
        l.input.path,
        self ? '${l.input.clue} is given to the mission that leaves it: it is found only once the mission is solved' : '${l.input.clue} is asked for before it is found',
        clue: l.input.clue,
        requiredAt: l.input,
        producedAt: producers[l.input.clue]!,
        cycle: self ? [l.input.missionId] : _cycleOf(cycles, l, (id) => index[id]!),
      ));
    }
    issues.sort((a, b) => _place(a.path).compareTo(_place(b.path)));
    return _CaseGraph(ClueGraphReport(issues, producers: producers, consumers: consumers, unresolved: unresolved), links, backward);
  }

  /// The clue graph of [season]'s case plans [cases], in the season's
  /// order: the plans it cannot place (of another season, of no act, given
  /// twice), each case's own findings ([casePlan]'s), then those between
  /// cases and of the cases given (these and the first [ClueIssue.acrossCases]). An input of a
  /// case whose plan is not given stays [ClueGraphReport.unresolved]; a
  /// clue is reported [ClueCode.neverUsed] only when every case after its
  /// own is given (and never the season's last final's: nothing follows it).
  static ClueGraphReport season(SeasonPlan season, List<CasePlan> cases) {
    final order = season.caseIds;
    final issues = <ClueIssue>[];
    final byId = <String, CasePlan>{};
    for (final c in cases) {
      if (c.seasonId != season.seasonId) {
        issues.add(ClueIssue(Severity.error, ClueCode.caseNotInSeason, c.caseId, r'$.seasonId', '${c.caseId} is of ${c.seasonId}, not ${season.seasonId}', acrossCases: true));
      } else if (!order.contains(c.caseId)) {
        issues.add(ClueIssue(Severity.error, ClueCode.caseNotInSeason, c.caseId, r'$.caseId', '${c.caseId} is in no act of ${season.seasonId}', acrossCases: true));
      } else if (byId.containsKey(c.caseId)) {
        issues.add(ClueIssue(Severity.error, ClueCode.caseGivenTwice, c.caseId, r'$.caseId', '${c.caseId} is given twice: its first plan is checked', acrossCases: true));
      } else {
        byId[c.caseId] = c;
      }
    }

    final producers = <String, List<ClueSite>>{};
    final consumers = <String, List<ClueSite>>{};
    final graphs = <String, _CaseGraph>{};
    final links = <_Link>[];
    final rank = <String, int>{};
    for (final (k, id) in order.indexed) {
      final c = byId[id];
      if (c == null) continue;
      final g = graphs[id] = _case(c, null);
      for (final (i, m) in c.allMissions.indexed) {
        rank[m.missionId] = k * 100 + i;
      }
      issues.addAll(g.report.issues);
      links.addAll(g.links);
      for (final e in g.report.producers.entries) {
        (producers[e.key] ??= []).addAll(e.value);
      }
      for (final e in g.report.consumers.entries) {
        (consumers[e.key] ??= []).addAll(e.value);
      }
    }

    // Inputs of another case's clues, against the cases before.
    final unresolved = <ClueSite>[];
    final backward = <_Link>[];
    final across = <ClueIssue>[];
    for (final (k, id) in order.indexed) {
      for (final site in graphs[id]?.report.unresolved ?? const <ClueSite>[]) {
        final from = PlanIds.caseOfChild(site.clue);
        final f = from == null ? -1 : order.indexOf(from);
        final left = producers[site.clue];
        if (f < 0) {
          across.add(ClueIssue(Severity.error, ClueCode.notFound, id, site.path, '${site.clue} is of no case of ${season.seasonId}', clue: site.clue, requiredAt: site, acrossCases: true));
        } else if (byId.containsKey(from) && left == null) {
          across.add(ClueIssue(Severity.error, ClueCode.notFound, id, site.path, 'no mission of $from leaves ${site.clue}', clue: site.clue, requiredAt: site, acrossCases: true));
        } else if (f > k) {
          if (left == null) {
            across.add(ClueIssue(Severity.error, ClueCode.usedBeforeDiscovery, id, site.path, '${site.clue} is of $from, a later case (its plan not given)', clue: site.clue, requiredAt: site, acrossCases: true));
          } else {
            final link = (input: site, output: left.first);
            links.add(link);
            backward.add(link);
          }
        } else if (left == null) {
          unresolved.add(site);
        } else {
          links.add((input: site, output: left.first));
        }
      }
    }
    final cycles = _cycles(links);
    for (final l in backward) {
      across.add(ClueIssue(
        Severity.error,
        ClueCode.usedBeforeDiscovery,
        l.input.caseId,
        l.input.path,
        '${l.input.clue} is of ${l.output.caseId}, a later case: it is asked for before it is found',
        clue: l.input.clue,
        requiredAt: l.input,
        producedAt: producers[l.input.clue]!,
        cycle: _cycleOf(cycles, l, (id) => rank[id]!),
        acrossCases: true,
      ));
    }

    // Clues no one is given, once every later case is known.
    for (final (k, id) in order.indexed) {
      final c = byId[id];
      if (c == null || order.skip(k + 1).any((later) => !byId.containsKey(later))) continue;
      for (final MapEntry(key: clue, value: sites) in graphs[id]!.report.producers.entries) {
        // The season's last mission ends it: nothing comes after to be given it.
        if (consumers.containsKey(clue) || (k == order.length - 1 && sites.first.missionId == c.finalMission.missionId)) continue;
        across.add(ClueIssue(Severity.warning, ClueCode.neverUsed, id, sites.first.path, '$clue is left, but no mission is given it', clue: clue, producedAt: sites, acrossCases: true));
      }
    }

    int caseRank(String caseId) => order.contains(caseId) ? order.indexOf(caseId) : order.length;
    across.sort((a, b) {
      final byCase = caseRank(a.caseId).compareTo(caseRank(b.caseId));
      return byCase != 0 ? byCase : _place(a.path).compareTo(_place(b.path));
    });
    issues.addAll(across);
    return ClueGraphReport(issues, producers: producers, consumers: consumers, unresolved: unresolved, complete: order.every(byId.containsKey));
  }

  /// A path's place in its case plan's play order, for sorting.
  static String _place(String path) {
    final m = RegExp(r'^\$\.missions\[(\d+)\]').firstMatch(path);
    final head = m != null ? m.group(1)!.padLeft(2, '0') : (path.startsWith(r'$.final') ? '98' : '99');
    final input = path.contains('clueInputs') ? '1' : '0';
    return '$head$input$path';
  }

  /// The mission graph's strongly connected parts of more than one mission
  /// (an input's mission depends on its output's), by Tarjan's algorithm.
  static List<Set<String>> _cycles(List<_Link> links) {
    final edges = <String, Set<String>>{};
    for (final l in links) {
      (edges[l.input.missionId] ??= {}).add(l.output.missionId);
      edges[l.output.missionId] ??= {};
    }
    final index = <String, int>{};
    final low = <String, int>{};
    final stack = <String>[];
    final onStack = <String>{};
    final out = <Set<String>>[];
    void visit(String v) {
      index[v] = low[v] = index.length;
      stack.add(v);
      onStack.add(v);
      for (final w in edges[v]!) {
        if (!index.containsKey(w)) {
          visit(w);
          low[v] = low[v]! < low[w]! ? low[v]! : low[w]!;
        } else if (onStack.contains(w)) {
          low[v] = low[v]! < index[w]! ? low[v]! : index[w]!;
        }
      }
      if (low[v] == index[v]) {
        final part = <String>{};
        String w;
        do {
          w = stack.removeLast();
          onStack.remove(w);
          part.add(w);
        } while (w != v);
        if (part.length > 1) out.add(part);
      }
    }

    for (final v in edges.keys) {
      if (!index.containsKey(v)) visit(v);
    }
    return out;
  }

  /// The missions, in play order, of the cycle [l] is a link of, or none.
  static List<String> _cycleOf(List<Set<String>> cycles, _Link l, int Function(String missionId) rank) {
    for (final c in cycles) {
      if (c.contains(l.input.missionId) && c.contains(l.output.missionId)) return [...c]..sort((a, b) => rank(a).compareTo(rank(b)));
    }
    return const [];
  }
}
