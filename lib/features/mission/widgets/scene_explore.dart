import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart';
import '../../../data/models/investigation.dart' show InvestigationSpot;
import '../../../data/models/mission.dart';
import '../../../data/models/scene_explore.dart';
import '../../../widgets/detective_tips.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/letter_card.dart';
import '../../../widgets/paper.dart';
import '../../../widgets/paper_background.dart';
import '../../game/game_providers.dart';
import 'investigation_search.dart' show PencilSlip, SearchTapRing, TapGuide;
import 'question_widgets.dart' show ShakeOnChange;

/// A place looked round ([ExploreScene]): its picture fills the screen and
/// can be looked at closer (pinch, drag); a tap on it looks at that spot.
/// The things worth a look carry a small glass, a tick once looked at.
///
/// The mission's document is read where it was left (sealed the first
/// time, open after); a note is said on its card; the choice opens its own
/// page, where the detective picks a picture and [onChoose] checks it as
/// the puzzle's answer. Looking is never a wrong answer.
///
/// What was looked at lives in [progress], kept by the page that shows it
/// ([onChanged] after each change), so going back keeps it. Not saved.
class SceneExplore extends ConsumerStatefulWidget {
  const SceneExplore({
    super.key,
    required this.scene,
    required this.mission,
    required this.progress,
    required this.onChanged,
    required this.onChoose,
    required this.onReread,
    required this.onDocumentAgain,
    required this.hintsShown,
    required this.onHint,
    required this.wrongPulse,
  });

  final ExploreScene scene;
  final Mission mission;
  final ExploreProgress progress;
  final VoidCallback onChanged;

  /// Checks the picture chosen (an option id) as the puzzle's answer.
  final Future<void> Function(String optionId) onChoose;

  /// The document opened again from the choice page (the page records it).
  final VoidCallback onReread;

  /// The document, already read, opened again where it is (the page
  /// records it as reading it again, as the choice page's).
  final VoidCallback onDocumentAgain;

  final int hintsShown;
  final Future<bool> Function() onHint;

  /// Bumped by the page on a wrong answer: the pictures shake.
  final int wrongPulse;

  @override
  ConsumerState<SceneExplore> createState() => _SceneExploreState();
}

class _SceneExploreState extends ConsumerState<SceneExplore> with TickerProviderStateMixin {
  /// The pencilled slip over the picture: what the last tap found.
  String? _line;

  /// Where the last tap landed (fractions of the picture), and a count so
  /// each tap rings anew.
  Offset? _tapAt;
  int _tapCount = 0;

  final _zoom = TransformationController();
  Matrix4 _home = Matrix4.identity();
  Size? _homeViewport;
  bool _homeShown = false;
  bool _moved = false;

  /// How far outside a place a tap still counts for it, in logical pixels
  /// on screen.
  static const slack = 14.0;
  static const maxScale = 3.0;

  ExploreProgress get _p => widget.progress;
  ExploreScene get _scene => widget.scene;

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _guideDone() {
    if (_p.guideShown) return;
    _p.guideShown = true;
    widget.onChanged();
  }

  void _tap(Offset point, Size shown) {
    if (_p.open != null) return;
    _guideDone();
    setState(() {
      _tapAt = point;
      _tapCount++;
    });
    _look(_scene.hit(point, slack: Size(slack / shown.width, slack / shown.height)));
  }

  void _look(Object? target) {
    if (_p.open != null) return;
    switch (target) {
      case ExploreSpot s:
        _open(s);
      case InvestigationSpot o:
        setState(() => _line = o.line);
      default:
        setState(() => _line = _scene.missLine);
    }
  }

  /// Looks at [s]: its card or its page, or what it still needs.
  void _open(ExploreSpot s) {
    if (!_p.canOpen(_scene, s)) {
      final first = s.requires == null ? null : _scene.spot(s.requires!);
      final unread = first != null && _p.hasLooked(first.id) && first.kind == ExploreKind.document;
      setState(() => _line = unread && s.unreadLine.isNotEmpty ? s.unreadLine : s.lockedLine);
      return;
    }
    if (s.kind == ExploreKind.document && _p.documentOpened) widget.onDocumentAgain();
    final audio = ref.read(audioServiceProvider);
    audio.play(s.kind == ExploreKind.choice ? GameSound.paperRustle : GameSound.pencilNote);
    HapticFeedback.selectionClick();
    _p.looked.add(s.id);
    _p.open = s.id;
    _line = null;
    widget.onChanged();
  }

