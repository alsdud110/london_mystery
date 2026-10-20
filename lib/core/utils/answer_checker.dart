import 'package:flutter/foundation.dart';

import '../../data/models/mission.dart';

/// Decides whether a player's submission solves a mission.
///
/// Text answers are forgiving for kids: case, spaces and punctuation are
/// ignored ("stone", " Stone! " and "STONE" all match).
abstract final class AnswerChecker {
  static final _nonAlphaNumeric = RegExp(r'[^A-Z0-9]');

  static String normalize(String input) => input.toUpperCase().replaceAll(_nonAlphaNumeric, '');

  /// The short line for a wrong [submission]: what the child probably
  /// misread, never the answer. Null when there is none (or the submission
  /// is right): the try-again sheet then shows its general line.
  static String? feedbackFor(Mission mission, String submission) {
    if (isCorrect(mission, submission)) return null;
    switch (mission.type) {
      case MissionType.multipleChoice:
      case MissionType.imageChoice:
      case MissionType.canvasChoice:
        for (final o in mission.options) {
          if (o.id == submission) return o.feedback;
        }
        return null;
      // The first part given that is not in the answer, and its line.
      case MissionType.spotDifferences:
      case MissionType.matchPairs:
      case MissionType.revealLayer:
        final expected = Mission.sequenceIds(mission.answer).toSet();
        for (final part in Mission.sequenceIds(submission)) {
          if (!expected.contains(part)) return mission.feedback[part];
        }
        return null;
      case MissionType.sequence:
        final given = Mission.sequenceIds(submission);
        final known = mission.feedback.entries.where((e) => listEquals(Mission.sequenceIds(e.key), given));
        if (known.isNotEmpty) return known.first.value;
        return _sameItems(given, Mission.sequenceIds(mission.answer)) ? mission.orderFeedback : null;
      case MissionType.wordInput:
      case MissionType.numberCode:
      case MissionType.examine:
      case MissionType.finalCode:
      case MissionType.letterLock:
        final given = normalize(submission);
        if (given.isEmpty) return null;
        for (final e in mission.feedback.entries) {
          if (normalize(e.key) == given) return e.value;
        }
        return _sameItems(given.split(''), normalize(mission.answer).split('')) ? mission.orderFeedback : null;
    }
  }

  /// The same items, in any order (the caller knows they are not in order).
  static bool _sameItems(List<String> a, List<String> b) =>
      a.length == b.length && listEquals([...a]..sort(), [...b]..sort());

  static bool isCorrect(Mission mission, String submission) {
    switch (mission.type) {
      case MissionType.multipleChoice:
      case MissionType.imageChoice:
      case MissionType.canvasChoice:
        return submission == mission.answer;
      // Every part found, each once, in any order.
      case MissionType.spotDifferences:
      case MissionType.matchPairs:
      case MissionType.revealLayer:
        final given = Mission.sequenceIds(submission);
        final expected = Mission.sequenceIds(mission.answer);
        return given.isNotEmpty && given.length == expected.length && _sameItems(given, expected);
      case MissionType.sequence:
        final given = Mission.sequenceIds(submission);
        final expected = Mission.sequenceIds(mission.answer);
        return given.isNotEmpty && listEquals(given, expected);
      case MissionType.wordInput:
      case MissionType.numberCode:
      case MissionType.examine:
      case MissionType.finalCode:
      case MissionType.letterLock:
        final given = normalize(submission);
        if (given.isEmpty) return false;
        return [mission.answer, ...mission.acceptedAnswers].any((a) => normalize(a) == given);
    }
  }
}
