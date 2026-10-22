import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/opera_puzzles.dart';
import '../../../data/models/scene_explore.dart' show ScenePixels;
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'letter_papers.dart' show postType;
import 'opera_papers.dart';

/// [rect] of a picture ([file], [pixels] big) drawn where it is in it, over
/// what is drawn under (pixels of the picture).
class _PicturePart extends StatelessWidget {
  const _PicturePart({required this.file, required this.pixels, required this.rect});

  final String file;
  final ScenePixels pixels;
  final Rect rect;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
    rect: rect,
    child: IgnorePointer(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -rect.left,
            top: -rect.top,
            width: pixels.width,
            height: pixels.height,
            child: Image.asset(file, fit: BoxFit.fill, excludeFromSemantics: true),
          ),
        ],
      ),
    ),
  );
}

/// M3, the rope rail ([FlyRailScene]): the Painted Street from the
/// notebook, the stage, and the rail's four ropes. A rope pulled (a tap, or
/// a pull down) lowers its backdrop onto the stage, the one down before
/// going back up (lowered once, it counts as looked at: [onLowered]). A tap
/// on the backdrop looks at it closer; THIS ONE! sends it as the answer.
class FlyRailPuzzle extends StatefulWidget {
  const FlyRailPuzzle({super.key, required this.scene, required this.mission, required this.lowered, required this.onLowered, required this.onSubmit});

  final FlyRailScene scene;
  final Mission mission;

  /// The backdrops lowered before, by id.
  final Set<String> lowered;
  final ValueChanged<String> onLowered;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<FlyRailPuzzle> createState() => _FlyRailPuzzleState();
}

class _FlyRailPuzzleState extends State<FlyRailPuzzle> with SingleTickerProviderStateMixin {
  /// 0: up in the flies; 1: down on the stage.
  late final AnimationController _drop = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  /// The backdrop on its way down or down, and the rope pulled for it.
  String? _down;
  bool _checking = false;

  /// A backdrop on its way up or down: another pull waits for it.
  bool _moving = false;

  /// The rope last pulled (its backdrop named while it comes down).
  String? _pulled;

