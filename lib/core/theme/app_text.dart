import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography helpers.
///
/// Two families, each with one job:
/// - [display] IM Fell English SC — the names of the world: the season, a
///   case, a place, a document ("SHADOWS OVER LONDON", "THE CLOCK ROOM",
///   "CASE CLOSED", "EVIDENCE"), and the cinematic prompt that readies the
///   next scene ("Are you ready?"). Short, and one or two per screen; never
///   story lines, questions to answer, buttons, numbers or small UI.
///   Regular only (no fake bold).
/// - [body] Sentient — everything a child reads or presses: story, puzzles,
///   labels, buttons, numbers. The app's default family.
///
/// [aside] keeps Libre Baskerville Italic: Sentient has no italic, and a
/// slanted Sentient would be a fake one.
///
/// Sentient is a variable font (wght 200-700), so every style sets both
/// [FontWeight] and the matching `wght` [FontVariation].
abstract final class AppText {
  static const display = 'IMFellEnglishSC';
  static const body = 'Sentient';

  /// The storybook italic of [aside].
  static const italic = 'LibreBaskerville';

  /// Long reading text (story narration, dialogue): the body family.
  static const heading = body;

  /// System Hangul faces: iOS, then Android (Noto CJK), then generic names.
  static const _hangulFallback = ['Apple SD Gothic Neo', 'Noto Sans CJK KR', 'Noto Sans KR', 'sans-serif'];

  static TextStyle style(
    String family, {
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    // IM Fell has one weight: drawn as it is, never emboldened.
    final w = family == display ? FontWeight.w400 : weight;
    return TextStyle(
      fontFamily: family,
      // The bundled faces are Latin only. Korean (a detective's name, the
      // grown-ups' pages) falls back to one clear system Hangul face on each
      // platform instead of whatever the engine picks per glyph.
      fontFamilyFallback: _hangulFallback,
      fontSize: size,
      fontWeight: w,
      fontStyle: fontStyle,
      fontVariations: family == display ? null : [FontVariation('wght', w.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// The big name of a screen ("SHADOWS OVER LONDON", "CASE CLOSED").
  static TextStyle logo({double size = 40, Color color = AppColors.navy}) =>
      style(display, size: size, color: color, letterSpacing: 0.6, height: 1.05);

  /// A place, a case or a document's name ("THE CLOCK ROOM", "THE MISSING
  /// CROWN"): the world's names, in the display face.
  static TextStyle placeTitle({double size = 26, Color color = AppColors.navy}) =>
      style(display, size: size, color: color, height: 1.15);

  /// A document's own label ("EVIDENCE", "CASE REPORT", "FINAL MISSION"):
  /// short, in the display face, a little larger than [eyebrow] to stay
  /// readable.
  static TextStyle mark({Color color = AppColors.goldDeep, double size = 15.5}) =>
      style(display, size: size, color: color, letterSpacing: 1);

  /// A cinematic prompt: the one short line between the story and the way
  /// on, that readies the player for the next scene ("Are you ready?").
  /// Not a question to answer, not a story line, not a button.
  static TextStyle cinematicPrompt({double size = 28, Color color = AppColors.goldLight}) =>
      style(display, size: size, color: color, height: 1.2, letterSpacing: 0.3);

  /// Short upper-case information label ("MISSION 01", "CASES SOLVED").
  static TextStyle eyebrow({Color color = AppColors.goldDeep}) =>
      style(body, size: 13, weight: FontWeight.w600, color: color, letterSpacing: 1.8);

  /// Titles that are information, not names (a question, a card's name, a
  /// figure on the case file).
  static TextStyle title({double size = 26, Color color = AppColors.navy}) =>
      style(body, size: size, weight: FontWeight.w600, color: color, height: 1.2);

  /// Quiet storybook line under a title (italic serif).
  static TextStyle aside({double size = 16, Color color = AppColors.muted}) =>
      style(italic, size: size, weight: FontWeight.w400, color: color, height: 1.4, fontStyle: FontStyle.italic);

  static TextStyle subtitle({Color color = AppColors.ink}) =>
      style(body, size: 18, weight: FontWeight.w600, color: color, height: 1.35);

  static TextStyle bodyText({double size = 18, Color color = AppColors.ink, FontWeight weight = FontWeight.w400}) =>
      style(body, size: size, weight: weight, color: color, height: 1.5);

  static TextStyle letter({double size = 19, Color color = AppColors.inkBrown}) =>
      style(body, size: size, weight: FontWeight.w500, color: color, height: 1.6);

  static TextStyle button({double size = 17, Color color = Colors.white}) =>
      style(body, size: size, weight: FontWeight.w600, color: color, letterSpacing: 1.2);

  static TextStyle caption({Color color = AppColors.muted}) =>
      style(body, size: 14, weight: FontWeight.w500, color: color, height: 1.4);
}
