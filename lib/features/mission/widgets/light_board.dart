import 'dart:math' as math;
import 'dart:ui' as ui;

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
import 'workshop_papers.dart' show handwriting;

/// The stage with the lights [on]: the dark stage, and each light's own
/// picture of it laid over it lighter-only (so two lights on show both, and
/// no picture hides another). A light comes up and goes down softly (at
/// once with Reduce Motion).
class LitStage extends StatefulWidget {
  const LitStage({super.key, required this.base, required this.lit, required this.pixels, required this.on, this.label});

  final String base;
  final Map<StageLight, String> lit;
  final ScenePixels pixels;
  final Set<StageLight> on;

  /// What it shows, for screen readers (null: the lights on are said).
  final String? label;

  @override
  State<LitStage> createState() => _LitStageState();
}

class _LitStageState extends State<LitStage> with TickerProviderStateMixin {
  late final Map<StageLight, AnimationController> _fade = {
    for (final l in widget.lit.keys)
      l: AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: widget.on.contains(l) ? 1 : 0),
  };
  final Map<String, ui.Image> _images = {};
  final List<(ImageStream, ImageStreamListener)> _streams = [];
  int? _decodedWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decoded no wider than the screen needs (never wider than drawn).
    final width = math.min(widget.pixels.width, MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).ceil();
    if (_decodedWidth == width) return;
    _decodedWidth = width;
    _stop();
    final config = createLocalImageConfiguration(context);
    for (final file in [widget.base, ...widget.lit.values]) {
      final stream = ResizeImage(AssetImage(file), width: width).resolve(config);
      final listener = ImageStreamListener((info, _) {
        if (mounted) setState(() => _images[file] = info.image);
      });
      stream.addListener(listener);
      _streams.add((stream, listener));
    }
  }

  void _stop() {
    for (final (s, l) in _streams) {
      s.removeListener(l);
    }
    _streams.clear();
  }

  @override
  void didUpdateWidget(LitStage old) {
    super.didUpdateWidget(old);
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    for (final MapEntry(key: l, value: c) in _fade.entries) {
      final on = widget.on.contains(l);
      if (still) {
        c.value = on ? 1 : 0;
      } else if (on) {
        c.forward();
      } else {
        c.reverse();
      }
    }
  }

  @override
  void dispose() {
    _stop();
    for (final c in _fade.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final names = [for (final l in StageLight.values) if (widget.on.contains(l)) l.label.toLowerCase()];
    return Semantics(
      image: true,
      label: widget.label ?? (names.isEmpty ? 'The stage, every light off: all dark.' : 'The stage with ${names.join(', ')} on.'),
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: widget.pixels.aspect,
        child: RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('lit-stage'),
            painter: _LitPainter(
              base: _images[widget.base],
              layers: [for (final MapEntry(key: l, value: file) in widget.lit.entries) (_images[file], _fade[l]!)],
              repaint: Listenable.merge(_fade.values.toList()),
            ),
          ),
        ),
      ),
    );
  }
}

class _LitPainter extends CustomPainter {
  _LitPainter({required this.base, required this.layers, required Listenable repaint}) : super(repaint: repaint);

  final ui.Image? base;
  final List<(ui.Image?, Animation<double>)> layers;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Offset.zero & size;
    final base = this.base;
    if (base == null) {
      canvas.drawRect(dst, Paint()..color = AppColors.nightBottom);
      return;
    }
    Rect src(ui.Image i) => Rect.fromLTWH(0, 0, i.width.toDouble(), i.height.toDouble());
    canvas.saveLayer(dst, Paint());
    canvas.drawImageRect(base, src(base), dst, Paint()..filterQuality = FilterQuality.medium);
    for (final (image, t) in layers) {
      if (image == null || t.value <= 0) continue;
      canvas.drawImageRect(
        image,
        src(image),
        dst,
        Paint()
          ..blendMode = BlendMode.lighten
          ..filterQuality = FilterQuality.medium
          ..color = Color.fromRGBO(0, 0, 0, t.value),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LitPainter old) => old.base != base || [for (final (i, _) in old.layers) i].join() != [for (final (i, _) in layers) i].join();
}

/// M2, the lighting desk ([LightBoardScene]): the old photo and the
/// Lighting Book (a tap looks closer at either), the stage as the levers
/// light it, and the desk's four levers (a tap, or a slide up or down;
/// their names under them). The check sends what the stage says against the
/// photo ([LightBoard.verdict]) as the answer.
class LightBoardPuzzle extends StatefulWidget {
  const LightBoardPuzzle({super.key, required this.scene, required this.mission, required this.onPhoto, required this.onSubmit});

