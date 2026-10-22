import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/letter_puzzles.dart';
import '../../../data/models/mission.dart';
import '../../../data/models/scene_explore.dart' show ScenePixels;
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import 'letter_papers.dart';
import 'mark_compare.dart' show WorkshopNote;
import 'river_papers.dart' show PictureCanvas;
import 'workshop_papers.dart';

/// The archive ([ArchiveScene]): the cabinet, its drawers' labels written
/// on their cards. A tap opens a drawer (kept: [onOpened]); one that does
/// not keep Letter 4417 says why and stays shut. The right one opens on its
/// three torn envelopes; a tap on one looks at it closer, where the corner
/// from Clock III is laid on it. The envelope it is laid on goes to
/// [onSubmit], checked as the puzzle's answer.
class ArchivePuzzle extends StatefulWidget {
  const ArchivePuzzle({super.key, required this.scene, required this.mission, required this.opened, required this.onOpened, required this.onSubmit});

  final ArchiveScene scene;
  final Mission mission;

  /// The drawers opened so far, by id.
  final Set<String> opened;
  final ValueChanged<String> onOpened;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<ArchivePuzzle> createState() => _ArchivePuzzleState();
}

class _ArchivePuzzleState extends State<ArchivePuzzle> {
  String? _refused;

  ArchiveScene get _scene => widget.scene;

  String get _right => _scene.drawers.keeping.single.id;

  void _open(CabinetDrawer d) {
    widget.onOpened(d.id);
    setState(() => _refused = d.id == _right ? null : d.id);
  }

  Future<void> _closer(DrawerEnvelope e, int number) async {
    final laid = await showEnvelopeCloser(context, scene: _scene, envelope: e, number: number);
    if (laid != null) await widget.onSubmit(laid);
  }

  Rect _fractions(Rect px, ScenePixels p) => Rect.fromLTRB(px.left / p.width, px.top / p.height, px.right / p.width, px.bottom / p.height);

