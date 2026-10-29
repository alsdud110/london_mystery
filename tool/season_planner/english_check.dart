import '../season_gen/plan_models.dart';
import 'finding.dart';

/// The English a player reads, counted (STEP 3-11): sentences too long for
/// a reader of 8 to 12, long words no glossary explains, a letter that runs
/// on, the same line again and again. Heuristics only: each finding asks for
/// a look, none judges the English. Whether a case reads well for its age is
/// Claude's review, kept beside them in the story bible (`englishReview`).
abstract final class EnglishCheck {
  /// Words in one sentence before it is long for the age.
  static const maxSentenceWords = 15;

  /// Letters in a lower-case word before it may be hard (unless the case's
  /// glossary or key words have it).
  static const longWord = 10;

  /// Words in one mission's letter before it is a lot to read.
  static const maxLetterWords = 110;

  /// Times the same sentence may come back in the season before it is a habit.
  static const maxRepeats = 2;

  /// Long words a reader of 8 to 12 knows: never "hard" for their length.
  static const commonLongWords = {
    'everything', 'everywhere', 'everybody', 'everyone', 'something', 'somewhere', 'sometimes', 'understand', //
    'classroom', 'blackboard', 'university', 'grandmother', 'grandfather', 'afternoon', 'basketball', 'chocolate',
    'beautiful', 'different', 'important', 'remember', 'yourself', 'detective', 'notebook', 'bookseller', 'bookshop',
  };

  /// Every text of [c] a player reads, with its JSON path.
  static List<(String, String)> texts(CasePlan c) {
    final out = <(String, String)>[];
    void add(String path, String? text) {
      if (text != null && text.trim().isNotEmpty) out.add((path, text));
    }

    void lines(String path, List<String> list) {
      for (final (i, t) in list.indexed) {
        add('$path[$i]', t);
      }
    }

    lines(r'$.synopsis', c.synopsis);
    add(r'$.hook', c.hook);
    if (c.play case final p?) {
      lines(r'$.play.intro', p.intro);
      lines(r'$.play.objectives', p.objectives);
      add(r'$.play.caseSummary', p.caseSummary);
    }
    for (final (i, m) in c.allMissions.indexed) {
      final at = m.isFinal ? r'$.final' : '\$.missions[$i]';
      for (final (j, o) in m.puzzle.answerSpec.options.indexed) {
        add('$at.puzzle.answerSpec.options[$j].label', o.label);
        add('$at.puzzle.answerSpec.options[$j].feedback', o.feedback);
      }
      final w = m.play;
      if (w == null) continue;
      lines('$at.play.story', w.story);
      add('$at.play.letterIntro', w.letterIntro);
      add('$at.play.letter', w.letter);
      add('$at.play.question', w.question);
      add('$at.play.prompt', w.prompt);
      lines('$at.play.hints', w.hints);
      add('$at.play.successMessage', w.successMessage);
      lines('$at.play.transition', w.transition);
      for (final MapEntry(:key, :value) in w.feedback.entries) {
        add('$at.play.feedback.$key', value);
      }
      add('$at.play.orderFeedback', w.orderFeedback);
      add('$at.play.evidenceLinkLine', w.evidenceLinkLine);
      if (w.clue case final k?) {
        add('$at.play.clue.note', k.note);
      }
      if (w.evidence case final e?) {
        add('$at.play.evidence.description', e.description);
        add('$at.play.evidence.inscription', e.inscription);
      }
      if (w.recall case final r?) {
        add('$at.play.recall.prompt', r.prompt);
        add('$at.play.recall.miss', r.miss);
      }
      // The scenes' words the player reads (STEP 3-13).
      if (w.explore case final s?) {
        final sa = '$at.play.explore';
        for (final (k, v) in [('task', s.task), ('nextTask', s.nextTask), ('missLine', s.missLine), ('choiceHow', s.choiceHow)]) {
          add('$sa.$k', v);
        }
        for (final (j, x) in s.spots.indexed) {
          add('$sa.spots[$j].line', x.line);
          add('$sa.spots[$j].lockedLine', x.lockedLine);
        }
        for (final (j, o) in s.others.indexed) {
          add('$sa.others[$j].line', o.line);
        }
      }
      if (w.search case final s?) {
        final sa = '$at.play.search';
        add('$sa.task', s.task);
        add('$sa.missLine', s.missLine);
        lines('$sa.arrival', s.arrival);
        for (final (j, f) in s.finds.indexed) {
          add('$sa.finds[$j].foundLine', f.foundLine);
        }
        for (final (j, o) in s.spots.indexed) {
          add('$sa.spots[$j].line', o.line);
        }
      }
      if (w.dialogue case final s?) {
        final sa = '$at.play.dialogue';
        add('$sa.goal', s.goal);
        add('$sa.how', s.how);
        for (final (j, q) in s.questions.indexed) {
          add('$sa.questions[$j].text', q.text);
        }
        for (final (j, x) in s.witnesses.indexed) {
          add('$sa.witnesses[$j].greeting', x.greeting);
          for (final MapEntry(:key, :value) in x.answers.entries) {
            add('$sa.witnesses[$j].answers.$key', value.line);
          }
        }
        for (final MapEntry(:key, :value) in s.deduction.lines.entries) {
          add('$sa.deduction.$key', value);
        }
      }
      // The story around the puzzle (STEP 3-13B).
      if (w.talk case final t?) {
        add('$at.play.talk.goal', t.goal);
        for (final (part, p) in [('before', t.before), ('after', t.after)]) {
          for (final (j, l) in (p?.lines ?? const <TalkLinePlan>[]).indexed) {
            add('$at.play.talk.$part.lines[$j]', l.text);
          }
        }
      }
      if (w.discovery case final d?) {
        add('$at.play.discovery.title', d.title);
        add('$at.play.discovery.detail', d.detail);
        add('$at.play.discovery.note', d.note);
      }
      for (final (j, l) in w.ending.indexed) {
        add('$at.play.ending[$j]', l.text);
      }
    }
    return out;
  }