  void _close() {
    if (_p.open == null) return;
    _p.open = null;
    widget.onChanged();
  }

  /// The opening view: the scene's [ExploreScene.opening] filling as much
  /// of the [viewport] as it can, never smaller than the whole picture
  /// ([size] at [origin]).
  Matrix4 _homeFor(Size viewport, Size size, Offset origin) {
    final o = _scene.opening;
    final s = math
        .min(viewport.width / (size.width * o.width), viewport.height / (size.height * o.height))
        .clamp(1.0, maxScale);
    final centre = origin + Offset(o.center.dx * size.width, o.center.dy * size.height);
    final onScreen = viewport.center(Offset.zero);
    final dx = (onScreen.dx - s * centre.dx).clamp(-(s - 1) * viewport.width, 0.0);
    final dy = (onScreen.dy - s * centre.dy).clamp(-(s - 1) * viewport.height, 0.0);
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final open = _p.open == null ? null : scene.spot(_p.open!);
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final viewport = box.biggest;
                    final aspect = scene.pixels.aspect;
                    var w = viewport.width;
                    var h = w / aspect;
                    if (h > viewport.height) {
                      h = viewport.height;
                      w = h * aspect;
                    }
                    final origin = Offset((viewport.width - w) / 2, (viewport.height - h) / 2);
                    if (!_moved && _homeViewport != viewport) {
                      _homeViewport = viewport;
                      _home = _homeFor(viewport, Size(w, h), origin);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted || _moved) return;
                        _zoom.value = _home;
                        setState(() => _homeShown = true);
                      });
                    }
                    return Stack(
                      children: [
                        // The station itself, dim, all around the picture.
                        Positioned.fill(
                          child: ExcludeSemantics(
                            child: Opacity(
                              opacity: 0.35,
                              child: Image.asset(scene.picture, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        Positioned.fill(child: ColoredBox(color: AppColors.navyDeep.withValues(alpha: 0.55))),
                        Opacity(
                          opacity: _homeShown ? 1 : 0,
                          child: InteractiveViewer(
                            transformationController: _zoom,
                            minScale: 1,
                            maxScale: maxScale,
                            boundaryMargin: EdgeInsets.zero,
                            onInteractionStart: (_) {
                              _moved = true;
                              _guideDone();
                            },
                            child: SizedBox.fromSize(
                              size: viewport,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: origin.dx,
                                    top: origin.dy,
                                    width: w,
                                    height: h,
                                    child: _ExplorePicture(
                                      key: const ValueKey('explore-picture'),
                                      scene: scene,
                                      progress: _p,
                                      tapAt: _tapAt,
                                      tapCount: _tapCount,
                                      guide: !_p.guideShown && !still,
                                      onGuideEnd: _guideDone,
                                      onTap: (point) {
                                        final s = _zoom.value.getMaxScaleOnAxis();
                                        _tap(point, Size(w * s, h * s));
                                      },
                                      onSpot: _look,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: AppSpace.md,
                          right: AppSpace.md,
                          top: AppSpace.sm,
                          child: IgnorePointer(child: PencilSlip(line: _line)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            ExplorePanel(
              task: _p.documentOpened ? scene.nextTask : scene.task,
              tapGuide: scene.tapGuide,
              zoomGuide: scene.zoomGuide,
              hints: widget.mission.hints,
              hintsShown: widget.hintsShown,
              documentLabel: _p.documentOpened ? scene.documentLabel : null,
              onDocument: () {
                final doc = scene.document;
                if (doc != null) _open(doc);
              },
              onTip: widget.onHint,
            ),
          ],
        ),
        if (open != null)
          Positioned.fill(
            child: switch (open.kind) {
              ExploreKind.document => _DocumentCard(
                key: ValueKey('explore-card-${open.id}'),
                spot: open,
                mission: widget.mission,
                opened: _p.documentOpened,
                still: still,
                onOpening: () => ref.read(audioServiceProvider).play(GameSound.envelopeOpen),
                onOpened: () {
                  _p.documentOpened = true;
                  widget.onChanged();
                },
                onClose: _close,
              ),
              ExploreKind.note => _NoteCard(
                key: ValueKey('explore-card-${open.id}'),
                spot: open,
                still: still,
                onClose: _close,
              ),
              ExploreKind.choice => _ChoicePage(
                key: ValueKey('explore-card-${open.id}'),
                scene: scene,
                mission: widget.mission,
                progress: _p,
                wrongPulse: widget.wrongPulse,
                onChanged: widget.onChanged,
                onChoose: widget.onChoose,
                onReread: widget.onReread,
                hintsShown: widget.hintsShown,
                onHint: widget.onHint,
                onClose: _close,
              ),
            },
          ),
      ],
    );
  }
}

/// The picture looked round, with a small glass on each thing worth a look
/// (a tick once looked at), the first "tap here" rings, and an invisible
/// button on every listed place for screen readers. Its taps are in
/// fractions of the picture, wherever it is enlarged or moved to.
class _ExplorePicture extends StatelessWidget {
  const _ExplorePicture({
    super.key,
    required this.scene,
    required this.progress,
    required this.tapAt,
    required this.tapCount,
    required this.guide,
    required this.onGuideEnd,
    required this.onTap,
    required this.onSpot,
  });

  final ExploreScene scene;
  final ExploreProgress progress;
  final Offset? tapAt;
  final int tapCount;
  final bool guide;
  final VoidCallback onGuideEnd;
  final ValueChanged<Offset> onTap;
  final ValueChanged<Object> onSpot;

  static const markSize = 30.0;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        Rect place(Rect r) =>
            Rect.fromLTRB(r.left * size.width, r.top * size.height, r.right * size.width, r.bottom * size.height);
        final inside = place(scene.inside);
        return Semantics(
          label: scene.place,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onTap(Offset(d.localPosition.dx / size.width, d.localPosition.dy / size.height)),
            child: ClipRect(
              clipper: _InsideClip(inside),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: Image.asset(scene.picture, fit: BoxFit.fill, excludeFromSemantics: true),
                  ),
                  for (final s in scene.spots)
                    Positioned(
                      left: s.mark.dx * size.width - markSize / 2,
                      top: s.mark.dy * size.height - markSize / 2,
                      child: LookMark(key: ValueKey('mark-${s.id}'), looked: progress.hasLooked(s.id)),
                    ),
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
                  for (final s in scene.spots)
                    Positioned.fromRect(
                      rect: place(s.areas.first),
                      child: Semantics(
                        button: true,
                        label: progress.hasLooked(s.id) ? '${s.label}, looked at' : s.label,
                        onTap: () => onSpot(s),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  for (final o in scene.others)
                    Positioned.fromRect(
                      rect: place(o.areas.first),
                      child: Semantics(
                        button: true,
                        label: o.label,
                        onTap: () => onSpot(o),
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InsideClip extends CustomClipper<Rect> {
  const _InsideClip(this.inside);

  final Rect inside;

  @override
  Rect getClip(Size size) => inside;

  @override
  bool shouldReclip(_InsideClip old) => old.inside != inside;
}

/// The small glass on a thing worth a look: a paper disc ringed in gold, a
/// tick in gold once looked at. Still: it marks, it never calls.
class LookMark extends StatelessWidget {
  const LookMark({super.key, required this.looked});

  final bool looked;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: _ExplorePicture.markSize,
        height: _ExplorePicture.markSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: looked ? AppColors.gold : AppColors.paperLight.withValues(alpha: 0.92),
          border: Border.all(color: looked ? AppColors.goldDeep : AppColors.gold, width: AppLine.rule),
          boxShadow: [BoxShadow(color: AppColors.navyDeep.withValues(alpha: 0.45), blurRadius: 5, offset: const Offset(0, 1))],
        ),
        child: InkIcon(
          looked ? InkGlyph.check : InkGlyph.search,
          size: AppIconSize.tiny,
          color: looked ? AppColors.navyDeep : AppColors.burgundy,
        ),
      ),
    );
  }
}

/// Under the picture: what to do now, how to look (the main line: tap the
/// picture), how to look closer, the hints opened, and the letter and tips.
class ExplorePanel extends StatelessWidget {
  const ExplorePanel({
    super.key,
    required this.task,
    required this.tapGuide,
    required this.zoomGuide,
    required this.hints,
    required this.hintsShown,
    required this.documentLabel,
    required this.onDocument,
    required this.onTip,
    this.hintsHeight = 0.2,
  });

  final String task;
  final String tapGuide;
  final String zoomGuide;
  final List<String> hints;
  final int hintsShown;

  /// The document's link, once it is read (null before).
  final String? documentLabel;
  final VoidCallback onDocument;
  final VoidCallback onTip;

  /// The most the opened hints take, as a fraction of the screen's height
  /// (they scroll beyond it).
  final double hintsHeight;

  @override
  Widget build(BuildContext context) {
    final tipLabel = nextTipLabel(hints, hintsShown);
    return DecoratedBox(
      key: const ValueKey('explore-panel'),
      decoration: BoxDecoration(
        color: AppColors.paperLight,
        border: Border(top: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.7), width: AppLine.rule)),
        boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: InkSurface(
        night: false,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Semantics(
                    key: ValueKey(task),
                    liveRegion: true,
                    child: GlossaryText(
                      task,
                      key: const ValueKey('explore-task'),
                      textAlign: TextAlign.center,
                      style: AppText.title(size: 19),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
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
                      TextSpan(text: tapGuide),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: AppText.bodyText(size: 16, weight: FontWeight.w700, color: AppColors.burgundy),
                ),
                const SizedBox(height: 2),
                Text(zoomGuide, textAlign: TextAlign.center, style: AppText.caption()),
                if (hintsShown > 0) const SizedBox(height: AppSpace.sm),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * hintsHeight),
                  child: SingleChildScrollView(
                    key: const ValueKey('explore-hints'),
                    child: DetectiveTipNotes(hints: hints, revealed: hintsShown, compact: true),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpace.sm,
                  children: [
                    if (documentLabel != null)
                      InkTextButton(label: documentLabel!, glyph: InkGlyph.letter, onPressed: onDocument),
                    if (tipLabel != null)
                      InkTextButton(label: tipLabel, glyph: InkGlyph.hint, color: tipLinkColor, onPressed: onTip),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Over the station, dimmed: a paper card in the middle, at most [maxWidth]
/// wide, its words scrolling inside it on a short screen.
class OverPicture extends StatelessWidget {
  const OverPicture({super.key, required this.still, required this.child, this.onTapOutside});

  final bool still;
  final Widget child;
  final VoidCallback? onTapOutside;

  static const maxWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTapOutside,
        child: ColoredBox(
          color: AppColors.navyDeep.withValues(alpha: 0.78),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: LayoutBuilder(
                builder: (context, box) => Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: math.min(maxWidth, box.maxWidth), maxHeight: box.maxHeight),
                    // A tap on the card itself stays on it.
                    child: GestureDetector(onTap: () {}, child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The suitcase opened: the mission's letter in it, sealed the first time
/// (the same envelope as every letter), open after.
class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    super.key,
    required this.spot,
    required this.mission,
    required this.opened,
    required this.still,
    required this.onOpening,
    required this.onOpened,
    required this.onClose,
  });

  final ExploreSpot spot;
  final Mission mission;
  final bool opened;
  final bool still;
  final VoidCallback onOpening;
  final VoidCallback onOpened;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return OverPicture(
      still: still,
      child: PaperSheet(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(spot.title, style: AppText.eyebrow()),
              const SizedBox(height: AppSpace.xs),
              const OrnamentRule(),
              const SizedBox(height: AppSpace.md),
              GlossaryText(
                mission.letterIntro,
                textAlign: TextAlign.center,
                style: AppText.aside(size: 17, color: AppColors.inkBrown),
              ),
              const SizedBox(height: AppSpace.md),
              EnvelopeReveal(
                letterText: mission.letter,
                initiallyOpen: opened,
                onOpen: onOpening,
                onOpened: onOpened,
              ),
              const SizedBox(height: AppSpace.md),
              if (opened) ...[
                Text('Tap a dotted word to see what it means.', textAlign: TextAlign.center, style: AppText.caption()),
                const SizedBox(height: AppSpace.md),
              ],
              GameButton(
                key: const ValueKey('explore-close'),
                label: 'BACK TO THE STATION',
                style: opened ? GameButtonStyle.navy : GameButtonStyle.outline,
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Something worth remembering, said on a small card; a tap anywhere goes
/// back to looking.
class _NoteCard extends StatelessWidget {
  const _NoteCard({super.key, required this.spot, required this.still, required this.onClose});

  final ExploreSpot spot;
  final bool still;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${spot.title}. ${spot.line} Keep looking',
      excludeSemantics: true,
      onTap: onClose,
      child: OverPicture(
        still: still,
        onTapOutside: onClose,
        child: GestureDetector(
          key: const ValueKey('explore-close'),
          onTap: onClose,
          child: PaperSheet(
            ruled: true,
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('NOTED', style: AppText.eyebrow()),
                const SizedBox(height: AppSpace.sm),
                Text(spot.title, textAlign: TextAlign.center, style: AppText.placeTitle(size: 28)),
                const SizedBox(height: AppSpace.xs),
                const OrnamentRule(),
                const SizedBox(height: AppSpace.sm),
                GlossaryText(spot.line, textAlign: TextAlign.center, style: AppText.letter(size: 18)),
                const SizedBox(height: AppSpace.md),
                Text('Tap to keep looking', textAlign: TextAlign.center, style: AppText.caption()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The choice's page, over the station: the puzzle's question, its
/// pictures two by two (each named under it with the option's own words),
/// then CHECK ANSWER for the one chosen.
class _ChoicePage extends StatefulWidget {
  const _ChoicePage({
    super.key,
    required this.scene,
    required this.mission,
    required this.progress,
    required this.wrongPulse,
    required this.onChanged,
    required this.onChoose,
    required this.onReread,
    required this.hintsShown,
    required this.onHint,
    required this.onClose,
  });

  final ExploreScene scene;
  final Mission mission;
  final ExploreProgress progress;
  final int wrongPulse;
  final VoidCallback onChanged;
  final Future<void> Function(String optionId) onChoose;
  final VoidCallback onReread;
  final int hintsShown;
  final Future<bool> Function() onHint;
  final VoidCallback onClose;

  @override
  State<_ChoicePage> createState() => _ChoicePageState();
}

class _ChoicePageState extends State<_ChoicePage> {
  /// A check is on its way: no second one (nor a second reward) meanwhile.
  bool _checking = false;

  Future<void> _check() async {
    final id = widget.progress.chosen;
    if (id == null || _checking) return;
    setState(() => _checking = true);
    try {
      await widget.onChoose(id);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _pick(String id) {
    widget.progress.chosen = id;
    widget.onChanged();
  }

  /// "The British Museum (treasures from long ago)" → its name and words.
  static (String, String?) _split(String label) {
    final at = label.indexOf(' (');
    if (at < 0 || !label.endsWith(')')) return (label, null);
    return (label.substring(0, at), label.substring(at + 2, label.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final scene = widget.scene;
    final chosen = widget.progress.chosen;
    return ColoredBox(
      key: const ValueKey('explore-choice'),
      color: AppColors.paperLight,
      child: InkSurface(
        night: false,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.xs, AppSpace.sm, 0),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('explore-choice-close'),
                      tooltip: 'Back to the station',
                      onPressed: widget.onClose,
                      icon: const InkIcon(InkGlyph.back, color: AppColors.navy),
                    ),
                    Expanded(
                      child: Text(
                        scene.choiceTitle,
                        textAlign: TextAlign.center,
                        style: AppText.eyebrow(),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey('explore-choice-scroll'),
                  padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.lg),
                  child: Column(
                    children: [
                      GlossaryText(m.question, textAlign: TextAlign.center, style: AppText.title(size: 22)),
                      const SizedBox(height: AppSpace.xs),
                      Text(scene.choiceHow, textAlign: TextAlign.center, style: AppText.caption(color: AppColors.inkBrown)),
                      const SizedBox(height: AppSpace.md),
                      const Center(child: OrnamentRule()),
                      const SizedBox(height: AppSpace.lg),
                      ShakeOnChange(
                        trigger: widget.wrongPulse,
                        child: LayoutBuilder(
                          builder: (context, box) {
                            const gap = AppSpace.md;
                            final tile = (box.maxWidth - gap) / 2;
                            return Wrap(
                              spacing: gap,
                              runSpacing: AppSpace.lg,
                              children: [
                                for (final c in scene.choices)
                                  SizedBox(
                                    width: tile,
                                    child: _PosterTile(
                                      key: ValueKey('poster-${c.optionId}'),
                                      picture: c,
                                      aspect: scene.pictureAspect,
                                      label: _split(m.options.firstWhere((o) => o.id == c.optionId).label),
                                      selected: chosen == c.optionId,
                                      onTap: () => _pick(c.optionId),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      DetectiveTipNotes(hints: m.hints, revealed: widget.hintsShown, compact: true),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.7), width: AppLine.rule)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameButton(
                        key: const ValueKey('explore-check'),
                        label: 'CHECK ANSWER',
                        onPressed: chosen == null || _checking ? null : _check,
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpace.sm,
                        children: [
                          InkTextButton(label: 'Reread Letter', glyph: InkGlyph.letter, onPressed: widget.onReread),
                          if (nextTipLabel(m.hints, widget.hintsShown) case final tip?)
                            InkTextButton(label: tip, glyph: InkGlyph.hint, color: tipLinkColor, onPressed: widget.onHint),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One poster: the picture whole, its name under it, the option's words
/// in a quiet line; chosen, it is framed in navy with a tick.
///
/// Choosing comes first, as on the answer cards: its words are dotted (a
/// tap: their meaning) only once it is chosen; screen readers hear the
/// poster as one answer, its words as actions.
class _PosterTile extends ConsumerWidget {
  const _PosterTile({
    super.key,
    required this.picture,
    required this.aspect,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ExplorePicture picture;
  final double aspect;
  final (String, String?) label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (name, words) = label;
    final said = '$name${words == null ? '' : ' ($words)'}';
    return Semantics(
      button: true,
      selected: selected,
      label: '$name${words == null ? '' : ', $words'}. Poster: ${picture.description}',
      excludeSemantics: true,
      customSemanticsActions: {
        for (final w in glossaryWordsOf(ref.watch(currentEpisodeProvider), said))
          CustomSemanticsAction(label: 'Meaning of ${w.word}'): () => lookUpAndShowWord(context, ref, w.word, w.meaning),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpace.xs),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.parchment.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.paper),
            border: Border.all(
              color: selected ? AppColors.navyDeep : AppLine.faint(0.25),
              width: selected ? AppLine.ink : AppLine.hairline,
            ),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: aspect,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Image.asset(picture.picture, fit: BoxFit.cover, excludeFromSemantics: true),
                    ),
                  ),
                  if (selected)
                    const Positioned(
                      right: AppSpace.xs,
                      top: AppSpace.xs,
                      child: CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.gold,
                        child: InkIcon(InkGlyph.check, size: AppIconSize.tiny, color: AppColors.navyDeep),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              GlossaryText(
                name,
                textAlign: TextAlign.center,
                linkColor: AppColors.goldLight,
                interactive: selected,
                wordSemantics: false,
                style: AppText.bodyText(
                  size: 15,
                  weight: FontWeight.w700,
                  color: selected ? AppColors.paperLight : AppColors.ink,
                ),
              ),
              if (words != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: AppSpace.xs),
                  child: GlossaryText(
                    words,
                    textAlign: TextAlign.center,
                    linkColor: AppColors.goldLight,
                    interactive: selected,
                    wordSemantics: false,
                    style: AppText.caption(color: selected ? AppColors.goldLight : AppColors.inkBrown),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
