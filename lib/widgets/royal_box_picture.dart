import 'package:flutter/material.dart';

import '../data/models/episode.dart';
import '../data/models/mission.dart';
import 'art_assets.dart';
import 'symbol_icon.dart';

/// One of Case 01's four Royal Box lock pictures: its full-colour drawing
/// ([ArtAssets.royalBoxLocks]) and the name it is shown with. The one
/// mapping for every place the lock order is read — the crown card's hidden
/// message (Mission 05), the Crown Symbol evidence and the locks of the
/// final — so they never show different pictures or names.
///
/// Keyed by the locks' own symbol ids, which stay as they are in the case
/// data and the save ('park' is the swan, 'museum' the Rosetta Stone): only
/// the picture and the shown name are the Royal Box's.
@immutable
class RoyalBoxPicture {
  const RoyalBoxPicture._(this.symbol, this.name);

  final String symbol;

  /// The shown name ("Swan"): written in capitals under the picture, read
  /// as it is by screen readers.
  final String name;

  String get file => ArtAssets.royalBoxLocks[symbol]!;

  static const _names = {'clock': 'Clock', 'train': 'Train', 'park': 'Swan', 'museum': 'Stone'};

  /// The picture for lock [symbol], or null for a symbol that is not one of
  /// the Royal Box's (then the symbol's glyph is shown as before).
  static RoyalBoxPicture? of(String? symbol) {
    final name = _names[symbol];
    return name == null || !ArtAssets.royalBoxLocks.containsKey(symbol) ? null : RoyalBoxPicture._(symbol!, name);
  }

  /// [symbol]'s shown name: the Royal Box's, else the symbol's own label.
  static String nameOf(String? symbol) => of(symbol)?.name ?? GameSymbol.of(symbol).label;

  /// The picture of [clue] in the notebook: its lock's picture when the clue
  /// is one of its own case's picture locks ([episode], the clue's case:
  /// only Case 01's final has them), so the clue and its lock look alike;
  /// null otherwise (the clue keeps its stamp).
  static RoyalBoxPicture? forClue(Clue clue, Episode? episode) =>
      episode != null && episode.finalMission.dialSymbols.contains(clue.symbol) ? of(clue.symbol) : null;
}

/// A lock picture drawn [size] square, the whole drawing in it (never
/// cropped or tinted). Silent for screen readers: the name beside it is
/// read. A missing file falls back to the symbol's glyph.
class RoyalBoxPictureImage extends StatelessWidget {
  const RoyalBoxPictureImage(this.picture, {super.key, required this.size});

  final RoyalBoxPicture picture;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        picture.file,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stack) => Center(child: GameSymbol.of(picture.symbol).mark(size: size * 0.6)),
      ),
    );
  }
}
