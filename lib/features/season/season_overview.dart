import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/season.dart';
import '../../data/models/season_progress.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';

/// Where a case stands on the season board.
enum CaseMark {
  /// Solved at least once (season record — replaying does not undo it).
  solved,

  /// The case to work on now.
  current,

  /// Open but not the one to work on (only with operator access, which
  /// opens every file).
  open,

  /// Still sealed: the case before it is not solved.
  sealed,
}

/// A thread pinned between two things on the board.
enum ThreadKind {
  /// Between two solved cases next to each other: the trail so far.
  chain,

  /// From the last solved case to the current one: where the trail leads.
  lead,

  /// From a solved case to the figure in the middle: what connects them.
  spoke,
}

@immutable
class BoardThread {
  const BoardThread(this.kind, this.from, [this.to]);

  final ThreadKind kind;

  /// Case index in the season.
  final int from;

  /// Case index, or null for the figure in the middle.
  final int? to;

  /// Stable id, to tell which threads are new since a moment ago.
  String get id => '${kind.name}:$from-${to ?? 'x'}';
}

/// The season as the detective sees it: computed from the season record,
/// the case saves and the catalog — nothing of its own is saved.
@immutable
class SeasonOverview {
  const SeasonOverview({
    required this.info,
    required this.cases,
    required this.marks,
    required this.current,
    required this.currentStarted,
    required this.figure,
    required this.begun,
  });

  final Season info;
  final List<Episode> cases;
  final List<CaseMark> marks;

  /// Index of the case to work on now, or null once every case is solved.
  final int? current;

  /// Whether the current case's story intro was seen (CONTINUE vs BEGIN).
  final bool currentStarted;

  /// Who is behind it, as far as the story has told (null: still a "?").
  final SeasonFigure? figure;

  /// Whether the season has started at all: a case begun or solved. Before
  /// that, the season opens on its casebook.
  final bool begun;

  int get total => cases.length;

  int get solvedCount => marks.where((m) => m == CaseMark.solved).length;

  bool get complete => total > 0 && solvedCount == total;

  Episode? get currentCase => current == null ? null : cases[current!];

  /// The board's threads: the trail through the solved cases, where it leads
  /// next, and — once something is known about who is behind it — a thread
  /// from every solved case to the middle. Solving the last case closes the
  /// ring.
  List<BoardThread> get threads {
    bool solved(int i) => marks[i] == CaseMark.solved;
    return [
      for (var i = 0; i + 1 < total; i++)
        if (solved(i) && solved(i + 1)) BoardThread(ThreadKind.chain, i, i + 1),
      if (complete && total > 2) BoardThread(ThreadKind.chain, total - 1, 0),
      if (current != null && current! > 0 && solved(current! - 1) && !solved(current!))
        BoardThread(ThreadKind.lead, current! - 1, current),
      if (figure != null)
        for (var i = 0; i < total; i++)
          if (solved(i)) BoardThread(ThreadKind.spoke, i),
    ];
  }

  static SeasonOverview of({
    required Season info,
    required List<Episode> catalog,
    required SeasonProgress season,
    required bool operator,
    required GameProgress Function(String episodeId) progressOf,
  }) {
    final saves = [for (final e in catalog) progressOf(e.id)];
    final ever = [for (final e in catalog) season.isSolved(e.id)];
    final unlocked = [
      for (final e in catalog) SeasonNotifier.unlockRule(catalog, season, e.id, operator: operator),
    ];

    // The case being worked on now: the open case file while it is under way
    // (also a solved case being played again); otherwise the first case that
    // was never solved — the next part of the season's story.
    final active = catalog.indexWhere((e) => e.id == season.activeEpisodeId);
    int? current;
    if (active >= 0 && saves[active].introSeen && !saves[active].isCaseSolved && unlocked[active]) {
      current = active;
    } else {
      for (var i = 0; i < catalog.length; i++) {
        if (!ever[i] && unlocked[i]) {
          current = i;
          break;
        }
      }
    }

    return SeasonOverview(
      info: info,
      cases: catalog,
      marks: [
        for (var i = 0; i < catalog.length; i++)
          ever[i]
              ? CaseMark.solved
              : i == current
              ? CaseMark.current
              : unlocked[i]
              ? CaseMark.open
              : CaseMark.sealed,
      ],
      current: current,
      currentStarted: current != null && saves[current].introSeen,
      figure: info.figureFor(season.isSolved),
      begun: season.solvedEpisodeIds.isNotEmpty || saves.any((p) => p.introSeen),
    );
  }

  /// The same season a moment before [justSolved] were solved: what the
  /// board showed last time, so it can play only what is new.
  static SeasonOverview before(SeasonOverview now, SeasonProgress season, List<String> justSolved, {
    required bool operator,
    required GameProgress Function(String episodeId) progressOf,
  }) {
    final earlier = season.copyWith(
      solvedEpisodeIds: [for (final id in season.solvedEpisodeIds) if (!justSolved.contains(id)) id],
    );
    return of(
      info: now.info,
      catalog: now.cases,
      season: earlier,
      operator: operator,
      // The cases just solved were the ones under way.
      progressOf: (id) => justSolved.contains(id) ? progressOf(id).resetCase().copyWith(introSeen: true) : progressOf(id),
    );
  }
}

/// [SeasonOverview] of the running game.
final seasonOverviewProvider = Provider<SeasonOverview>((ref) {
  final season = ref.watch(seasonProvider);
  final active = ref.watch(gameControllerProvider);
  final repo = ref.read(progressRepositoryProvider);
  return SeasonOverview.of(
    info: ref.watch(seasonInfoProvider),
    catalog: ref.watch(episodeCatalogProvider),
    season: season,
    operator: ref.watch(operatorAccessProvider),
    progressOf: (id) => id == season.activeEpisodeId ? active : repo.load(id),
  );
});