  bool get _still => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  Future<void> _pull(int rope) async {
    final id = widget.scene.rail.ropes[rope].id;
    if (_down == id || _moving) return;
    // The rope pulled is named at once (the one down still going up).
    setState(() {
      _moving = true;
      _pulled = id;
    });
    try {
      await _lower(id);
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  Future<void> _lower(String id) async {
    if (_down != null && _drop.value > 0) {
      // The one down goes back up first.
      if (_still) {
        _drop.value = 0;
      } else {
        await _drop.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeInCubic);
      }
    }
    if (!mounted) return;
    setState(() => _down = id);
    widget.onLowered(id);
    if (_still) {
      _drop.value = 1;
    } else {
      await _drop.animateTo(1, curve: Curves.easeOutCubic);
    }
  }

  Future<void> _choose() async {
    final id = _down;
    if (id == null || _checking) return;
    setState(() => _checking = true);
    try {
      await widget.onSubmit(id);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  int _numberOf(String id) => widget.scene.rail.ropes.indexWhere((b) => b.id == id) + 1;

  Future<void> _closer() async {
    final id = _down;
    if (id == null) return;
    final scene = widget.scene;
    final art = scene.art(id);
    final chosen = await showOperaCloser<bool>(
      context,
      title: 'BACKDROP ${_numberOf(id)}',
      closeLabel: 'BACK TO THE ROPES',
      closeKey: const ValueKey('backdrop-done'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            image: true,
            label: art.label,
            excludeSemantics: true,
            child: AspectRatio(
              aspectRatio: scene.backdropPixels.aspect,
              child: Image.asset(art.file, key: ValueKey('backdrop-close-$id'), fit: BoxFit.contain, excludeFromSemantics: true),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text('THE DOOR, CLOSER', style: AppText.eyebrow(color: AppColors.goldLight)),
          const SizedBox(height: AppSpace.xs),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.paper),
              child: PixelCrop(
                key: const ValueKey('backdrop-door'),
                pixels: scene.backdropPixels,
                crop: scene.closer,
                child: Image.asset(art.file, fit: BoxFit.fill, excludeFromSemantics: true),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Builder(
          builder: (context) => GameButton(
            key: const ValueKey('backdrop-choose-close'),
            label: scene.chooseLabel,
            glyph: InkGlyph.check,
            style: GameButtonStyle.gold,
            tap: TapRole.primary,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
      ],
    );
    if (chosen == true && mounted) await _choose();
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final down = _down;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PaintedStreet(scene: scene),
        const SizedBox(height: AppSpace.md),
        _Stage(scene: scene, down: down, drop: _drop, onTap: _closer),
        const SizedBox(height: AppSpace.xs),
        Text(
          (_pulled ?? down) == null ? scene.task : 'BACKDROP ${_numberOf((_pulled ?? down)!)} · Tap it to look closer.',
          key: const ValueKey('rail-task'),
          textAlign: TextAlign.center,
          style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy),
        ),
        const SizedBox(height: AppSpace.sm),
        _Rail(scene: scene, down: down, drop: _drop, lowered: widget.lowered, onPull: _pull),
        const SizedBox(height: AppSpace.md),
        GameButton(
          key: const ValueKey('backdrop-choose'),
          label: scene.chooseLabel,
          glyph: InkGlyph.check,
          tap: TapRole.primary,
          onPressed: down == null || _checking ? null : _choose,
        ),
      ],
    );
  }
}

/// The Painted Street as the notebook has it: the red door and the small
/// clock above it, in Case 02's painting, beside its words.
class _PaintedStreet extends StatelessWidget {
  const _PaintedStreet({required this.scene});

  final FlyRailScene scene;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('painted-street-clue'),
    padding: const EdgeInsets.all(AppSpace.sm),
    decoration: BoxDecoration(
      color: AppColors.paperLight,
      border: Border.all(color: AppLine.faint(0.25), width: AppLine.hairline),
      borderRadius: BorderRadius.circular(AppRadius.paper),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 64,
          child: ExcludeSemantics(
            child: PixelCrop(
              pixels: scene.cluePixels,
              crop: scene.clueCrop,
              child: Image.asset(scene.clueFile, fit: BoxFit.fill, excludeFromSemantics: true),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR NOTEBOOK · THE PAINTED STREET', style: AppText.eyebrow()),
              const SizedBox(height: AppSpace.xs),
              Text(scene.clueLine, style: AppText.bodyText(size: 17, weight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// The stage, seen from the hall: the backdrop pulled comes down between
/// the curtains. A tap on it looks at it closer.
class _Stage extends StatelessWidget {
  const _Stage({required this.scene, required this.down, required this.drop, required this.onTap});

  final FlyRailScene scene;
  final String? down;
  final Animation<double> drop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final o = scene.opening;
    final canvas = scene.canvas;
    // The backdrop's canvas as wide as the opening.
    final k = o.width / canvas.width;
    final width = scene.backdropPixels.width * k;
    final height = scene.backdropPixels.height * k;
    final down = this.down;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.paper),
      child: PixelCrop(
        key: const ValueKey('rail-stage'),
        pixels: scene.stagePixels,
        crop: scene.stageView,
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(scene.stage, fit: BoxFit.fill, excludeFromSemantics: true)),
            if (down != null)
              Positioned.fromRect(
                rect: o,
                child: Semantics(
                  button: true,
                  label: '${scene.art(down).label}. Tap to look closer.',
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: const ValueKey('backdrop-down'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: ClipRect(
                      child: AnimatedBuilder(
                        animation: drop,
                        builder: (context, child) => Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned(
                              left: -canvas.left * k,
                              top: -(1 - drop.value) * (height + 20),
                              width: width,
                              height: height,
                              child: child!,
                            ),
                          ],
                        ),
                        child: Image.asset(scene.art(down).file, key: ValueKey('backdrop-$down'), fit: BoxFit.fill, excludeFromSemantics: true),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The rope rail: a rope through each lock, its number on the card above;
/// a tick on the card once its backdrop has been down. A rope's whole
/// column is its target: a tap, or a pull down.
class _Rail extends StatelessWidget {
  const _Rail({required this.scene, required this.down, required this.drop, required this.lowered, required this.onPull});

  final FlyRailScene scene;
  final String? down;
  final Animation<double> drop;
  final Set<String> lowered;
  final ValueChanged<int> onPull;

  @override
  Widget build(BuildContext context) {
    final rail = scene.railPixels;
    final view = scene.railView;
    final (left, right) = scene.ropeStrand;
    // The rope drawn 44 rail pixels thick; its picture repeats down.
    final k = 44 / (right - left);
    final ropeWidth = scene.ropePixels.width * k;
    final tile = scene.ropePixels.height * k;
    final strand = (left + right) / 2 * k;
    final columns = scene.ropeX.length;
    final columnWidth = view.width / columns;
    return LayoutBuilder(
      builder: (context, box) {
        final screen = box.maxWidth / view.width;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: Stack(
            children: [
              PixelCrop(
                key: const ValueKey('rope-rail'),
                pixels: rail,
                crop: view,
                child: Stack(
                  children: [
                    Positioned.fill(child: Image.asset(scene.railFile, fit: BoxFit.fill, excludeFromSemantics: true)),
                    for (final (i, x) in scene.ropeX.indexed)
                      // The rope of the backdrop down is pulled: it runs down.
                      AnimatedBuilder(
                        animation: drop,
                        builder: (context, _) {
                          final pulled = down == scene.rail.ropes[i].id ? drop.value : 0.0;
                          final shift = (pulled * tile * 0.6) % tile;
                          return Positioned(
                            left: x - strand,
                            top: 0,
                            width: ropeWidth,
                            height: rail.height,
                            child: IgnorePointer(
                              child: ClipRect(
                                child: Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    for (var y = shift - tile; y < rail.height; y += tile)
                                      Positioned(left: 0, top: y, width: ropeWidth, height: tile, child: Image.asset(scene.rope, fit: BoxFit.fill, excludeFromSemantics: true)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    // The locks and the card plates in front of the ropes.
                    for (final x in scene.ropeX) _PicturePart(file: scene.railFile, pixels: rail, rect: Rect.fromLTRB(x - 78, scene.lockTop, x + 78, 690)),
                    for (final plate in scene.plates) _PicturePart(file: scene.railFile, pixels: rail, rect: plate.inflate(6)),
                    for (final (i, plate) in scene.plates.indexed)
                      Positioned.fromRect(
                        rect: plate.deflate(6),
                        child: IgnorePointer(
                          child: FittedBox(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${i + 1}', key: ValueKey('rope-number-${i + 1}'), style: postType(44, color: AppColors.walnutDeep)),
                                if (lowered.contains(scene.rail.ropes[i].id)) ...[
                                  const SizedBox(width: 8),
                                  const InkIcon(InkGlyph.check, size: 34, color: AppColors.success),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (final (i, x) in scene.ropeX.indexed)
                Positioned(
                  left: (x - view.left - columnWidth / 2) * screen,
                  width: columnWidth * screen,
                  top: 0,
                  bottom: 0,
                  child: Semantics(
                    button: true,
                    selected: down == scene.rail.ropes[i].id,
                    label: 'Rope ${i + 1}${lowered.contains(scene.rail.ropes[i].id) ? ', its backdrop seen before' : ''}. Pull it to lower its backdrop.',
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: ValueKey('rope-${i + 1}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onPull(i),
                      // A pull down, as a rope is pulled.
                      onVerticalDragUpdate: (d) {
                        if (d.delta.dy > 2) onPull(i);
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The right backdrop is chosen: its back, from backstage. A tap on its
/// pocket takes out the paper in it (the Amendment Slip); then on.
class PocketFound extends StatelessWidget {
  const PocketFound({super.key, required this.scene, required this.mission, required this.open, required this.onOpen, required this.onContinue});

  final FlyRailScene scene;
  final Mission mission;
  final bool open;
  final VoidCallback onOpen;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(open ? mission.successMessage : 'BEHIND THE BACKDROP', textAlign: TextAlign.center, style: AppText.title(size: 24)),
        const SizedBox(height: AppSpace.xs),
        Text(
          open ? 'In the pocket: an old slip of paper.' : scene.pocketTask,
          key: const ValueKey('pocket-task'),
          textAlign: TextAlign.center,
          style: AppText.subtitle(),
        ),
        const SizedBox(height: AppSpace.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: PixelCrop(
            key: const ValueKey('backdrop-back'),
            pixels: scene.backPixels,
            crop: Offset.zero & Size(scene.backPixels.width, scene.backPixels.height),
            child: Stack(
              children: [
                Positioned.fill(child: Image.asset(scene.back, fit: BoxFit.fill, excludeFromSemantics: true)),
                Positioned.fromRect(
                  rect: scene.pocket.inflate(30),
                  child: Semantics(
                    button: true,
                    label: 'A canvas pocket sewn on the back of the backdrop. Tap to look inside.',
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: const ValueKey('pocket'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onOpen,
                      child: open ? const SizedBox.expand() : const _Ring(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (open) ...[
          const SizedBox(height: AppSpace.md),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: still ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, -30 * (1 - t)), child: child)),
            child: DecoratedBox(
              decoration: const BoxDecoration(boxShadow: AppShadow.paperLift),
              child: AmendmentSlipView(key: const ValueKey('pocket-slip'), slip: scene.slip),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text('A round stamp: a clock with no hands, in a ring of leaves. No name.', textAlign: TextAlign.center, style: AppText.aside(size: 15, color: AppColors.inkBrown)),
          const SizedBox(height: AppSpace.lg),
          GameButton(key: const ValueKey('pocket-continue'), label: 'CONTINUE', arrow: true, tap: TapRole.primary, onPressed: onContinue),
        ],
      ],
    );
  }
}

/// A gold ring round the pocket (still with Reduce Motion).
class _Ring extends StatefulWidget {
  const _Ring();

  @override
  State<_Ring> createState() => _RingState();
}

class _RingState extends State<_Ring> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c
        ..stop()
        ..value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    // A soft gold light round the pocket, breathing (no hard frame).
    builder: (context, _) => DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.3 + 0.4 * _c.value), width: 6),
      ),
    ),
  );
}