  final LightBoardScene scene;
  final Mission mission;

  /// The photo looked at closer (saved).
  final VoidCallback onPhoto;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<LightBoardPuzzle> createState() => _LightBoardPuzzleState();
}

class _LightBoardPuzzleState extends State<LightBoardPuzzle> {
  Set<StageLight> _on = {};
  bool _checking = false;

  void _set(StageLight l, bool on) {
    if (_on.contains(l) == on) return;
    setState(() => _on = on ? {..._on, l} : ({..._on}..remove(l)));
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await widget.onSubmit(widget.scene.board.verdict(_on));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _photo() {
    widget.onPhoto();
    final scene = widget.scene;
    showOperaCloser<void>(
      context,
      title: 'THE OLD PHOTO',
      closeLabel: 'BACK TO THE DESK',
      closeKey: const ValueKey('photo-done'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhotoPrintView(key: const ValueKey('photo-close'), photo: scene.photo),
          const SizedBox(height: AppSpace.md),
          Text('YOUR STAGE NOW', style: AppText.eyebrow(color: AppColors.goldLight)),
          const SizedBox(height: AppSpace.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: LitStage(key: const ValueKey('photo-compare-stage'), base: scene.stage, lit: scene.lit, pixels: scene.stagePixels, on: _on),
          ),
        ],
      ),
    );
  }

  void _book() => showOperaCloser<void>(
    context,
    title: widget.scene.book.title,
    closeLabel: 'BACK TO THE DESK',
    closeKey: const ValueKey('book-done'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LightingBookView(key: const ValueKey('book-close'), book: widget.scene.book),
        const SizedBox(height: AppSpace.md),
        // What the pages say, large enough to read without a pinch.
        _BookWords(book: widget.scene.book),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Tile(
                key: const ValueKey('old-photo'),
                label: 'THE OLD PHOTO',
                semantics: 'The old photo, marked ${scene.photo.caption} Tap to look closer and compare.',
                onTap: _photo,
                child: PhotoPrintView(photo: scene.photo),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: _Tile(
                key: const ValueKey('lighting-book'),
                label: scene.book.title,
                semantics: '${scene.book.title}. Tap to read it.',
                onTap: _book,
                child: AspectRatio(
                  aspectRatio: scene.book.pixels.aspect,
                  child: Image.asset(scene.book.file, fit: BoxFit.contain, excludeFromSemantics: true),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: LitStage(base: scene.stage, lit: scene.lit, pixels: scene.stagePixels, on: _on),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(scene.task, key: const ValueKey('desk-task'), textAlign: TextAlign.center, style: AppText.caption()),
        const SizedBox(height: AppSpace.xs),
        _Desk(scene: scene, on: _on, onSet: _set),
        const SizedBox(height: AppSpace.md),
        GameButton(
          key: const ValueKey('lights-check'),
          label: scene.checkLabel,
          glyph: InkGlyph.check,
          tap: TapRole.primary,
          singleLine: true,
          onPressed: _checking ? null : _check,
        ),
      ],
    );
  }
}

/// A small picture to look at closer, its name under it.
class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.label, required this.semantics, required this.onTap, required this.child});

  final String label;
  final String semantics;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantics,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          child,
          const SizedBox(height: 2),
          // The lens sits on the name's first line, wherever it wraps.
          Text.rich(
            TextSpan(
              children: [
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(padding: EdgeInsets.only(right: 4), child: InkIcon(InkGlyph.search, size: AppIconSize.tiny, color: AppColors.goldDeep)),
                ),
                TextSpan(text: label),
              ],
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            style: AppText.eyebrow(),
          ),
        ],
      ),
    ),
  );
}

