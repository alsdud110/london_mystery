import 'package:flutter/material.dart';

/// London Mystery palette — "Vintage London Detective Storybook":
/// ink on aged paper, deep navy, with antique gold and muted royal blue as
/// the only accents.
///
/// Rules:
/// - Surfaces are paper; text, lines and icons are ink.
/// - Status colours ([success], [tryAgain], [locked]) are for small marks
///   only — stamps, short labels, lines, icons — never to fill a card.
/// - No neon or glow. The only gradients are light falling on a material:
///   the vignette of an old page and the night sky.
abstract final class AppColors {
  // ── Ink & navy ────────────────────────────────────────────────────────────
  /// Main ink: body text, outlines, icons.
  static const ink = Color(0xFF2A2622);
  static const charcoal = ink;
  static const navy = Color(0xFF1E2A44); // primary
  static const navyDeep = Color(0xFF151D30);

  /// Night sky, top to bottom (title page, story scenes, big reveals).
  static const nightTop = Color(0xFF243150);
  static const nightBottom = Color(0xFF0E1424);

  /// The London skyline standing against the night sky.
  static const nightSkyline = Color(0xFF090E1A);

  // ── Paper ────────────────────────────────────────────────────────────────
  static const paper = Color(0xFFF4ECDA); // background
  static const paperLight = Color(0xFFFAF5EA); // document surface
  static const parchment = Color(0xFFEDE2C9);
  static const parchmentDark = Color(0xFFDCCBA6); // rules, empty slots
  static const paperShade = parchmentDark;

  // ── Accents ──────────────────────────────────────────────────────────────
  static const royalBlue = Color(0xFF3E5A8C); // muted royal blue
  static const royalBlueSoft = Color(0xFFDDE2EC);
  static const gold = Color(0xFFA8844A); // antique gold
  static const goldLight = Color(0xFFD9C38F); // gold on dark backgrounds
  static const goldDeep = Color(0xFF7E5F2C); // gold ink for small text on paper (≥4.5:1)

  /// Leather of the detective's notebook cover and report folder.
  static const leather = Color(0xFF4B2C24);
  static const leatherDeep = Color(0xFF34201A);

  /// The detective's walnut desk (season pages: the casebook, the briefing
  /// and the investigation board lie on it), lit by a lamp from above.
  static const walnut = Color(0xFF3A291E);
  static const walnutDeep = Color(0xFF1B130D);
  static const burgundy = Color(0xFF7A2E2E); // seals, stamps
  static const waxRed = burgundy;
  static const inkBrown = Color(0xFF5C4630); // handwriting on letters
  static const muted = Color(0xFF6A6254); // secondary text (≥4.5:1 on paper and parchment)

  // ── Status (small marks only) ────────────────────────────────────────────
  static const success = Color(0xFF5E7A55); // muted green
  static const successSoft = Color(0xFFE3E8D8);
  static const tryAgain = Color(0xFF94453D); // muted burgundy
  static const tryAgainSoft = Color(0xFFF0DCD5);

  /// Locked / not yet: icons, outlines and large titles only (≥3:1).
  /// Small text that is locked uses [muted].
  static const locked = Color(0xFF857D6D); // muted gray

  // ── Map & illustration washes ────────────────────────────────────────────
  static const park = Color(0xFFCBD1A8);
  static const parkDeep = Color(0xFF8C9A6A);
  static const river = Color(0xFFB7C7D3);
  static const riverDeep = Color(0xFF8FA6B8);
  static const brick = Color(0xFFC7A48A);
  static const stone = Color(0xFFE9DFC9);
}
