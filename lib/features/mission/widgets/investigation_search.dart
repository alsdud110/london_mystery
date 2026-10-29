import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart';
import '../../../data/models/investigation.dart';
import '../../../widgets/art_assets.dart';
import '../../../widgets/detective_character.dart';
import '../../../widgets/detective_tips.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/landmark_art.dart';
import '../../../widgets/letter_card.dart';
import '../../../widgets/paper.dart';
import '../../../widgets/paper_background.dart';
import '../../../widgets/place_scenery.dart';
import '../../game/game_providers.dart';
import 'search_stage.dart';

// ---------------------------------------------------------------------------
// Arriving: the place in the dark, why the document is read, the document.
// ---------------------------------------------------------------------------

/// The arrival at a searched place: its picture fills the screen in the
/// dark, the [InvestigationScene.arrival] lines fade in, then the document
/// ([letter]) slides up and the search can start. About 1.4 s, with no
/// button to press on the way; a tap shows all of it at once. [instant]
/// (coming back to it) shows it whole.
class InvestigationArrival extends ConsumerStatefulWidget {
  const InvestigationArrival({
    super.key,
    required this.scene,
    required this.letter,
    required this.instant,
    required this.onArrived,
    required this.onStart,
  });

  final InvestigationScene scene;
  final String letter;
  final bool instant;

  /// Called once the document is on screen (so coming back shows it whole).
  final VoidCallback onArrived;
  final VoidCallback onStart;

  @override
  ConsumerState<InvestigationArrival> createState() => _InvestigationArrivalState();
}

class _InvestigationArrivalState extends ConsumerState<InvestigationArrival> with SingleTickerProviderStateMixin {
  static const duration = Duration(milliseconds: 1400);

