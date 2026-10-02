import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Spacing scale (4-point). Screens use [screen] as their side margin.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
  static const screen = 24.0;
}

/// Corner radii. Paper documents are nearly square; nothing is a pill.
abstract final class AppRadius {
  static const paper = 4.0;
  static const button = 8.0;
  static const sheet = 20.0;
}

/// Shadows: paper lifted off the desk, and a document laid on the night desk.
abstract final class AppShadow {
  static const paperLift = [
    BoxShadow(color: Color(0x142A2622), blurRadius: 1, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1A2A2622), blurRadius: 10, offset: Offset(0, 4)),
  ];
  static const onNight = [BoxShadow(color: Color(0x73000000), blurRadius: 28, offset: Offset(0, 14))];
}

/// Icon sizes for [InkIcon] (logical px). Picture-sized art such as the
/// register screen's detective emblem is sized on its own.
abstract final class AppIconSize {
  /// Tiny marks inside small labels (map pin arrow).
  static const tiny = 14.0;

  /// Inline with caption text (clue location, "Look closer").
  static const small = 18.0;

  /// Buttons, choice ticks, tabs.
  static const medium = 22.0;

  /// App bars and list tiles (the [InkIcon] default).
  static const regular = 24.0;

  /// Floating actions.
  static const large = 28.0;

  /// A glyph centred in a round emblem (start screen, notebook cover).
  static const emblem = 40.0;

  /// The single picture of a panel (QR prompt, try-again sheet).
  static const hero = 52.0;
}

/// Line weights for ink drawing.
abstract final class AppLine {
  static const hairline = 1.0;
  static const rule = 1.5;
  static const ink = 2.0;

  /// Faint ink for borders and rules on paper.
  static Color faint([double alpha = 0.18]) => AppColors.ink.withValues(alpha: alpha);
}
