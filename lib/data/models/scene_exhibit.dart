import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';

import 'scene_explore.dart' show ScenePixels;

/// A thing handed to the detective with a mission's document (the lost
/// ticket with the clerk's notes): its picture beside the document, looked
/// at closer with a tap. Presentation only: the puzzle is the mission's own.
@immutable
class Exhibit {
  const Exhibit({
    required this.id,
    required this.picture,
    required this.pixels,
    required this.title,
    required this.description,
    required this.caption,
  });

  /// Saved once looked at closer (see `GameProgress.examined`).
  final String id;

  final String picture;
  final ScenePixels pixels;

  /// Its name over its close look ("THE LOST TICKET").
  final String title;

  /// What the picture shows, word for word what is printed on it, for
  /// screen readers (never more than the picture says).
  final String description;

  /// One line under it on its close look.
  final String caption;
}

/// A piece of evidence that matches another one of its case (the painting's
/// church is the one on the lost ticket): shown under it, once the other is
/// found too.
@immutable
class EvidenceLink {
  const EvidenceLink({required this.to, required this.line});

  /// The other evidence's id.
  final String to;

  /// How the two match, in a short line.
  final String line;
}

/// A letter-lock box in two pictures, shut and open, each on its own canvas
/// (they are not in register: the open lid changes the box's shape). The
/// lock's letter slots are on both ([closedSlots], [openSlots], left to
/// right, fractions of each picture): the opening is laid on them, so the
/// slots stay put while the box opens round them.
@immutable
class LockBoxArt {
  const LockBoxArt({
    required this.closed,
    required this.closedPixels,
    required this.closedSlots,
    required this.open,
    required this.openPixels,
    required this.openSlots,
    required this.inside,
    required this.insideLabel,
    required this.found,
    required this.foundPixels,
    required this.foundTitle,
    required this.foundLine,
    required this.back,
    required this.examineId,
  });

  final String closed;
  final ScenePixels closedPixels;
  final List<Rect> closedSlots;

  final String open;
  final ScenePixels openPixels;
  final List<Rect> openSlots;

  /// What lies in the open box (fractions of [open]): a tap there looks at
  /// it closer.
  final Rect inside;
  final String insideLabel;

  /// What was found, its own picture, its name and what it shows.
  final String found;
  final ScenePixels foundPixels;
  final String foundTitle;
  final String foundLine;

  /// What is written on its back.
  final String back;

  /// Saved once its back is read (see `GameProgress.examined`).
  final String examineId;

  /// Every slot of [slots] in one rectangle.
  static Rect band(List<Rect> slots) => slots.skip(1).fold(slots.first, (a, r) => a.expandToInclude(r));
}
