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
  static const button = 12.0;
  static const sheet = 20.0;
}

/// The only shadow in the game: a sheet of paper lifted off the desk.
abstract final class AppShadow {
  static const paperLift = [BoxShadow(color: Color(0x1F2A2622), blurRadius: 6, offset: Offset(0, 2))];
}

/// Line weights for ink drawing.
abstract final class AppLine {
  static const hairline = 1.0;
  static const rule = 1.5;
  static const ink = 2.0;

  /// Faint ink for borders and rules on paper.
  static Color faint([double alpha = 0.18]) => AppColors.ink.withValues(alpha: alpha);
}