  late final AnimationController _in = AnimationController(vsync: this, duration: duration)
    ..addListener(_onTick)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onArrived();
    });

  bool _rustled = false;

  /// Where the document starts coming up (fraction of the whole arrival).
  static const _documentFrom = 0.6;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_in.isAnimating || _in.isCompleted) return;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.instant || still) {
      _rustled = true;
      _in.value = 1;
      widget.onArrived();
    } else {
      _in.forward();
    }
  }

  void _onTick() {
    if (!_rustled && _in.value >= _documentFrom) {
      _rustled = true;
      ref.read(audioServiceProvider).play(GameSound.paperRustle);
    }
  }

  /// A tap during the arrival shows all of it.
  void _showAll() {
    if (_in.isCompleted) return;
    _rustled = true;
    _in.value = 1;
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  double _part(double from, double to) => Curves.easeOut.transform(((_in.value - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final lines = widget.scene.arrival;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.scene.artwork case final artwork?) PlaceScenery(artwork) else PlaceScenery.file(widget.scene.picture!),
        InkSurface(
          night: true,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _showAll,
            child: AnimatedBuilder(
              animation: _in,
              builder: (context, _) {
                final document = _part(_documentFrom, 1);
                // The lines and the document scroll; the button that starts
                // the search stays in sight under them.
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // The two lines read as one short scene: close
                            // together, then a breath before the report.
                            for (final (i, line) in lines.indexed)
                              Opacity(
                                opacity: _part(i * 0.25, i * 0.25 + 0.3),
                                child: Padding(
                                  padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpace.sm),
                                  child: GlossaryText(
                                    line,
                                    textAlign: TextAlign.center,
                                    linkColor: AppColors.goldLight,
                                    style: AppText.bodyText(size: 17, color: AppColors.paperLight),
                                  ),
                                ),
                              ),
                            const SizedBox(height: AppSpace.lg),
                            // The document comes up from below, a short way, as it is
                            // handed over.
                            Opacity(
                              opacity: document,
                              child: Transform.translate(
                                offset: Offset(0, 40 * (1 - document)),
                                child: LetterCard(key: const ValueKey('arrival-report'), text: widget.letter, textSize: 17, compact: true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.lg),
                      child: IgnorePointer(
                        key: const ValueKey('arrival-start'),
                        ignoring: document < 1,
                        child: Opacity(
                          opacity: document,
                          // The player's detective, glass up, sets out on the search.
                          child: WithPlayerDetective(
                            moment: DetectiveMoment.investigate,
                            child: GameButton(
                              label: widget.scene.startLabel,
                              style: GameButtonStyle.glass,
                              arrow: true,
                              singleLine: true, // beside the detective on a 360-wide phone
                              tap: TapRole.primary,
                              onPressed: widget.onStart,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Searching: the picture to look at closely, how to search, the report.
// ---------------------------------------------------------------------------

/// A place searched for the things its document names (see
/// [InvestigationScene]). The picture fills the screen and can be looked at
/// closely (pinch, drag, double tap); a tap on it investigates that spot.
/// Under it: what to find, how to search, the report and the tips.
///
/// A thing found is shown on its own card, then laid where it was found;
/// when the last one's card is closed, [onComplete] is called once with the
/// scene's answer (the mission's puzzle answer).
///
/// What was found lives in [found] and whether the "tap here" guide was
/// shown in [guideShown], both kept by the page that shows the search, so
/// reading the report or going back keeps them. They are not saved: after a
/// restart the search begins again (the mission itself is saved only when
/// it is solved, as for any puzzle).
class InvestigationSearch extends ConsumerStatefulWidget {
  const InvestigationSearch({
    super.key,
    required this.scene,
    required this.found,
    required this.onFound,
    required this.onComplete,
    required this.hints,
    required this.hintsShown,
    required this.onHint,
    required this.guideShown,
    required this.onGuideDone,
    this.onReport,
  });

  final InvestigationScene scene;

  /// Ids of the things already found, in the order they were found.
  final List<String> found;
  final ValueChanged<String> onFound;
  final ValueChanged<String> onComplete;

  /// The mission's tips, how many are open, and asking for the next one
  /// (true when one was opened).
  final List<String> hints;
  final int hintsShown;
  final Future<bool> Function() onHint;

  final bool guideShown;
  final VoidCallback onGuideDone;

  /// The report was opened (the page records it as reading it again).
  final VoidCallback? onReport;

  @override
  ConsumerState<InvestigationSearch> createState() => _InvestigationSearchState();
}

class _InvestigationSearchState extends ConsumerState<InvestigationSearch> with TickerProviderStateMixin {
  /// The pencilled slip over the picture: what the last tap found.
  String? _line;

  /// Taps in a row that found nothing new: after a few, a quiet nudge
  /// towards the report and the tips.
  int _misses = 0;

  /// Where the last tap landed (fractions of the picture), shown as a small
  /// ink ring that fades: the tap was seen.
  Offset? _tapAt;
  int _tapCount = 0;

  /// The thing whose card is open, if any, and whether it has settled (a
  /// quick second tap meant for the picture does not close it unseen).
  InvestigationFind? _card;
  bool _cardSettled = false;
  Timer? _cardTimer;

  bool _completed = false;

  /// Fingers on the picture: a pinch or a drag is looking, never a tap;
  /// nor is a tap just as one ends.
  bool _looking = false;
  bool _justLooked = false;
  Timer? _lookTimer;

  final _zoom = TransformationController();
  late final AnimationController _zoomMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  Animation<Matrix4>? _zoomTo;

  Offset? _doubleTapAt;

  /// The opening view ([InvestigationScene.opening] as large as the screen
  /// allows), worked out for [_homeViewport]; shown from the first frame
  /// it is known, until the detective moves the picture themselves.
  Matrix4 _home = Matrix4.identity();
  Size? _homeViewport;
  bool _homeShown = false;
  bool _moved = false;

  static const _nudgeAfter = 3;

  /// How far outside a place a tap still counts for it, in logical pixels
  /// on screen (shrinks in the picture as it is enlarged).
  static const slack = 12.0;

  /// A double tap enlarges the picture this much around the spot.
  static const doubleTapScale = 2.5;
  static const maxScale = 4.0;

  /// A card stays put this long before a tap may close it.
  static const cardSettle = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _zoomMotion.addListener(() {
      final to = _zoomTo;
      if (to != null) _zoom.value = to.value;
    });
    // Everything was found but the last card was left (back, while it was
    // open): the search is over, so it answers now, once.
    if (_allFound) {
      _completed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onComplete(widget.scene.answer);
      });
    }
  }

  @override
  void dispose() {
    _cardTimer?.cancel();
    _lookTimer?.cancel();
    _zoomMotion.dispose();
    _zoom.dispose();
    super.dispose();
  }

  bool get _allFound => widget.scene.finds.every((f) => widget.found.contains(f.id));

  void _guideDone() {
    if (!widget.guideShown) widget.onGuideDone();
  }

  /// A tap on the picture at [point] (fractions of the picture), whose
  /// on-screen size is [shown].
  void _tap(Offset point, Size shown) {
    if (_card != null || _completed || _looking || _justLooked) return;
    _guideDone();
    setState(() {
      _tapAt = point;
      _tapCount++;
    });
    _investigate(widget.scene.hit(point, slack: Size(slack / shown.width, slack / shown.height)));
  }

  void _investigate(Object? target) {
    if (_card != null || _completed) return;
    switch (target) {
      case InvestigationFind f when !widget.found.contains(f.id):
        ref.read(audioServiceProvider).play(GameSound.pencilNote);
        HapticFeedback.selectionClick();
        widget.onFound(f.id);
        setState(() {
          _misses = 0;
          _line = null;
          _card = f;
          _cardSettled = false;
        });
        _cardTimer?.cancel();
        _cardTimer = Timer(cardSettle, () => _cardSettled = true);
      case InvestigationFind f:
        setState(() => _line = 'You found ${f.name.toLowerCase()} here already.');
      case InvestigationSpot s:
        setState(() {
          _misses++;
          _line = s.line;
        });
      default:
        setState(() {
          _misses++;
          _line = widget.scene.missLine;
        });
    }
  }

  /// The find card is closed: back to the search, or, the last thing found,
  /// the answer (once).
  void _closeCard() {
    if (_card == null || !_cardSettled) return;
    final last = _allFound;
    setState(() {
      _card = null;
      if (last) _line = widget.scene.doneLine;
    });
    if (last && !_completed) {
      _completed = true;
      widget.onComplete(widget.scene.answer);
    }
  }

  // ── Looking closer ────────────────────────────────────────────────────

  void _zoomAnimated(Matrix4 to) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _zoom.value = to;
      return;
    }
    _zoomTo = Matrix4Tween(
      begin: _zoom.value,
      end: to,
    ).animate(CurvedAnimation(parent: _zoomMotion, curve: Curves.easeOut));
    _zoomMotion.forward(from: 0);
  }

  /// Where the picture sits for a screen [width] wide.
  SearchFrame _frame(double width) => SearchFrame(
    width: width,
    aspect: widget.scene.pixels?.aspect ?? ArtAssets.sceneAspect(widget.scene.artwork!),
    inside: widget.scene.inside,
    focus: widget.scene.opening,
    maxScale: maxScale,
  );

  /// A double tap at [at] (in the viewer's own space, [viewport] big):
  /// closer around that spot, or back to the opening view.
  void _doubleTap(Offset at, SearchFrame frame, Size viewport) {
    if (_card != null || _completed) return;
    _guideDone();
    _moved = true;
    final home = _home.getMaxScaleOnAxis();
    if (_zoom.value.getMaxScaleOnAxis() > home + 0.05) {
      _zoomAnimated(_home);
      return;
    }
    final s = math.max(doubleTapScale, home + 0.5).clamp(1.0, maxScale);
    // Keep the spot under the finger, never past the picture's edges.
    final onScreen = MatrixUtils.transformPoint(_zoom.value, at);
    _zoomAnimated(frame.view(s, at, onScreen, viewport));
  }

  // ── The report ────────────────────────────────────────────────────────

  Future<void> _openReport() async {
    widget.onReport?.call();
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    await showInvestigationReport(
      context,
      scene: widget.scene,
      found: widget.found,
      hints: widget.hints,
      hintsShown: widget.hintsShown,
    );
  }

  /// A hint opened is written in the panel under the picture (the search
  /// stays as it is; the report lists it too).
  Future<void> _askTip() => widget.onHint();

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final card = _card;
    return Stack(
      children: [
        SearchStage(
          idealHeight: (width) => _frame(width).idealHeight,
          picture: (context, viewport) {
                    final frame = _frame(viewport.width);
                    final size = frame.picture;
                    final origin = frame.origin;
                    // The opening view, for this screen (again if the screen
                    // changes before the picture was moved); once moved, the
                    // view stays where it was, still covering the screen
                    // (a hint opened makes the picture's place shorter).
                    if (_homeViewport != viewport) {
                      _homeViewport = viewport;
                      _home = frame.home(viewport);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _zoomMotion.stop();
                        _zoom.value = _moved ? frame.keep(_zoom.value, viewport) : _home;
                        if (!_homeShown) setState(() => _homeShown = true);
                      });
                    }
                    return Opacity(
                          // Hidden for the one frame before the opening view is set.
                          opacity: _homeShown ? 1 : 0,
                          child: Listener(
                          onPointerDown: (_) => _guideDone(),
                          child: InteractiveViewer(
                            transformationController: _zoom,
                            // The room inside its paper edge, never smaller
                            // than the screen: no band around it, ever.
                            constrained: false,
                            minScale: frame.minScale(viewport),
                            maxScale: maxScale,
                            boundaryMargin: EdgeInsets.zero,
                            onInteractionStart: (d) {
                              _moved = true;
                              _zoomMotion.stop();
                              if (d.pointerCount > 1) setState(() => _looking = true);
                            },
                            onInteractionUpdate: (d) {
                              if (!_looking && (d.pointerCount > 1 || d.focalPointDelta.distance > 2)) {
                                setState(() => _looking = true);
                              }
                            },
                            onInteractionEnd: (_) {
                              if (!_looking) return;
                              setState(() {
                                _looking = false;
                                _justLooked = true;
                              });
                              _lookTimer?.cancel();
                              _lookTimer = Timer(const Duration(milliseconds: 120), () => _justLooked = false);
                            },
                            child: SizedBox.fromSize(
                              size: frame.content,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: origin.dx,
                                    top: origin.dy,
                                    width: size.width,
                                    height: size.height,
                                    child: _SearchPicture(
                                      key: const ValueKey('investigation-picture'),
                                      scene: scene,
                                      found: widget.found,
                                      tapAt: _tapAt,
                                      tapCount: _tapCount,
                                      guide: !widget.guideShown && !still,
                                      onGuideEnd: _guideDone,
                                      onTap: (point) => _tap(point, size * _zoom.value.getMaxScaleOnAxis()),
                                      onDoubleTapDown: (local) => _doubleTapAt = origin + local,
                                      onDoubleTap: () => _doubleTap(
                                        _doubleTapAt ?? frame.focusRect.center,
                                        frame,
                                        viewport,
                                      ),
                                      onSpot: _investigate,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        );
          },
          caption: _SearchCaption(scene: scene),
          // What the last tap found, pencilled on a slip.
          note: PencilSlip(
            line: _line,
            nudge: !_allFound && _misses >= _nudgeAfter ? 'Stuck? Read the report again, or get a hint.' : null,
          ),
          actions: _SearchActions(
            scene: scene,
            tipLabel: nextTipLabel(widget.hints, widget.hintsShown),
            hints: widget.hints,
            hintsShown: widget.hintsShown,
            onReport: _openReport,
            onTip: _askTip,
          ),
        ),
        if (card != null)
          Positioned.fill(
            child: _FindCard(
              key: ValueKey('find-card-${card.id}'),
              find: card,
              last: _allFound,
              still: still,
              onClose: _closeCard,
            ),
          ),
      ],
    );
  }
}

/// The picture searched, with what was found laid where it was, the first
/// "tap here" guide, and an invisible button on every listed place for
/// screen readers. Its taps are in fractions of the picture, wherever it
/// is enlarged or moved to (the viewer's transform is undone by hit
/// testing).
class _SearchPicture extends StatelessWidget {
  const _SearchPicture({
    super.key,
    required this.scene,
    required this.found,
    required this.tapAt,
    required this.tapCount,
    required this.guide,
    required this.onGuideEnd,
    required this.onTap,
    required this.onDoubleTapDown,
    required this.onDoubleTap,
    required this.onSpot,
  });

  final InvestigationScene scene;
  final List<String> found;
  final Offset? tapAt;
  final int tapCount;
  final bool guide;
  final VoidCallback onGuideEnd;
  final ValueChanged<Offset> onTap;
  final ValueChanged<Offset> onDoubleTapDown;
  final VoidCallback onDoubleTap;
  final ValueChanged<Object> onSpot;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        Rect place(Rect r) =>
            Rect.fromLTRB(r.left * size.width, r.top * size.height, r.right * size.width, r.bottom * size.height);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => onTap(Offset(d.localPosition.dx / size.width, d.localPosition.dy / size.height)),
          onDoubleTapDown: (d) => onDoubleTapDown(d.localPosition),
          onDoubleTap: onDoubleTap,
          // The room inside the print's own paper edge.
          child: ClipRect(
            clipper: _Inside(scene.inside),
            child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: switch (scene.artwork) {
                  final artwork? => LandmarkArt(artwork, borderRadius: 2),
                  // A season's own room: its file, laid on the frame its
                  // places are measured on (fractions of the whole file).
                  null => Image.asset(scene.picture!, fit: BoxFit.fill, excludeFromSemantics: true),
                },
              ),
              for (final f in scene.finds)
                if (found.contains(f.id))
                  _FoundThing(key: ValueKey('found-${f.id}'), find: f, size: size, still: still),
              if (tapAt != null)
                Positioned(
                  left: tapAt!.dx * size.width - 22,
                  top: tapAt!.dy * size.height - 22,
                  child: SearchTapRing(key: ValueKey('tap-$tapCount'), still: still),
                ),
              if (guide)
                Positioned(
                  left: scene.guideAt.dx * size.width - TapGuide.size / 2,
                  top: scene.guideAt.dy * size.height - TapGuide.size / 2,
                  child: TapGuide(key: const ValueKey('tap-guide'), onEnd: onGuideEnd),
                ),
              // Screen readers: one button per place (a tap on the picture
              // itself reaches the same places by position).
              for (final f in scene.finds)
                for (final r in f.areas.take(1))
                  Positioned.fromRect(
                    rect: place(r),
                    child: Semantics(
                      button: true,
                      label: found.contains(f.id) ? '${f.spot}: ${f.name.toLowerCase()}, found' : f.spot,
                      onTap: () => onSpot(f),
                      child: const SizedBox.expand(),
                    ),
                  ),
              for (final s in scene.spots)
                Positioned.fromRect(
                  rect: place(s.areas.first),
                  child: Semantics(
                    button: true,
                    label: s.label,
                    onTap: () => onSpot(s),
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
          ),
        );
      },
    );
  }
}

/// Clips a picture to [inside] (fractions of its size).
class _Inside extends CustomClipper<Rect> {
  const _Inside(this.inside);

  final Rect inside;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(inside.left * size.width, inside.top * size.height, inside.right * size.width, inside.bottom * size.height);

  @override
  bool shouldReclip(_Inside oldClipper) => oldClipper.inside != inside;
}

/// How to search, shown once as the search opens: a fingertip tapping the
/// picture (rings going out twice), then fading. Over an empty spot of the
/// room, never a thing. Gone at the first touch.
class TapGuide extends StatefulWidget {
  const TapGuide({super.key, required this.onEnd});

  static const size = 88.0;
  static const duration = Duration(milliseconds: 1800);

  final VoidCallback onEnd;

  @override
  State<TapGuide> createState() => _TapGuideState();
}

class _TapGuideState extends State<TapGuide> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: TapGuide.duration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onEnd();
    })
    ..forward();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: TapGuide.size,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final v = _t.value;
            // Fades out over the last quarter.
            final fade = v < 0.75 ? 1.0 : 1 - (v - 0.75) / 0.25;
            return Opacity(
              opacity: fade,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final start in const [0.0, 0.4])
                    if (v >= start)
                      Builder(
                        builder: (context) {
                          final r = ((v - start) / 0.45).clamp(0.0, 1.0);
                          return Container(
                            width: 20 + 60 * r,
                            height: 20 + 60 * r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.goldLight.withValues(alpha: 1 - r),
                                width: AppLine.ink,
                              ),
                            ),
                          );
                        },
                      ),
                  // The fingertip.
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.paperLight.withValues(alpha: 0.9),
                      border: Border.all(color: AppColors.goldDeep, width: AppLine.rule),
                      boxShadow: [BoxShadow(color: AppColors.navyDeep.withValues(alpha: 0.4), blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A found thing, laid where it was found, ringed in gold ink so it stays
/// easy to see.
class _FoundThing extends StatelessWidget {
  const _FoundThing({super.key, required this.find, required this.size, required this.still});

  final InvestigationFind find;
  final Size size;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final w = find.width * size.width;
    final h = w / find.pictureAspect * find.squash;
    // The ring: around the thing as it lies, never smaller than a fingertip.
    final ring = (w > h ? w : h).clamp(36.0, double.infinity) + 10;
    final centre = Offset(find.at.dx * size.width, find.at.dy * size.height);
    return Positioned(
      left: centre.dx - ring / 2,
      top: centre.dy - ring / 2,
      width: ring,
      height: ring,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: still ? 1 : 0, end: 1),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: find.turn,
                child: SizedBox(
                  width: w,
                  height: w / find.pictureAspect,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(1, find.squash, 1),
                    child: Image.asset(
                      find.picture,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.goldLight, width: AppLine.ink),
                  boxShadow: [BoxShadow(color: AppColors.navyDeep.withValues(alpha: 0.35), blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small ink ring where the finger landed, fading at once.
class SearchTapRing extends StatelessWidget {
  const SearchTapRing({super.key, required this.still});

  final bool still;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: still ? Duration.zero : const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        builder: (context, t, _) => Opacity(
          opacity: still ? 0 : (1 - t) * 0.85,
          child: Transform.scale(
            scale: 0.6 + 0.4 * t,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.paperLight, width: AppLine.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The detective's pencilled slip over the room: what the last tap found
/// (read aloud by screen readers as it changes). Nothing before the first
/// tap; each line goes after [shown], leaving the picture clear again.
class PencilSlip extends StatefulWidget {
  const PencilSlip({super.key, required this.line, this.nudge});

  final String? line;
  final String? nudge;

  /// How long a line stays on the picture.
  static const shown = Duration(milliseconds: 2500);

  @override
  State<PencilSlip> createState() => _PencilSlipState();
}

class _PencilSlipState extends State<PencilSlip> {
  Timer? _timer;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(PencilSlip old) {
    super.didUpdateWidget(old);
    if (old.line != widget.line || old.nudge != widget.nudge) {
      _gone = false;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    if (widget.line == null) return;
    _timer = Timer(PencilSlip.shown, () {
      if (mounted) setState(() => _gone = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _gone ? null : widget.line;
    final nudge = widget.nudge;
    return Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: text == null
            ? const SizedBox.shrink(key: ValueKey('no-slip'))
            : Center(
                key: ValueKey('$text|$nudge'),
                child: PaperSheet(
                  tilt: -0.006,
                  padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text,
                        textAlign: TextAlign.center,
                        style: AppText.letter(size: 16, color: AppColors.inkBrown),
                      ),
                      if (nudge != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          nudge,
                          textAlign: TextAlign.center,
                          style: AppText.caption(color: AppColors.goldDeep),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Under the picture, read with it: what to find, how to search (the main
/// line: tap the picture) and how to look closer.
class _SearchCaption extends StatelessWidget {
  const _SearchCaption({required this.scene});

  final InvestigationScene scene;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlossaryText(scene.task, textAlign: TextAlign.center, style: AppText.title(size: 19)),
          const SizedBox(height: AppSpace.sm),
          // The main line: the glass sits with the words, also when they wrap.
          Text.rich(
            TextSpan(
              children: [
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.only(right: AppSpace.sm),
                    child: InkIcon(InkGlyph.search, size: AppIconSize.small, color: AppColors.burgundy),
                  ),
                ),
                TextSpan(text: scene.tapGuide),
              ],
            ),
            key: const ValueKey('tap-guide-line'),
            textAlign: TextAlign.center,
            style: AppText.bodyText(size: 17, weight: FontWeight.w700, color: AppColors.burgundy),
          ),
          const SizedBox(height: 2),
          Text(scene.zoomGuide, textAlign: TextAlign.center, style: AppText.caption()),
        ],
      ),
    );
  }
}

/// At the bottom of the page, in reach of the thumb: the hints opened so
/// far, then the report and the tips.
class _SearchActions extends StatelessWidget {
  const _SearchActions({
    required this.scene,
    required this.tipLabel,
    required this.hints,
    required this.hintsShown,
    required this.onReport,
    required this.onTip,
  });

  final InvestigationScene scene;
  final String? tipLabel;

  /// The hints opened so far: written above the links, in a short strip
  /// that scrolls (the picture keeps most of the screen).
  final List<String> hints;
  final int hintsShown;
  final VoidCallback onReport;
  final VoidCallback onTip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('search-panel'),
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.2),
            child: SingleChildScrollView(
              key: const ValueKey('search-hints'),
              child: DetectiveTipNotes(hints: hints, revealed: hintsShown, compact: true),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.sm,
            children: [
              InkTextButton(label: scene.documentLabel, glyph: InkGlyph.letter, onPressed: onReport),
              if (tipLabel != null)
                InkTextButton(label: tipLabel!, glyph: InkGlyph.hint, color: tipLinkColor, onPressed: onTip),
            ],
          ),
        ],
      ),
    );
  }
}

/// A thing just found, on its own card over the room: its picture, large,
/// its name and how it was found. Not the case's evidence yet (no XP, no
/// coins: the mission's Discovery says those); a tap goes back to the room.
///
/// The card is laid square in the middle, at most [maxWidth] wide and never
/// nearer the screen's edges than [margin], so its whole edge always shows;
/// when the screen is short, the words scroll inside it.
class _FindCard extends StatelessWidget {
  const _FindCard({super.key, required this.find, required this.last, required this.still, required this.onClose});

  final InvestigationFind find;
  final bool last;
  final bool still;
  final VoidCallback onClose;

  static const maxWidth = 320.0;
  static const margin = AppSpace.xl;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Semantics(
        button: true,
        label: '${find.title}. ${find.foundLine} ${last ? 'Continue' : 'Keep searching'}',
        excludeSemantics: true,
        onTap: onClose,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: ColoredBox(
            color: AppColors.navyDeep.withValues(alpha: 0.72),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(margin),
                child: LayoutBuilder(
                  builder: (context, box) {
                    // The picture keeps most of the card on a tall screen and
                    // gives way on a short one.
                    final picture = (box.maxHeight * 0.3).clamp(96.0, 150.0);
                    return Center(
                      child: ConstrainedBox(
                        key: const ValueKey('find-sheet'),
                        constraints: BoxConstraints(maxWidth: math.min(maxWidth, box.maxWidth), maxHeight: box.maxHeight),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: still ? 1 : 0, end: 1),
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                          builder: (context, t, child) => Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
                          child: PaperSheet(
                            ruled: true,
                            padding: EdgeInsets.zero,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('FOUND', style: AppText.eyebrow()),
                                  const SizedBox(height: AppSpace.xs),
                                  SizedBox(
                                    height: picture,
                                    child: Image.asset(
                                      find.picture,
                                      fit: BoxFit.contain,
                                      excludeFromSemantics: true,
                                      errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.sm),
                                  Text(find.title, textAlign: TextAlign.center, style: AppText.placeTitle(size: 26)),
                                  const SizedBox(height: AppSpace.xs),
                                  const OrnamentRule(),
                                  const SizedBox(height: AppSpace.sm),
                                  Text(find.foundLine, textAlign: TextAlign.center, style: AppText.letter(size: 18)),
                                  const SizedBox(height: AppSpace.md),
                                  Text(
                                    last ? 'Tap to continue' : 'Tap to keep searching',
                                    textAlign: TextAlign.center,
                                    style: AppText.caption(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The report, opened when needed.
// ---------------------------------------------------------------------------

/// The search's document lines (each ticked once its thing is found) and
/// the tips opened so far, on a paper sheet over the room. Closing it
/// changes nothing.
Future<void> showInvestigationReport(
  BuildContext context, {
  required InvestigationScene scene,
  required List<String> found,
  required List<String> hints,
  required int hintsShown,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: paperSheetShape,
    showDragHandle: false,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: SingleChildScrollView(
          key: const ValueKey('investigation-report'),
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaperSheetTab(),
              InvestigationProgress(scene: scene, found: found),
              const SizedBox(height: AppSpace.lg),
              DetectiveTipNotes(hints: hints, revealed: hintsShown),
              GameButton(label: 'BACK TO THE SEARCH', onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The document's lines, each ticked once its thing is found, and how many
/// are found.
class InvestigationProgress extends StatelessWidget {
  const InvestigationProgress({super.key, required this.scene, required this.found});

  final InvestigationScene scene;
  final List<String> found;

  @override
  Widget build(BuildContext context) {
    final count = scene.finds.where((f) => found.contains(f.id)).length;
    return PaperSheet(
      ruled: true,
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(scene.documentTitle, style: AppText.eyebrow())),
              Semantics(
                label: 'Found $count of ${scene.finds.length}',
                excludeSemantics: true,
                child: Text(foundCountLabel(count, scene.finds.length), style: AppText.mark(size: 14)),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          for (final f in scene.finds)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: _ReportLine(find: f, found: found.contains(f.id)),
            ),
        ],
      ),
    );
  }
}

/// How many things are found, as the search writes it ("FOUND 1 / 3").
String foundCountLabel(int found, int of) => 'FOUND $found / $of';

class _ReportLine extends StatelessWidget {
  const _ReportLine({required this.find, required this.found});

  final InvestigationFind find;
  final bool found;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: found ? 'Found' : 'Not found yet',
          excludeSemantics: true,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: found ? AppColors.success : Colors.transparent,
              border: Border.all(color: found ? AppColors.success : AppLine.faint(0.4), width: AppLine.rule),
            ),
            child: found ? const InkIcon(InkGlyph.check, size: AppIconSize.tiny, color: AppColors.paperLight) : null,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: GlossaryText(
            find.reportLine,
            style: AppText.letter(size: 17, color: found ? AppColors.muted : AppColors.inkBrown),
          ),
        ),
      ],
    );
  }
}
