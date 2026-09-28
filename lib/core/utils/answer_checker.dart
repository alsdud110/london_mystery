import '../../data/models/mission.dart';

/// Decides whether a player's submission solves a mission.
///
/// Text answers are forgiving for kids: case, spaces and punctuation are
/// ignored ("stone", " Stone! " and "STONE" all match).
abstract final class AnswerChecker {
  static final _nonAlphaNumeric = RegExp(r'[^A-Z0-9]');

  static String normalize(String input) => input.toUpperCase().replaceAll(_nonAlphaNumeric, '');

  static bool isCorrect(Mission mission, String submission) {
    switch (mission.type) {
      case MissionType.multipleChoice:
      case MissionType.imageChoice:
        return submission == mission.answer;
      case MissionType.wordInput:
      case MissionType.numberCode:
      case MissionType.qrScan:
      case MissionType.finalCode:
        final given = normalize(submission);
        if (given.isEmpty) return false;
        return [mission.answer, ...mission.acceptedAnswers].any((a) => normalize(a) == given);
    }
  }
}
