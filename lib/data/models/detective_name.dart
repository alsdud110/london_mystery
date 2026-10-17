import '../../core/constants/app_constants.dart';

/// The one rule for a detective's name.
///
/// The letters are kept exactly as typed (Lee, MIN, alex, McDonald): the
/// game never changes a name's case, in storage or on screen. Names saved in
/// capitals by earlier versions stay as they were.
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

  /// Where the detective's name goes in a line that speaks to them.
  static const placeholder = '{detectiveName}';

  /// [text] with [placeholder] replaced by [name], as saved (never changed in
  /// case). Without a name the placeholder and the space before it go
  /// ("Hello, Detective {detectiveName}!" → "Hello, Detective!"): a line
  /// never shows "null" or the placeholder itself.
  ///
  /// A name that already starts with the title ("Detective Lu") is not
  /// titled twice: "Dear Detective {detectiveName}," → "Dear Detective Lu,".
  /// The name goes in as plain text (never as a pattern), whatever it holds.
  static String address(String text, String? name) {
    final n = normalize(name ?? '');
    if (n.isEmpty) return text.replaceAll(' $placeholder', '').replaceAll(placeholder, '');
    if (_titled.hasMatch(n)) text = text.replaceAll('$_title $placeholder', n);
    return text.replaceAll(placeholder, n);
  }

  static const _title = 'Detective';
  static final _titled = RegExp(r'^detective(\s|$)', caseSensitive: false);

  /// How the game names the detective on its own: "Detective Luna" (or just
  /// "Detective" without a name, and never "Detective Detective Lu").
  static String title(String? name) => address('$_title $placeholder', name);

  /// [text] split around each [placeholder]: the parts as written, with the
  /// name's place between them (`null`). For a surface that must keep the
  /// name apart from the words around it (a name is never a dotted word).
  static List<String?> splitAtName(String text) {
    final parts = text.split(placeholder);
    return [
      for (final (i, part) in parts.indexed) ...[if (i > 0) null, part],
    ];
  }
}