  static final _sentenceEnd = RegExp(r'(?<=[.!?])\s+|\n+');
  static final _word = RegExp(r"[A-Za-z][A-Za-z'’-]*");

  /// The sentences of [text]: split at its ends and its lines.
  static List<String> sentences(String text) => [
    for (final s in text.split(_sentenceEnd))
      if (s.trim().isNotEmpty) s.trim(),
  ];

  static int words(String text) => _word.allMatches(text).length;

  /// Its findings on [cases], in play order.
  static void check(List<CasePlan> cases, Findings out) {
    final seen = <String, List<String>>{};
    for (final c in cases) {
      final known = {...?c.play?.glossary.keys, for (final k in c.play?.keyWords ?? const <String>[]) k.toLowerCase()};
      final hard = <String>{};
      for (final (path, text) in texts(c)) {
        final where = 'cases/${c.caseId} $path';
        for (final s in sentences(text)) {
          final n = words(s);
          if (n > maxSentenceWords) {
            out.warning('en_long_sentence', where, '$n words: "${_short(s)}" (at most $maxSentenceWords for ages 8-12)', source: Source.englishHeuristic);
          }
          if (n >= 4) (seen[s.toLowerCase()] ??= []).add(where);
        }
        if (path.endsWith('.letter') && words(text) > maxLetterWords) {
          out.warning('en_long_text', where, '${words(text)} words in one letter (at most $maxLetterWords)', source: Source.englishHeuristic);
        }
        for (final m in _word.allMatches(text)) {
          // A possessive is its word ("the inspector's notes").
          final w = m[0]!.replaceAll(RegExp(r"['’]s$"), '');
          if (w.length < longWord || w != w.toLowerCase() || known.contains(w) || commonLongWords.contains(w) || !hard.add(w)) continue;
          out.warning('en_hard_word', where, '"$w" may be hard for ages 8-12: in the glossary, or a simpler word', source: Source.englishHeuristic);
        }
      }
    }
    for (final MapEntry(key: s, value: where) in seen.entries) {
      if (where.length > maxRepeats) {
        out.warning('en_repeated', where.first, '"${_short(s)}" ${where.length} times in the season (${where.skip(1).take(3).join('; ')}…)', source: Source.englishHeuristic);
      }
    }
  }

  static String _short(String s) => s.length > 60 ? '${s.substring(0, 57)}...' : s;
}