/// The lighting desk: four levers in their slots (up: ON), their names on
/// the plates and, readable, under the desk. A tap on a lever's column
/// flips it; a slide up turns it on, down off.
class _Desk extends StatelessWidget {
  const _Desk({required this.scene, required this.on, required this.onSet});

  final LightBoardScene scene;
  final Set<StageLight> on;
  final void Function(StageLight light, bool on) onSet;

  @override
  Widget build(BuildContext context) {
    final paper = scene.deskPaper;
    final still = MediaQuery.disableAnimationsOf(context);
    final lever = scene.leverPaper;
    // The lever drawn 250 desk pixels tall, its shaft on the slot's middle:
    // up, its knob stands above the slot; down, it sits low in it.
    final k = 250 / lever.height;
    final leverX = (lever.left + lever.right) / 2;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        double screenX(double deskX) => (deskX - paper.left) / paper.width * width;
        final column = (scene.slots[1].slot.center.dx - scene.slots[0].slot.center.dx) / paper.width * width;
        final desk = Column(
          children: [
            PixelCrop(
              pixels: scene.deskPixels,
              crop: paper,
              child: Stack(
                children: [
                  Positioned.fill(child: Image.asset(scene.desk, fit: BoxFit.fill, excludeFromSemantics: true)),
                  for (final s in scene.slots) ...[
                    // Its slot glows warm when the light is on.
                    Positioned.fromRect(
                      rect: s.slot.inflate(6),
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: on.contains(s.light) ? 1 : 0,
                          duration: still ? Duration.zero : const Duration(milliseconds: 220),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: const Color(0x66FFC25A),
                              boxShadow: const [BoxShadow(color: Color(0xAAFFC25A), blurRadius: 40, spreadRadius: 6)],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Its little enamel plate: lit from behind when on, dim
                    // when off (its name is on the brass plaque under the
                    // desk, large enough to read: never twice).
                    Positioned.fromRect(
                      rect: s.plate.deflate(4),
                      child: IgnorePointer(
                        child: AnimatedContainer(
                          key: ValueKey('plate-${s.light.name}-${on.contains(s.light) ? 'on' : 'off'}'),
                          duration: still ? Duration.zero : const Duration(milliseconds: 220),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: on.contains(s.light) ? const Color(0x77FFD27A) : const Color(0x73000000),
                          ),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      key: ValueKey('lever-${s.light.name}'),
                      duration: still ? Duration.zero : const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      left: s.slot.center.dx - leverX * k,
                      top: (on.contains(s.light) ? s.slot.top - 120 : s.slot.bottom + 40 - lever.height * k) - lever.top * k,
                      width: scene.leverPixels.width * k,
                      height: scene.leverPixels.height * k,
                      child: IgnorePointer(child: Image.asset(scene.lever, fit: BoxFit.fill, excludeFromSemantics: true)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 2),
            // Under each lever, its brass plaque: its name, and ON or OFF
            // (the plaque lit when on), one for each lever.
            SizedBox(
              height: 62,
              child: Stack(
                children: [
                  for (final s in scene.slots)
                    Positioned(
                      left: screenX(s.slot.center.dx) - column / 2 + 3,
                      width: column - 6,
                      top: 0,
                      bottom: 0,
                      child: ExcludeSemantics(child: _Plaque(light: s.light, on: on.contains(s.light), still: still)),
                    ),
                ],
              ),
            ),
          ],
        );
        // Each lever's whole column (the desk down to its name) is one
        // target.
        return Stack(
          children: [
            desk,
            for (final s in scene.slots)
              Positioned(
                left: screenX(s.slot.center.dx) - column / 2,
                width: column,
                top: 0,
                bottom: 0,
                child: _LeverTarget(slot: s, on: on.contains(s.light), onSet: onSet),
              ),
          ],
        );
      },
    );
  }
}

class _LeverTarget extends StatelessWidget {
  const _LeverTarget({required this.slot, required this.on, required this.onSet});

  final DeskSlot slot;
  final bool on;
  final void Function(StageLight light, bool on) onSet;

  @override
  Widget build(BuildContext context) {
    final s = slot;
    return Semantics(
      button: true,
      toggled: on,
      label: s.light.label,
      hint: on ? 'Tap to turn it off.' : 'Tap to turn it on.',
      child: GestureDetector(
        key: ValueKey('lever-tap-${s.light.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onSet(s.light, !on),
        onVerticalDragUpdate: (d) {
          if (d.delta.dy.abs() > 2) onSet(s.light, d.delta.dy < 0);
        },
      ),
    );
  }
}

/// A lever's brass plaque under the desk: its name in two short lines and
/// its state; lit warm when on, dark brass when off.
class _Plaque extends StatelessWidget {
  const _Plaque({required this.light, required this.on, required this.still});

  final StageLight light;
  final bool on;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final name = light.label.replaceAll(' ', '\n').replaceFirst('FOOTLIGHTS', 'FOOT-\nLIGHTS');
    return AnimatedContainer(
      duration: still ? Duration.zero : const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: on ? const [Color(0xFFF0D99A), Color(0xFFC9A55E)] : const [Color(0xFF5A4330), Color(0xFF3A291E)],
        ),
        border: Border.all(color: on ? AppColors.goldDeep : const Color(0xFF8A6A3E), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1.5))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: AppText.style(AppText.body, size: 11.5, weight: FontWeight.w800, color: on ? AppColors.navyDeep : AppColors.creamGold, height: 1.05, letterSpacing: 0.4),
              ),
            ),
          ),
          Text(
            on ? 'ON' : 'OFF',
            key: ValueKey('lever-state-${light.name}'),
            style: AppText.style(AppText.body, size: 11.5, weight: FontWeight.w800, color: on ? AppColors.burgundy : AppColors.parchmentDark, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }
}

/// What the Lighting Book says, in large print under its pages.
class _BookWords extends StatelessWidget {
  const _BookWords({required this.book});

  final LightingBook book;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('book-words'),
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(color: AppColors.paperLight, borderRadius: BorderRadius.circular(AppRadius.paper)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, (name, lines)) in book.entries.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpace.sm),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$name: ', style: AppText.bodyText(size: 16, weight: FontWeight.w800, color: AppColors.navy)),
                TextSpan(text: lines.join(' '), style: AppText.bodyText(size: 16, color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

/// The Lighting Book open: what it says of each light, on its two pages.
class LightingBookView extends StatelessWidget {
  const LightingBookView({super.key, required this.book});

  final LightingBook book;

  @override
  Widget build(BuildContext context) {
    final [first, ...rest] = book.entries;
    Widget entry((String, List<String>) e) => Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${e.$1}:', style: postType(58, color: AppColors.navyDeep)),
          for (final l in e.$2) Text(l, style: handwriting(58)),
        ],
      ),
    );
    return Semantics(
      image: true,
      label: '${book.title}. ${[for (final (n, ls) in book.entries) '$n: ${ls.join(' ')}'].join(' ')}',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: book.pixels.aspect,
        child: FittedBox(
          fit: BoxFit.fill,
          child: MediaQuery.withNoTextScaling(
            child: SizedBox(
              width: book.pixels.width,
              height: book.pixels.height,
              child: Stack(
                children: [
                  Positioned.fill(child: Image.asset(book.file, fit: BoxFit.fill, excludeFromSemantics: true)),
                  Positioned.fromRect(
                    rect: book.left,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: book.left.width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: Text(book.title, textAlign: TextAlign.center, style: AppText.style(AppText.display, size: 62, color: AppColors.burgundy))),
                            const SizedBox(height: 30),
                            entry(first),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: book.right,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: book.right.width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [const SizedBox(height: 90), for (final e in rest) entry(e)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The stage matches the photo: the Lighting Book open at show No. 34's
/// page, the cue card on it (a tap reads it: [onCue]) and, once it is
/// read, a scrap tucked in the book (a tap looks at it: [onScrap]). Then
/// on.
class CueFound extends StatelessWidget {
  const CueFound({
    super.key,
    required this.scene,
    required this.mission,
    required this.cueRead,
    required this.scrapFound,
    required this.onCue,
    required this.onScrap,
    required this.onContinue,
  });

  final LightBoardScene scene;
  final Mission mission;
  final bool cueRead;
  final bool scrapFound;
  final VoidCallback onCue;
  final VoidCallback onScrap;
  final VoidCallback onContinue;

  Future<void> _readCue(BuildContext context) async {
    onCue();
    await showOperaCloser<void>(
      context,
      title: 'THE STAGE CUE CARD',
      line: 'Kept at the lighting desk, not in the office. The stage cue says 4:00.',
      closeLabel: 'BACK TO THE BOOK',
      closeKey: const ValueKey('cue-done'),
      child: CueCardView(key: const ValueKey('cue-close'), card: scene.cue),
    );
  }

  Future<void> _lookAtScrap(BuildContext context) async {
    onScrap();
    await showOperaCloser<void>(
      context,
      title: 'A SCRAP OF PAPER',
      line: scene.scrapLine,
      closeLabel: 'BACK TO THE BOOK',
      closeKey: const ValueKey('scrap-done'),
      maxWidth: 360,
      child: AspectRatio(aspectRatio: 1, child: Image.asset(scene.scrap, key: const ValueKey('scrap-close'), fit: BoxFit.contain, excludeFromSemantics: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = scene.book;
    final still = MediaQuery.disableAnimationsOf(context);
    final task = !cueRead
        ? 'Tap the cue card to read it.'
        : !scrapFound
        ? 'Something is tucked in the book. Tap it.'
        : 'The stage cue says 4:00.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(mission.successMessage, textAlign: TextAlign.center, style: AppText.title(size: 24)),
        const SizedBox(height: AppSpace.xs),
        Text(scene.emptyLine, key: const ValueKey('empty-line'), textAlign: TextAlign.center, style: AppText.aside(size: 16, color: AppColors.inkBrown)),
        const SizedBox(height: AppSpace.md),
        Text(task, key: const ValueKey('cue-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.sm),
        DecoratedBox(
          decoration: const BoxDecoration(boxShadow: AppShadow.paperLift),
          child: PixelCrop(
            pixels: book.pixels,
            crop: const Rect.fromLTRB(60, 40, 1480, 990),
            child: Stack(
              children: [
                Positioned.fill(child: Image.asset(book.file, fit: BoxFit.fill, excludeFromSemantics: true)),
                Positioned.fromRect(
                  rect: book.left,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: Column(
                      key: const ValueKey('book-page-34'),
                      children: [
                        Text(scene.pageTitle.first, style: AppText.style(AppText.display, size: 74, color: AppColors.burgundy)),
                        const SizedBox(height: 16),
                        for (final t in scene.pageTitle.skip(1)) Text(t, style: postType(40, color: AppColors.walnutDeep)),
                      ],
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: scene.cueOnPage,
                  child: Semantics(
                    button: true,
                    label: 'The stage cue card for show No. 34. Tap to read it.',
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: const ValueKey('cue-card'),
                      onTap: () => _readCue(context),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CueCardView(card: scene.cue),
                          if (!cueRead) const _Glow(),
                        ],
                      ),
                    ),
                  ),
                ),
                if (cueRead)
                  Positioned.fromRect(
                    rect: scene.scrapAt,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: still ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 450),
                      builder: (context, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 40 * (1 - t)), child: child)),
                      child: Semantics(
                        button: true,
                        label: 'A small scrap of paper tucked in the book. Tap to look at it.',
                        excludeSemantics: true,
                        child: GestureDetector(
                          key: const ValueKey('scrap'),
                          onTap: () => _lookAtScrap(context),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(scene.scrap, fit: BoxFit.contain, excludeFromSemantics: true),
                              if (!scrapFound) const _Glow(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        AnimatedOpacity(
          opacity: cueRead && scrapFound ? 1 : 0,
          duration: still ? Duration.zero : const Duration(milliseconds: 300),
          child: GameButton(
            key: const ValueKey('cue-continue'),
            label: 'CONTINUE',
            arrow: true,
            tap: TapRole.primary,
            onPressed: cueRead && scrapFound ? onContinue : null,
          ),
        ),
      ],
    );
  }
}

/// A soft gold ring round what to tap next (still with Reduce Motion).
class _Glow extends StatefulWidget {
  const _Glow();

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
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
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      // A soft gold light round it, breathing (no hard frame on the paper).
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.35 + 0.45 * _c.value), width: 7),
        ),
      ),
    ),
  );
}
