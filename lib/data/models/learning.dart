import 'package:flutter/foundation.dart';

/// The learning experience a mission is *designed* to give (see
/// WORLD_MYSTERY_TYPE_B_DESIGN.md §2). A design level, never a measure of
/// what a child understood.
enum LearningLevel {
  /// The English is on screen, but a key word, a picture, a symbol or a
  /// memory is enough to answer.
  exposure('Exposure', '영어를 접함'),

  /// The answer depends on what an English sentence means.
  comprehension('Comprehension', '영어 의미 이해'),

  /// The understood English is used to do something: work out a time, walk
  /// a path, put things in order, build a sentence.
  application('Application', '이해한 영어 활용'),

  /// English read earlier (an earlier letter or piece of evidence) has to be
  /// read again to answer.
  recall('Recall', '이전에 읽은 영어 다시 사용');

  const LearningLevel(this.label, this.labelKo);

  final String label;
  final String labelKo;
}

/// How much the answer depends on understanding the English.
enum LanguageDependency {
  /// Without the key phrase, only guessing reaches the answer.
  essential('영어 이해 필수'),

  /// Understanding helps, but a key word, a named picture, an answer seen
  /// before or ruling out options also reaches it.
  helpful('영어 이해가 추리에 도움'),

  /// The English sets the scene; another skill solves the puzzle.
  exposure('영어 노출 중심'),

  /// Symbols, a QR card, letter decoding: little to do with English.
  low('언어 의존성 낮음');

  const LanguageDependency(this.labelKo);

  final String labelKo;
}

/// The kind of English a mission is about.
enum LanguageSkill {
  vocabulary('어휘'),
  sentenceMeaning('문장 의미'),
  grammarInContext('문맥 속 문법');

  const LanguageSkill(this.labelKo);

  final String labelKo;
}

/// What one mission is designed to do with English. Content (a design), not
/// progress: it is never saved and never says what a child achieved.
@immutable
class LearningObjective {
  const LearningObjective({
    required this.dependency,
    required this.level,
    required this.objective,
    this.skill,
    this.expressions = const [],
    this.recallFrom,
  });

  final LanguageDependency dependency;
  final LearningLevel level;

  /// One sentence for the parent report, in Korean.
  final String objective;

  /// Null for missions that hardly use English ([LanguageDependency.low]).
  final LanguageSkill? skill;

  /// The English that decides the mission, exactly as it appears in the
  /// mission's text (or, for [recallFrom], in that earlier mission's text,
  /// clue or evidence).
  final List<String> expressions;

  /// The earlier mission whose English is read again (any case).
  final String? recallFrom;

  /// Only a mission that needs the English can claim more than exposure.
  bool get isHonest => level == LearningLevel.exposure || dependency == LanguageDependency.essential;
}

/// The language topic of one case.
@immutable
class CaseLanguageTopic {
  const CaseLanguageTopic({required this.title, required this.titleKo});

  final String title;
  final String titleKo;
}
