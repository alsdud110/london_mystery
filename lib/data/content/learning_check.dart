import '../models/case_talk.dart';
import '../models/dialogue.dart';
import '../models/learning.dart';
import '../models/mission.dart';
import '../models/scene_explore.dart';

/// Whether the English a learning design names (`LearningObjective
/// .expressions`, shown in the parent report) is really on the mission's
/// pages — at the level it is played at: give it the mission as played
/// (`playedEpisodesProvider`, `DifficultyContent.episodeAt`) and the design
/// read at that level (`SeasonCatalog.learning`).
///
/// Compared as words: letters folded to lower case, curly quotes made
/// straight, every other mark a space, spaces collapsed; an expression must
/// be whole words of the text (`one hour behind` is in "is ONE HOUR
/// BEHIND,", `hour` is not in "hours").
abstract final class LearningCheck {
  /// [s] as compared: lower case, words only, single spaces. An apostrophe
  /// stays only inside a word (Bell's); one quoting words ('never sleep')
  /// is a mark like any other.
  static String words(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[‘’]'), "'")
      .replaceAll(RegExp(r"[^a-z0-9']+"), ' ')
      .replaceAll(RegExp(r"(?<![a-z0-9])'|'(?![a-z0-9])"), ' ')
      .replaceAll(RegExp(' +'), ' ')
      .trim();

  /// Everything [m] puts on screen before and during its puzzle.
  static String shownText(Mission m) => words([
        ...m.story,
        m.letterIntro,
        m.letter,
        m.question,
        m.prompt ?? '',
        for (final o in m.options) o.label,
        ...m.hints,
      ].join(' \n '));

  /// What the detective keeps from solved [m]: its pages, its clue and its
  /// evidence (read again from the notebook).
  static String keptText(Mission m) => words([
        shownText(m),
        m.clue?.title ?? '',
        m.clue?.note ?? '',
        m.evidence?.name ?? '',
        m.evidence?.description ?? '',
        m.evidence?.inscription ?? '',
      ].join(' \n '));

  /// What a mission's scenes put on screen besides its own words (a season
  /// made from its plans, Rome on, says much of its English there): its
  /// witnesses' greetings, questions and answers, the talks before and after
  /// its puzzle, its look round's tasks and the lines of what is looked at.
  static String sceneText({DialogueScene? dialogue, TalkMission? talk, ExploreScene? explore}) => words([
        if (dialogue != null) ...[
          dialogue.goal,
          dialogue.how,
          for (final q in dialogue.questions) q.text,
          for (final s in dialogue.speakers) ...[s.greeting, for (final a in s.answers.values) a.line],
        ],
        if (talk != null)
          for (final scene in [?talk.before, ?talk.after]) ...[scene.goal, for (final l in scene.opening) l.text],
        if (explore != null) ...[
          explore.task,
          explore.nextTask,
          explore.missLine,
          explore.choiceHow,
          for (final s in explore.spots) ...[s.title, s.label, s.line, s.lockedLine],
          for (final o in explore.others) ...[o.label, o.line],
        ],
      ].join(' \n '));

  /// The expressions of [objective] found neither on [own]'s pages (its
  /// [scenes] too: [sceneText]) nor in what [recalled] (its `recallFrom`
  /// mission, at the same level) left kept. Empty: every one is really there.
  static List<String> unmatched(LearningObjective objective, Mission own, {Mission? recalled, String scenes = ''}) {
    final shown = ' ${shownText(own)} $scenes ';
    final kept = recalled == null ? '' : ' ${keptText(recalled)} ';
    return [
      for (final e in objective.expressions)
        if (words(e) case final w when w.isEmpty || (!shown.contains(' $w ') && !kept.contains(' $w '))) e,
    ];
  }
}
