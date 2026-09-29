import 'package:flutter/foundation.dart';

import 'mission.dart';

@immutable
class Episode {
  const Episode({
    required this.id,
    required this.number,
    required this.title,
    required this.synopsis,
    required this.objectives,
    required this.intro,
    required this.missions,
    required this.finalMission,
    this.glossary = const {},
    this.caseSummary,
    this.keyWords = const [],
    this.hook,
  });

  final String id;
  final int number;
  final String title;
  final List<String> synopsis;
  final List<String> objectives;

  /// Lines shown one by one with a typewriter effect before the game starts.
  final List<String> intro;

  /// Regular missions, in play order.
  final List<Mission> missions;
  final Mission finalMission;

  /// Tap-to-reveal meanings for harder words (lower-case word → Korean meaning).
  final Map<String, String> glossary;

  /// One English sentence for the case report (null: the report's default).
  final String? caseSummary;

  /// A few key English words of the case, named in the parent report.
  final List<String> keyWords;

  /// Season story hook shown after the case is closed ("what happens next?").
  final String? hook;

  List<Mission> get allMissions => [...missions, finalMission];

  List<Clue> get allClues => [for (final m in allMissions) ?m.clue];

  List<Evidence> get allEvidence => [for (final m in allMissions) ?m.evidence];

  static final _nonWord = RegExp(r"[^a-z']");

  /// Looks up [word] ignoring case and surrounding punctuation.
  String? meaningOf(String word) {
    final key = word.toLowerCase().replaceAll(_nonWord, '');
    return glossary[key] ?? (key.endsWith("'s") ? glossary[key.substring(0, key.length - 2)] : null);
  }

  Mission? missionById(String id) {
    for (final m in allMissions) {
      if (m.id == id) return m;
    }
    return null;
  }

  String get numberLabel => number.toString().padLeft(2, '0');

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        id: json['id'] as String,
        number: json['number'] as int,
        title: json['title'] as String,
        synopsis: (json['synopsis'] as List).cast<String>(),
        objectives: (json['objectives'] as List).cast<String>(),
        intro: (json['intro'] as List).cast<String>(),
        missions: [for (final m in json['missions'] as List) Mission.fromJson(m as Map<String, dynamic>)],
        finalMission: Mission.fromJson(json['finalMission'] as Map<String, dynamic>, finale: true),
        glossary: {
          for (final e in (json['glossary'] as Map? ?? const {}).entries)
            e.key.toString().toLowerCase(): e.value.toString(),
        },
        caseSummary: json['caseSummary'] as String?,
        keyWords: (json['keyWords'] as List? ?? const []).cast<String>(),
        hook: json['hook'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'title': title,
        'synopsis': synopsis,
        'objectives': objectives,
        'intro': intro,
        'missions': [for (final m in missions) m.toJson()],
        'finalMission': finalMission.toJson(),
        'glossary': glossary,
        if (caseSummary != null) 'caseSummary': caseSummary,
        if (keyWords.isNotEmpty) 'keyWords': keyWords,
        if (hook != null) 'hook': hook,
      };
}
