import 'dart:ui' show Color;

import '../../models/mission.dart';
import '../../models/scene_decode.dart';
import '../../models/scene_explore.dart' show ScenePixels;

/// Missions played by examining one thing at their place (presentation
/// only: nothing here is saved). Mission id → its [DecodeScene]. Only
/// [MissionType.examine] missions are listed.
///
/// What the code hides is the mission's data (its letter, its evidence's
/// symbols), not written here, so the order shown is the order the final
/// locks read. Coordinates were checked drawn over the picture itself.
final Map<String, DecodeScene> season1Decodes = {
  // ── Case 01 M5 — the crown card by the palace gate (1536 × 1024) ─────
  // An old card leans on the stone pier of the gate, the palace lit behind
  // the railings: a jewelled crown on its left, a square symbol drawn like a
  // QR code (a small crown at its middle) on its right. The symbol is only
  // a drawing: the scan over it is the game's.
  'm05': DecodeScene(
    picture: 'assets/images/case01/buckingham_palace_crown_card.png',
    pixels: _gate,
    place: 'The gate of Buckingham Palace, at night',
    thing: 'An old card with a crown and a strange square symbol',
    // The card's face, below its sloping top edge, the strip of its top-left
    // corner, and its right edge as it leans out under the railings.
    areas: [_gate.rect(165, 300, 1000, 828), _gate.rect(145, 252, 665, 300), _gate.rect(1000, 420, 1100, 815)],
    // The symbol's top-right corner (the glass never hides the crown).
    mark: _gate.at(975, 425),
    // The card with a little of the stones around it.
    closer: _gate.rect(110, 220, 1150, 870),
    // The square symbol.
    code: _gate.rect(645, 415, 980, 710),
    // Decoded: the symbol gone, the card's paper restored where it was (the
    // same pixels elsewhere; the fleur-de-lis below and the stains to the
    // right kept), the pictures drawn there, turned as the card is (its
    // edges slope down to the right); short of the crown (it ends about
    // x 620) and of the card's border lines. Then the card's right half,
    // closer (the pictures over 60 dp wide on a 360 dp phone), the crown's
    // edge still in sight. The area is the tool's `_area`: keep the two in
    // step.
    cleared: 'assets/images/case01/buckingham_palace_crown_card_code_clear.png',
    clearedArea: _gate.rect(648, 414, 980, 714),
    messageTilt: 0.035,
    revealed: _gate.rect(530, 310, 1040, 780),
    // The symbol's brown ink (about 90 · 56 · 23 in the picture).
    ink: Color(0xFF5A3817),
    inside: _gate.rect(36, 30, 1500, 994),
    found: 'You found a mysterious card near the palace gate.',
    tapTask: 'Tap the card to look closer.',
    closerTask: 'A crown, and a strange square symbol. What does it hide?',
    missLine: 'Only wet stones and leaves here. Look at the card.',
  ),
};

/// The thing to examine at [m]'s place, or null when [m] is played as before.
DecodeScene? decodeOf(Mission m) => season1Decodes[m.id];

// The crown card by the palace gate, in pixels.
const _gate = ScenePixels(1536, 1024);
