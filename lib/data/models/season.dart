import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

/// Who stands behind the season's cases, as far as the detective knows.
///
/// A figure is revealed only once the case that names it in the story has
/// been solved ([afterCase]), so the season board never tells more than the
/// player has read.
@immutable
class SeasonFigure {
  const SeasonFigure({required this.afterCase, required this.figure, required this.label});

  /// The case whose solving reveals this figure (season record).
  final String afterCase;

  /// Which picture stands for it on the board (`ravens`, `ravenSociety`,
  /// `clockmaker`, `clockmakerWatch`; unknown keys show a question mark).
  final String figure;
  final String label;

  static SeasonFigure? fromJson(Object? json) {
    if (json is! Map) return null;
    final after = json['after'];
    final figure = json['figure'];
    final label = json['label'];
    if (after is! String || figure is! String || label is! String) return null;
    return SeasonFigure(afterCase: after, figure: figure, label: label);
  }
}

/// The season's opening sequence: short scenes, one message each, played
/// once before the first case.
@immutable
class SeasonPrologue {
  const SeasonPrologue({
    this.city = '',
    this.cases = const [],
    this.separate = const [],
    this.question = '',
    this.bigger = '',
    this.promise = const [],
    this.firstCasePicture = '',
    this.firstCaseLine = '',
  });

  /// London at night.
  final String city;

  /// The kinds of trouble, laid on the desk one by one.
  final List<String> cases;

  /// Over the map: they look apart — but look closer.
  final List<String> separate;

  /// The thread appears: the question the season asks.
  final String question;
  final String bigger;

  /// Under 12 CASES · ONE MYSTERY.
  final List<String> promise;

  /// The first case's file: its picture (an `ArtAssets.objects` key) and a line.
  final String firstCasePicture;
  final String firstCaseLine;

  factory SeasonPrologue.fromJson(Object? json) {
    if (json is! Map) return const SeasonPrologue();
    List<String> lines(Object? v) => v is List ? v.whereType<String>().toList() : const [];
    String text(Object? v) => v is String ? v : '';
    final first = json['firstCase'];
    return SeasonPrologue(
      city: text(json['city']),
      cases: lines(json['cases']),
      separate: lines(json['separate']),
      question: text(json['question']),
      bigger: text(json['bigger']),
      promise: lines(json['promise']),
      firstCasePicture: first is Map ? text(first['picture']) : '',
      firstCaseLine: first is Map ? text(first['line']) : '',
    );
  }
}

/// The seasons' ids. Saved with a season's own records (Season 2 on), so they
/// never change once released.
abstract final class SeasonIds {
  /// Season 1. Its saves were made before seasons had ids: they keep their
  /// keys, and its content needs no id (it is the default).
  static const london = AppConstants.firstSeasonId;

  static const paris = 's2_paris';
}

/// A season: the bigger story the cases belong to. Its cases are the
/// episode catalog, in order; this holds what is told about the season as a
/// whole. Content, like an episode: plain JSON-shaped data.
@immutable
class Season {
  const Season({
    this.id = SeasonIds.london,
    required this.number,
    required this.title,
    required this.tagline,
    required this.prologue,
    required this.outro,
    this.finale = const [],
    required this.figures,
    this.city = 'London',
    this.plannedCases,
  });

  /// [SeasonIds]: which season this is.
  final String id;

  /// The city the season's cases happen in ("London"), as the pages name it.
  final String city;

  /// How many cases the season will have once it is all in the game (12),
  /// or null: as many as are in the game. A season is complete only once
  /// all of them are solved.
  final int? plannedCases;

  final int number;

  /// "Shadows over London".
  final String title;

  /// Said after the number of cases ("ONE MYSTERY" → "12 CASES • ONE MYSTERY").
  final String tagline;

  /// The season's opening sequence (played once, before the first case).
  final SeasonPrologue prologue;

  /// The lines once every case is solved.
  final List<String> outro;

  /// The lines on the last case's report, pointing on to the next season
  /// ("London is safe." / "But the watch says PARIS."); empty: none.
  final List<String> finale;

  /// What the detective learns about who is behind it, in story order.
  final List<SeasonFigure> figures;

  /// "SEASON ONE".
  String get label => 'SEASON ${_words[number] ?? '$number'}';

  static const _words = {1: 'ONE', 2: 'TWO', 3: 'THREE', 4: 'FOUR'};

  /// The last figure revealed by the [solved] cases, or null (still a "?").
  SeasonFigure? figureFor(bool Function(String caseId) solved) {
    SeasonFigure? known;
    for (final f in figures) {
      if (solved(f.afterCase)) known = f;
    }
    return known;
  }

  /// Tolerant decoding, like the episodes: malformed lines are skipped.
  factory Season.fromJson(Map<String, dynamic> json) {
    List<String> lines(Object? v) => v is List ? v.whereType<String>().toList() : const [];
    final id = json['id'];
    final number = json['number'];
    final figures = json['figures'];
    final city = json['city'];
    final planned = json['cases'];
    return Season(
      // Season 1's content names no city: it is London.
      city: city is String && city.isNotEmpty ? city : 'London',
      plannedCases: planned is int && planned > 0 ? planned : null,
      // Season 1's content has no id: it is the default.
      id: id is String && id.isNotEmpty ? id : SeasonIds.london,
      number: number is int ? number : 1,
      title: json['title'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      prologue: SeasonPrologue.fromJson(json['prologue']),
      outro: lines(json['outro']),
      finale: lines(json['finale']),
      figures: figures is List ? figures.map(SeasonFigure.fromJson).whereType<SeasonFigure>().toList() : const [],
    );
  }
}
