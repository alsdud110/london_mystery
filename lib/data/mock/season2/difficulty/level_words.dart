import '../../../models/case_talk.dart';
import '../../../models/easy_steps.dart';
import '../../../models/learning.dart';
import '../season2_learning.dart';

// What more than one Paris case's level files are told with: the builders
// (each copies its base's structure and takes a level's words), and
// Victor's words that Cases 11 and 12 both quote.

// ═════════════════════════════════════════════════════════════════════════
// Easy steps (Cases 04–12)
// ═════════════════════════════════════════════════════════════════════════

/// A step's words at a level: null keeps the base's (a way to play, or a
/// paper's words read out).
typedef StepWords = ({String? say, List<String> hints, Map<String, String> feedback, String? tell, String? done});

/// [base]'s steps told in a level's words (also Cases 07–12's) ([words], by step id). What each
/// step shows, its choices, its answer and how many free hints lead to it
/// are the base's.
EasyStepsScene retold(EasyStepsScene base, Map<String, StepWords> words) => EasyStepsScene(
      title: base.title,
      answer: base.answer,
      finishLabel: base.finishLabel,
      seen: base.seen,
      steps: [
        for (final s in base.steps)
          if (words[s.id] case final w?)
            EasyStep(
              id: s.id,
              say: w.say ?? s.say,
              panels: s.panels,
              does: s.does,
              button: s.button,
              target: s.target,
              lit: s.lit,
              question: s.question,
              options: [
                for (final o in s.options) EasyOption(id: o.id, label: o.label, panel: o.panel, area: o.area, feedback: o.feedback == null ? null : w.feedback[o.id]!),
              ],
              answer: s.answer,
              hints: w.hints,
              lookHere: s.lookHere,
              wrong: s.wrong,
              tell: s.tell == null ? null : w.tell!,
              done: w.done ?? s.done,
              after: s.after,
              doneButton: s.doneButton,
            )
          else
            s,
      ],
    );

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

/// [id]'s learning design at a level: its own English (and its aim, where
/// the aim quotes it); what the mission depends on, its level and skill as
/// they are.
LearningObjective levelObjectiveWith(String id, {required List<String> expressions, String? objective}) {
  final base = season2Learning[id]!;
  return LearningObjective(
    dependency: base.dependency,
    level: base.level,
    skill: base.skill,
    recallFrom: base.recallFrom,
    objective: objective ?? base.objective,
    expressions: expressions,
  );
}

/// [id]'s learning design at a level: its own English; the rest as it is
/// (Cases 04–12).
LearningObjective levelObjective(String id, List<String> expressions) {
  final base = season2Learning[id]!;
  return LearningObjective(
    dependency: base.dependency,
    level: base.level,
    skill: base.skill,
    recallFrom: base.recallFrom,
    objective: base.objective,
    expressions: expressions,
  );
}

// ═════════════════════════════════════════════════════════════════════════
// Talks (Cases 11–12)
// ═════════════════════════════════════════════════════════════════════════

/// [base] said as [text], by the same voice and in the same mood.
TalkLine _say(TalkLine base, String text) => switch (base.voice) {
      TalkVoice.narrator => TalkLine.narrator(text),
      TalkVoice.detective => TalkLine.detective(text),
      TalkVoice.speaker => TalkLine(text, mood: base.mood),
    };

/// Each line of [base] said as [texts] (as many, in order).
List<TalkLine> _beat(List<TalkLine> base, List<String> texts) {
  assert(texts.length == base.length, 'a beat keeps its number of lines');
  return [for (final (i, l) in base.indexed) _say(l, texts[i])];
}

/// A talk's words at a level: its goal, its opening, each question's words
/// and beat (by id), each piece to show's prompt, beat, line for a wrong
/// piece and the line that names the right one (by id).
typedef TalkWords = ({
  String goal,
  List<String> opening,
  Map<String, (String, List<String>)> questions,
  Map<String, (String, List<String>, String, String)> presents,
});

/// [base] told in a level's words. Who speaks, the steps, what each needs
/// and accepts, every line's voice and mood, and how the talk ends are the
/// base's.
TalkScene retoldTalk(TalkScene base, TalkWords w) => TalkScene(
      id: base.id,
      speaker: base.speaker,
      goal: w.goal,
      opening: _beat(base.opening, w.opening),
      questions: [
        for (final q in base.questions)
          TalkQuestion(
            id: q.id,
            text: w.questions[q.id]!.$1,
            beat: _beat(q.beat, w.questions[q.id]!.$2),
            requires: q.requires,
            repeatable: q.repeatable,
          ),
      ],
      presents: [
        for (final p in base.presents)
          TalkPresent(
            id: p.id,
            prompt: w.presents[p.id]!.$1,
            accepted: p.accepted,
            beat: _beat(p.beat, w.presents[p.id]!.$2),
            misses: p.misses,
            miss: _say(p.miss, w.presents[p.id]!.$3),
            requires: p.requires,
            choices: p.choices,
            tell: p.tell == null ? null : w.presents[p.id]!.$4,
          ),
      ],
      finishWhen: base.finishWhen,
      place: base.place,
      background: base.background,
      finishLabel: base.finishLabel,
      answer: base.answer,
      earlierEvidence: base.earlierEvidence,
    );

TalkWords talkWordsOnly(String goal, List<String> opening) => (goal: goal, opening: opening, questions: const {}, presents: const {});

TalkMission retoldMission(TalkMission base, {TalkWords? before, TalkWords? after}) => TalkMission(
      before: base.before == null ? null : retoldTalk(base.before!, before!),
      after: base.after == null ? null : retoldTalk(base.after!, after!),
    );

// Victor's own words, as the case file and his evidence quote them.
const hidThePage = 'Yes. I hid the page.';
