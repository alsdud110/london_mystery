import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography helpers.
///
/// Three families, each with one job (use at most two per screen):
/// - [display] Cinzel — short upper-case labels and stamps only
///   ("CASE CLOSED", "EVIDENCE"), never sentences.
/// - [heading] Libre Baskerville — titles and place names (storybook serif).
/// - [body] Nunito — everything a child reads, and buttons.
///
/// The bundled fonts are variable fonts, so every style sets both
/// [FontWeight] and the matching `wght` [FontVariation].
abstract final class AppText {
  static const display = 'Cinzel';
  static const heading = 'LibreBaskerville';
  static const body = 'Nunito';

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
    return TextStyle(
      fontFamily: family,
      // The bundled faces are Latin only. Korean (a detective's name, the
      // grown-ups' pages) falls back to one clear system Hangul face on each
      // platform instead of whatever the engine picks per glyph.
      fontFamilyFallback: _hangulFallback,
      fontSize: size,
      fontWeight: weight,
      fontStyle: fontStyle,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Brand mark ("LONDON MYSTERY").
  static TextStyle logo({double size = 40, Color color = AppColors.navy}) =>
      style(display, size: size, weight: FontWeight.w700, color: color, letterSpacing: 3, height: 1.05);

  /// Short upper-case label ("EVIDENCE", "TIP 1").
  static TextStyle eyebrow({Color color = AppColors.goldDeep}) =>
      style(display, size: 13, weight: FontWeight.w700, color: color, letterSpacing: 2.5);

  /// Titles and place names.
  static TextStyle title({double size = 26, Color color = AppColors.navy}) =>
      style(heading, size: size, weight: FontWeight.w700, color: color, height: 1.2);

  /// Quiet storybook line under a title (italic serif).
  static TextStyle aside({double size = 16, Color color = AppColors.muted}) =>
      style(heading, size: size, weight: FontWeight.w400, color: color, height: 1.4, fontStyle: FontStyle.italic);

  static TextStyle subtitle({Color color = AppColors.ink}) =>
      style(body, size: 18, weight: FontWeight.w700, color: color, height: 1.35);

  static TextStyle bodyText({double size = 18, Color color = AppColors.ink, FontWeight weight = FontWeight.w500}) =>
      style(body, size: size, weight: weight, color: color, height: 1.5);

  static TextStyle letter({double size = 19, Color color = AppColors.inkBrown}) =>
      style(body, size: size, weight: FontWeight.w700, color: color, height: 1.6);

  static TextStyle button({double size = 17, Color color = Colors.white}) =>
      style(body, size: size, weight: FontWeight.w800, color: color, letterSpacing: 1.2);

  static TextStyle caption({Color color = AppColors.muted}) =>
      style(body, size: 14, weight: FontWeight.w600, color: color, height: 1.4);
}