  @override
  Widget build(BuildContext context) {
    final open = widget.opened.contains(_right);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The corner from Clock III, and its number: what to find.
        WorkshopNote(key: const ValueKey('corner-note'), intro: widget.mission.letterIntro, text: widget.mission.letter),
        const SizedBox(height: AppSpace.md),
        Text(open ? _scene.drawerTask : _scene.cabinetTask, key: const ValueKey('archive-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.md),
        DecoratedBox(
          decoration: BoxDecoration(boxShadow: AppShadow.paperLift, borderRadius: BorderRadius.circular(AppRadius.paper)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: open ? _drawer() : _cabinet(),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        if (!open)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: _refused == null
                ? const SizedBox.shrink()
                : GlossaryText(
                    _scene.refusalOf(_refused!),
                    key: const ValueKey('drawer-refused'),
                    textAlign: TextAlign.center,
                    style: AppText.bodyText(size: 17, color: AppColors.inkBrown, weight: FontWeight.w600),
                  ),
          ),
      ],
    );
  }

  Widget _cabinet() => Semantics(
    key: const ValueKey('cabinet'),
    label: 'An archive cabinet of four drawers, each with a label.',
    child: CroppedPicture(
      file: _scene.cabinet,
      pixels: _scene.cabinetPixels,
      crop: _fractions(_scene.cabinetView, _scene.cabinetPixels),
      child: Stack(
        children: [
          for (final d in _scene.cabinetDrawers) ...[
            Positioned.fromRect(
              rect: d.label,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${_scene.drawers.drawer(d.id).kind.word}S\n${_scene.drawers.drawer(d.id).from}–${_scene.drawers.drawer(d.id).to}',
                    key: ValueKey('drawer-label-${d.id}'),
                    textAlign: TextAlign.center,
                    style: postType(40),
                  ),
                ),
              ),
            ),
            if (widget.opened.contains(d.id) && d.id != _right)
              Positioned.fromRect(
                rect: d.area,
                child: IgnorePointer(child: ColoredBox(color: AppColors.navyDeep.withValues(alpha: 0.35))),
              ),
            Positioned.fromRect(
              rect: d.area,
              child: Semantics(
                button: true,
                label: 'The drawer labelled ${_scene.drawers.drawer(d.id).label}. Tap to open it.',
                excludeSemantics: true,
                child: GestureDetector(key: ValueKey('drawer-${d.id}'), behavior: HitTestBehavior.opaque, onTap: () => _open(d)),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _drawer() => Semantics(
    key: const ValueKey('open-drawer'),
    label: 'The open drawer, ${_scene.drawers.drawer(_right).label}: three torn envelopes on green felt.',
    child: CroppedPicture(
      file: _scene.drawer,
      pixels: _scene.drawerPixels,
      crop: _fractions(_scene.drawerView, _scene.drawerPixels),
      child: Stack(
        children: [
          for (final (i, e) in _scene.envelopes.indexed) ...[
            Positioned.fromRect(rect: e.inDrawer, child: EnvelopeView(key: ValueKey('drawer-envelope-${e.id}'), scene: _scene, envelope: e, number: i + 1)),
            Positioned.fromRect(
              rect: e.inDrawer.deflate(20),
              child: Semantics(
                button: true,
                label: 'Envelope ${i + 1}. Tap to look at its torn edge.',
                excludeSemantics: true,
                child: GestureDetector(key: ValueKey('envelope-${e.id}'), behavior: HitTestBehavior.opaque, onTap: () => _closer(e, i + 1)),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// An envelope up close, the corner from Clock III under it: dragged (or
/// laid by its button) onto it, the corner settles where it was torn from
/// on the envelope it fits, and the envelope's id is returned; on one it
/// does not fit, it slides back, and the envelope's id is returned too (the
/// answer it gives is checked, said why).
Future<String?> showEnvelopeCloser(BuildContext context, {required ArchiveScene scene, required DrawerEnvelope envelope, required int number}) {
  return Navigator.of(context).push<String>(
    PageRouteBuilder<String>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.94),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: _EnvelopeCloser(scene: scene, envelope: envelope, number: number),
      ),
    ),
  );
}

class _EnvelopeCloser extends StatefulWidget {
  const _EnvelopeCloser({required this.scene, required this.envelope, required this.number});

  final ArchiveScene scene;
  final DrawerEnvelope envelope;
  final int number;

  @override
  State<_EnvelopeCloser> createState() => _EnvelopeCloserState();
}

class _EnvelopeCloserState extends State<_EnvelopeCloser> with SingleTickerProviderStateMixin {
  /// Room under the envelope for the corner, in the envelopes' pixels.
  static const _gap = 40.0;

  late final AnimationController _slide = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  Animation<Offset>? _path;

  /// Where the corner's canvas is laid (pixels of the envelope's canvas;
  /// zero: where it was torn from).
  late Offset _at = _tray;
  bool _settled = false;
  bool _busy = false;
  String? _line;

  ArchiveScene get _scene => widget.scene;

  /// The corner's place under the envelope, its paper in the middle.
  Offset get _tray {
    final piece = _scene.cornerPiece;
    return Offset((_scene.envelopePixels.width - piece.width) / 2 - piece.left, _scene.envelopePixels.height + _gap - piece.top);
  }

  ScenePixels get _canvas => ScenePixels(_scene.envelopePixels.width, _scene.envelopePixels.height + _gap + _scene.cornerPiece.height + _gap);

  bool get _fits => _scene.drawers.fits(_scene.drawers.envelopes.firstWhere((e) => e.id == widget.envelope.id));

  Future<void> _glide(Offset to) async {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      setState(() => _at = to);
      return;
    }
    _path = Tween(begin: _at, end: to).animate(CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic))
      ..addListener(() => setState(() => _at = _path!.value));
    await _slide.forward(from: 0);
  }

  /// Laid on the envelope: it settles where it fits; otherwise it goes back.
  Future<void> _lay() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _glide(Offset.zero);
    if (!mounted) return;
    if (_fits) {
      setState(() {
        _settled = true;
        _line = null;
      });
      // Long enough to see the tag come off and the round spot under it.
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.of(context).pop(widget.envelope.id);
      return;
    }
    setState(() => _line = _scene.notFit);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await _glide(_tray);
    if (mounted) Navigator.of(context).pop(widget.envelope.id);
  }

  void _dragged(Offset delta) {
    if (_busy) return;
    setState(() => _at += delta);
  }

  /// Let go: near enough to where it would fit, it is laid there; anywhere
  /// else it goes back under the envelope.
  void _dropped() {
    if (_busy) return;
    if (_at.distance < 260) {
      _lay();
    } else {
      _glide(_tray);
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvas = _canvas;
    final env = _scene.envelopePixels;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ENVELOPE ${widget.number}', key: const ValueKey('envelope-title'), style: AppText.mark(color: AppColors.goldLight)),
                  const SizedBox(height: AppSpace.xs),
                  Text(_scene.layTask, textAlign: TextAlign.center, style: AppText.bodyText(size: 16, color: AppColors.paperLight)),
                  const SizedBox(height: AppSpace.md),
                  LayoutBuilder(
                    builder: (context, box) {
                      final width = math.min(box.maxWidth, MediaQuery.sizeOf(context).height * 0.62 * canvas.aspect);
                      // Screen points per pixel of the canvas.
                      final k = width / canvas.width;
                      return SizedBox(
                        width: width,
                        child: Semantics(
                          label: 'Envelope ${widget.number}, torn at its corner. Under it, the torn corner from Clock III.',
                          child: PictureCanvas(
                            key: ValueKey('envelope-close-${widget.envelope.id}'),
                            pixels: canvas,
                            child: Stack(
                              children: [
                                // Laid on the drawer's felt: where the corner meets
                                // the envelope, the felt shows along the tear.
                                Positioned(left: 0, top: 0, width: env.width, height: env.height, child: FeltBehind(scene: _scene)),
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  width: env.width,
                                  height: env.height,
                                  // Its number tag comes off once the corner fits.
                                  child: EnvelopeView(scene: _scene, envelope: widget.envelope, number: widget.number, tagged: !_settled),
                                ),
                                Positioned(
                                  left: _at.dx,
                                  top: _at.dy,
                                  width: env.width,
                                  height: env.height,
                                  child: IgnorePointer(child: CornerView(key: const ValueKey('torn-corner'), scene: _scene)),
                                ),
                                Positioned.fromRect(
                                  rect: _scene.cornerPiece.shift(_at),
                                  child: RawGestureDetector(
                                    key: const ValueKey('corner-drag'),
                                    behavior: HitTestBehavior.opaque,
                                    gestures: {
                                      ImmediateMultiDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<ImmediateMultiDragGestureRecognizer>(
                                        ImmediateMultiDragGestureRecognizer.new,
                                        (r) => r.onStart = (_) => _CornerDrag((d) => _dragged(d.delta / k), _dropped),
                                      ),
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpace.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 28),
                    child: Text(
                      _settled ? 'It fits!' : (_line ?? ''),
                      key: const ValueKey('envelope-line'),
                      textAlign: TextAlign.center,
                      style: AppText.title(size: 20, color: _settled ? AppColors.goldLight : AppColors.tryAgainSoft),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  GameButton(
                    key: const ValueKey('corner-lay'),
                    label: _scene.layLabel,
                    glyph: InkGlyph.puzzle,
                    style: GameButtonStyle.gold,
                    tap: TapRole.primary,
                    onPressed: _busy ? null : _lay,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  InkTextButton(
                    key: const ValueKey('envelope-done'),
                    label: 'BACK TO THE DRAWER',
                    color: AppColors.goldLight,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
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

/// The corner following a finger.
class _CornerDrag extends Drag {
  _CornerDrag(this.onUpdate, this.onDone);

  final ValueChanged<DragUpdateDetails> onUpdate;
  final VoidCallback onDone;

  @override
  void update(DragUpdateDetails details) => onUpdate(details);

  @override
  void end(DragEndDetails details) => onDone();

  @override
  void cancel() => onDone();
}

/// The envelope found, its corner back on it and the seal on it: the seal
/// is looked at closer before the story goes on ([onContinue]).
class EnvelopeFound extends StatelessWidget {
  const EnvelopeFound({super.key, required this.scene, required this.onContinue});

  final ArchiveScene scene;
  final VoidCallback onContinue;

  Future<void> _lookAtSeal(BuildContext context) async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: AppColors.navyDeep.withValues(alpha: 0.94),
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, anim, _) => FadeTransition(
          opacity: anim,
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('THE SEAL', style: AppText.mark(color: AppColors.goldLight)),
                        const SizedBox(height: AppSpace.md),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
                          child: Semantics(
                            image: true,
                            label: scene.sealLabel,
                            excludeSemantics: true,
                            child: PictureCanvas(
                              key: const ValueKey('seal-close'),
                              pixels: scene.sealPixels,
                              child: Image.asset(scene.seal, fit: BoxFit.fill, excludeFromSemantics: true),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                        GlossaryText(
                          scene.sealLine,
                          key: const ValueKey('seal-line'),
                          textAlign: TextAlign.center,
                          linkColor: AppColors.goldLight,
                          style: AppText.title(size: 21, color: AppColors.goldLight),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Builder(
                          builder: (context) => GameButton(
                            key: const ValueKey('seal-close-done'),
                            label: 'CONTINUE',
                            arrow: true,
                            style: GameButtonStyle.gold,
                            tap: TapRole.primary,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    onContinue();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('The corner fits. This is Letter 4417!', key: const ValueKey('envelope-found-line'), textAlign: TextAlign.center, style: AppText.title(size: 22)),
      const SizedBox(height: AppSpace.md),
      DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.paper), boxShadow: AppShadow.paperLift),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: Stack(
            children: [
              Positioned.fill(child: FeltBehind(scene: scene)),
              FittedEnvelopeView(key: const ValueKey('envelope-found'), fitted: scene.fitted),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpace.lg),
      GameButton(
        key: const ValueKey('envelope-seal-look'),
        label: 'LOOK AT THE SEAL',
        glyph: InkGlyph.search,
        tap: TapRole.primary,
        onPressed: () => _lookAtSeal(context),
      ),
    ],
  );
}

/// The drawer's felt ([ArchiveScene.felt]), covering its box: what an
/// envelope looked at closer lies on.
class FeltBehind extends StatelessWidget {
  const FeltBehind({super.key, required this.scene});

  final ArchiveScene scene;

  @override
  Widget build(BuildContext context) {
    final p = scene.drawerPixels;
    final f = scene.felt;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: f.width,
          height: f.height,
          child: CroppedPicture(file: scene.drawer, pixels: p, crop: Rect.fromLTRB(f.left / p.width, f.top / p.height, f.right / p.width, f.bottom / p.height)),
        ),
      ),
    );
  }
}

/// A torn envelope of the drawer with the archive's round number tag stuck
/// on it ([ArchiveScene.numberTag]: the same place on all three, over the
/// right one's seal spot). [tagged] false: the tag fades off, and what is
/// under it shows.
class EnvelopeView extends StatelessWidget {
  const EnvelopeView({super.key, required this.scene, required this.envelope, required this.number, this.tagged = true});

  final ArchiveScene scene;
  final DrawerEnvelope envelope;
  final int number;
  final bool tagged;

  @override
  Widget build(BuildContext context) => PictureCanvas(
    pixels: scene.envelopePixels,
    child: Stack(
      children: [
        Positioned.fill(child: Image.asset(envelope.file, fit: BoxFit.fill, excludeFromSemantics: true)),
        Positioned.fromRect(
          rect: scene.numberTag,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: tagged ? 1 : 0,
              duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : const Duration(milliseconds: 500),
              child: DecoratedBox(
                key: ValueKey('envelope-tag-${envelope.id}'),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.paperLight,
                  border: Border.all(color: AppColors.navy, width: 12),
                  boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Center(child: Text('$number', style: postType(140, color: AppColors.navy))),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
