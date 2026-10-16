import '../../core/constants/app_constants.dart';

/// The one rule for a detective's name.
///
/// Upper- and lower-case letters are both a valid stored form: the game
/// writes names in capitals (`GameController.cleanName`), and a saved name
/// is never rejected for its case.
///
/// Letters (A–Z, a–z), Hangul syllables, digits, spaces, "." and "-"; no
/// space at either end and never two in a row; 1 to 12 characters. Every
/// allowed character is one UTF-16 unit, so Dart's `length` and the text
/// field's count agree.
abstract final class DetectiveName {
  static const minLength = AppConstants.nameMinLength;
  static const maxLength = AppConstants.nameMaxLength;

  /// The stored form: starts and ends with a non-space allowed character.
  static const pattern = r'^[A-Za-z0-9가-힣.-]([A-Za-z0-9가-힣 .-]*[A-Za-z0-9가-힣.-])?$';
  static final _pattern = RegExp(pattern);

  /// The characters that may be typed (Hangul jamo too, while a syllable is
  /// being composed).
  static final typeable = RegExp(r'[A-Za-z0-9가-힣ㄱ-ㅎㅏ-ㅣ .\-]');

  /// [raw] with the spaces at both ends removed and every run of spaces made
  /// one. Never changes a saved name: only what is typed or sent.
  static String normalize(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Whether [name] is already in the stored form and allowed.
  static bool isValid(String name) =>
      name.length >= minLength && name.length <= maxLength && !name.contains('  ') && _pattern.hasMatch(name);
}
