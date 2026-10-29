/// The game's picture styles, read from London's and Paris's pictures
/// (`STYLE_GUIDE.md`): each a line added to a prompt, with the size and
/// background its kind of picture is made at. The same style id always adds
/// the same words, so pictures of one season match.
class ImageStyle {
  const ImageStyle({required this.id, required this.kind, required this.size, required this.background, required this.text});

  final String id;

  /// `scene` (a place, full frame), `character` or `object` (on parchment).
  final String kind;
  final String size;
  final String background;
  final String text;
}

abstract final class ImageStyles {
  /// Every picture: for children of 8 to 12, a mystery that is never frightening.
  static const _common =
      'Storybook illustration for a children\'s detective mystery game (ages 8-12): warm, inviting and gently mysterious, never scary. '
      'No text, letters, numbers, signatures, watermarks or logos anywhere in the image.';

  static const all = <String, ImageStyle>{
    'london_scene': ImageStyle(
      id: 'london_scene',
      kind: 'scene',
      size: '1536x1024',
      background: 'opaque',
      text: '$_common Style: hand-inked pen line drawing with soft watercolour washes on aged, warm parchment paper; '
          'sepia, ochre and muted teal and burgundy accents; clear architectural perspective; '
          'framed like an old postcard with a thin inked border and slightly worn paper edges.',
    ),
    'paris_scene': ImageStyle(
      id: 'paris_scene',
      kind: 'scene',
      size: '1536x1024',
      background: 'opaque',
      text: '$_common Style: impressionist oil painting with thick, broken, mosaic-like impasto brushstrokes; '
          'golden late-afternoon sunlight with long shadows; honey, amber, umber and soft sky-blue palette; '
          'full-bleed composition with no border.',
    ),
    // STEP 3-12A: London's ink and watercolour, in Rome's light and colours;
    // full bleed, so it never reads as London's postcards.
    'rome_scene': ImageStyle(
      id: 'rome_scene',
      kind: 'scene',
      size: '1536x1024',
      background: 'opaque',
      text: '$_common Style: hand-drawn pen line drawing with soft watercolour washes on warm cream paper, lightly stylised rather than '
          'photographic, like a well-loved travel sketchbook; warm vintage Roman colours of terracotta, ochre, travertine cream, '
          'umbrella-pine green and soft sky blue; warm Mediterranean sunlight with gentle shadows; clear architectural perspective; '
          'full-bleed composition with no border.',
    ),
    'character': ImageStyle(
      id: 'character',
      kind: 'character',
      size: '1024x1536',
      background: 'opaque',
      text: '$_common Style: detailed ink linework with rich, slightly textured colour washes; one person, three-quarter view, '
          'from the head to below the waist, natural friendly expression; plain aged parchment background with no scenery.',
    ),
    'object': ImageStyle(
      id: 'object',
      kind: 'object',
      size: '1024x1024',
      background: 'opaque',
      text: '$_common Style: a single object drawn in detailed ink linework with colour washes and soft shading, '
          'centred with space around it, on plain aged parchment with no other objects.',
    ),
  };
}
