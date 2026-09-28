import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography helpers.
///
/// The bundled fonts are variable fonts, so every style sets both
/// [FontWeight] and the matching `wght` [FontVariation].
abstract final class AppText {
  static const display = 'Cinzel'; // mystery / title lettering
  static const heading = 'Fredoka'; // friendly headings & buttons
  static const body = 'Nunito'; // reading text

  static TextStyle style(
    String family, {
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.charcoal,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle logo({double size = 40, Color color = AppColors.navy}) =>
      style(display, size: size, weight: FontWeight.w800, color: color, letterSpacing: 2, height: 1.05);

  static TextStyle eyebrow({Color color = AppColors.goldDeep}) =>
      style(display, size: 14, weight: FontWeight.w700, color: color, letterSpacing: 3);

  static TextStyle title({double size = 28, Color color = AppColors.navy}) =>
      style(heading, size: size, weight: FontWeight.w600, color: color, height: 1.15);

  static TextStyle subtitle({Color color = AppColors.charcoal}) =>
      style(heading, size: 19, weight: FontWeight.w500, color: color, height: 1.3);

  static TextStyle bodyText({double size = 18, Color color = AppColors.charcoal, FontWeight weight = FontWeight.w500}) =>
      style(body, size: size, weight: weight, color: color, height: 1.45);

  static TextStyle letter({double size = 19, Color color = AppColors.inkBrown}) =>
      style(body, size: size, weight: FontWeight.w700, color: color, height: 1.55);

  static TextStyle button({double size = 19, Color color = Colors.white}) =>
      style(heading, size: size, weight: FontWeight.w600, color: color, letterSpacing: 1.2);

  static TextStyle caption({Color color = AppColors.muted}) =>
      style(body, size: 14, weight: FontWeight.w600, color: color, height: 1.35);
}
