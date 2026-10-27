import 'dart:ui' show Color, Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import 'scene_explore.dart' show ScenePixels, hitArea;

/// How far the detective has got with a [DecodeScene]'s thing.
enum DecodeStep {
  /// The place: the thing is somewhere in the picture.
  look,

  /// The thing, brought closer: its code can be examined.
  closer,

  /// The code examined: what it hides is shown on the thing.
  decoded,
}

/// A mission played by examining one thing found at its place (the
/// presentation of a `MissionType.examine` mission, never saved): the
/// detective finds it in the picture, looks at it closer, examines its code
/// (a short scan drawn over it: no camera, nothing is really read) and the
/// code's hidden message appears on it. Taking it then answers the mission,
/// through the same check, save, rewards and Discovery Moment as any other
/// answer. Nothing to type or choose: never a wrong answer.
///
/// What the code hides is the mission's own data: its letter (the message)
/// and its evidence's symbols (the pictures, in order).
@immutable
class DecodeScene {
  const DecodeScene({
    required this.picture,
    required this.pixels,
    required this.place,
    required this.thing,
    required this.areas,
    required this.mark,
    required this.closer,
    required this.code,
    required this.cleared,
    required this.clearedArea,
    required this.revealed,
    required this.ink,
    required this.found,
    required this.tapTask,
    required this.closerTask,
    required this.missLine,
    this.messageTilt = 0,
    this.inside = const Rect.fromLTRB(0, 0, 1, 1),
    this.examine = 'EXAMINE THE CODE',
    this.take = 'TAKE THE CARD',
  });

  /// The place's picture (its file) and its size in pixels.
  final String picture;
  final ScenePixels pixels;

  /// The place, for screen readers ("The gate of Buckingham Palace, at night").
  final String place;

  /// The thing, for screen readers and its button.
  final String thing;

  /// Where a tap reaches the thing (fractions of the picture).
  final List<Rect> areas;

  /// Where its small glass sits (fractions): on what is to be examined.
  final Offset mark;

  /// The part of the picture the thing is shown in, closer (fractions).
  final Rect closer;

  /// Its code: where the scan passes (fractions).
  final Rect code;

  /// Decoded, the code is gone from the thing: [cleared] is the picture's
  /// own pixels in [clearedArea] (fractions) with the code's ink taken off
  /// and the paper under it restored (made by
  /// `tool/card_code_clear/clear_test.dart`; the picture itself is never
  /// changed). The hidden message is drawn there, turned as the thing is
  /// ([messageTilt], radians, clockwise).
  final String cleared;
  final Rect clearedArea;
  final double messageTilt;

  /// Decoded, the part of the picture shown, closer still, so the message
  /// reads large (fractions).
  final Rect revealed;

  /// The thing's own ink, as drawn in the picture: the pencilled lines of
  /// the message are drawn in it.
  final Color ink;

  /// What the detective found, said on arriving (the panel's main line).
  final String found;

  /// How to look at it closer (the panel's tap line).
  final String tapTask;

  /// Said once it is closer, above [examine].
  final String closerTask;

  /// Said when a tap is not on the thing.
  final String missLine;

  /// The picture inside its own printed paper edge.
  final Rect inside;

  /// The buttons that examine the code, then take the thing.
  final String examine;
  final String take;

  /// The same thing in other words (a level's): its picture, code and
  /// buttons never change.
  DecodeScene copyWith({String? found, String? closerTask, String? missLine}) => DecodeScene(
        picture: picture,
        pixels: pixels,
        place: place,
        thing: thing,
        areas: areas,
        mark: mark,
        closer: closer,
        code: code,
        cleared: cleared,
        clearedArea: clearedArea,
        revealed: revealed,
        ink: ink,
        found: found ?? this.found,
        tapTask: tapTask,
        closerTask: closerTask ?? this.closerTask,
        missLine: missLine ?? this.missLine,
        messageTilt: messageTilt,
        inside: inside,
        examine: examine,
        take: take,
      );

  /// Whether a tap at [point] (fractions) reaches the thing.
  bool hits(Offset point, {Size slack = Size.zero}) =>
      hitArea<bool>(point, [(true, areas)], slack: slack) ?? false;
}

/// How far the detective has got in a [DecodeScene]: kept by the page while
/// it is open (going back to the place keeps it); never saved. The scan
/// itself is not kept: left half-way, the code is examined again.
class DecodeProgress {
  DecodeStep step = DecodeStep.look;
}
