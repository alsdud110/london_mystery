import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart';
import '../../../data/models/clock_puzzle.dart' show ClockTime;
import '../../../data/models/investigation.dart' show InvestigationSpot;
import '../../../data/models/mission.dart';
import '../../../data/models/station_clocks.dart';
import '../../../widgets/detective_tips.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/landmark_art.dart' show ClockHandsPainter;
import '../../../widgets/paper.dart';
import '../../../widgets/paper_background.dart';
import '../../game/game_providers.dart';
import 'investigation_search.dart' show PencilSlip, SearchTapRing, TapGuide;
import 'question_widgets.dart' show ShakeOnChange;
import 'scene_explore.dart' show ExploreActions, ExploreCaption, LookMark, OverPicture;
import 'search_stage.dart';

/// A station hall with clocks to compare ([StationClocksScene]): its
/// picture fills the top of the page and can be looked at closer (pinch,
/// drag), the clocks' hands drawn on it. A tap on a clock looks at it up
/// close (its name and its time); a tap on the departure board reads its
/// trains and the notice under them; the Lost Property desk, once the
/// notice is read and every clock seen, is where one clock is reported:
/// [onChoose] checks it as the puzzle's answer. Looking is never a wrong
/// answer.
///
/// What was looked at lives in [progress] (kept by the page) and is saved
/// through [onExamined], so it stays seen after a restart.
class StationClocks extends ConsumerStatefulWidget {
  const StationClocks({
    super.key,
    required this.scene,
    required this.mission,
    required this.progress,
    required this.onChanged,
    required this.onExamined,
    required this.onChoose,
    required this.hintsShown,
    required this.onHint,
    required this.wrongPulse,
  });

  final StationClocksScene scene;
  final Mission mission;
  final StationClocksProgress progress;
  final VoidCallback onChanged;

  /// A clock's option id, or the board's id: looked at for the first time.
  final ValueChanged<String> onExamined;

  /// Checks the clock reported (an option id) as the puzzle's answer.
  final Future<void> Function(String optionId) onChoose;

  final int hintsShown;
  final Future<bool> Function() onHint;

  /// Bumped by the page on a wrong answer: the clocks on the desk shake.
  final int wrongPulse;

  @override
  ConsumerState<StationClocks> createState() => _StationClocksState();
}

class _StationClocksState extends ConsumerState<StationClocks> {
  /// The pencilled slip over the picture: what the last tap found.
  String? _line;

  Offset? _tapAt;
  int _tapCount = 0;

  final _zoom = TransformationController();
  Size? _homeViewport;
  bool _homeShown = false;
  bool _moved = false;

  /// How far outside a place a tap still counts for it, on screen.
  static const slack = 14.0;
  static const maxScale = 3.5;

  StationClocksProgress get _p => widget.progress;
  StationClocksScene get _scene => widget.scene;

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
      case PaintedClock c:
        _open(c.optionId);
      case StationSpot s when s.id == _scene.board.id:
        _open(s.id);
      case StationSpot s when s.id == _scene.desk.id:
        if (!_p.boardRead(_scene)) {
          setState(() => _line = _scene.boardFirstLine);
        } else if (!_p.allClocksLooked(_scene)) {
          setState(() => _line = _scene.clocksFirstLine);
        } else {
          _open(s.id);
        }
      case InvestigationSpot o:
        setState(() => _line = o.line);
      default:
        setState(() => _line = _scene.missLine);
    }
  }

  void _open(String id) {
    final audio = ref.read(audioServiceProvider);
    audio.play(id == _scene.board.id || id == _scene.desk.id ? GameSound.paperRustle : GameSound.pencilNote);
    HapticFeedback.selectionClick();
    // Saved, so it stays looked at (the desk: its guide stays off).
    if (_p.looked.add(id)) widget.onExamined(id);
    _p.open = id;
    _line = null;
    widget.onChanged();
  }

  void _close() {
    if (_p.open == null) return;
    _p.open = null;
    widget.onChanged();
  }

  SearchFrame _frame(double width) => SearchFrame(
        width: width,
        aspect: _scene.pixels.aspect,
        inside: _scene.inside,
        focus: _scene.opening,
        maxScale: maxScale,
      );

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final open = _p.open;
    return Stack(
      children: [
        SearchStage(
          idealHeight: (width) => _frame(width).idealHeight,
          picture: (context, viewport) {
            final frame = _frame(viewport.width);
            final size = frame.picture;
            final origin = frame.origin;
            if (_homeViewport != viewport) {
              _homeViewport = viewport;
              final home = frame.home(viewport);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _zoom.value = _moved ? frame.keep(_zoom.value, viewport) : home;
                if (!_homeShown) setState(() => _homeShown = true);
              });
            }
            return Opacity(
              opacity: _homeShown ? 1 : 0,
              child: InteractiveViewer(
                transformationController: _zoom,
                constrained: false,
                minScale: frame.minScale(viewport),
                maxScale: maxScale,
                boundaryMargin: EdgeInsets.zero,
                onInteractionStart: (_) {
                  _moved = true;
                  _guideDone();
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
                        child: _HallPicture(
                          key: const ValueKey('station-picture'),
                          scene: scene,
                          progress: _p,
                          tapAt: _tapAt,
                          tapCount: _tapCount,
                          guide: !_p.guideShown && !still,
                          onGuideEnd: _guideDone,
                          onTap: (point) => _tap(point, size * _zoom.value.getMaxScaleOnAxis()),
                          onSpot: _look,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          note: PencilSlip(line: _line),
          caption: ExploreCaption(
            task: _p.taskOf(scene),
            tapGuide: scene.tapGuide,
            zoomGuide: scene.zoomGuide,
          ),
          actions: ExploreActions(
            key: const ValueKey('station-panel'),
            hints: widget.mission.hints,
            hintsShown: widget.hintsShown,
            documentLabel: _p.boardRead(scene) ? 'Departure Board' : null,
            onDocument: () => _open(scene.board.id),
            onTip: widget.onHint,
          ),
        ),
        if (open != null)
          Positioned.fill(
            child: open == scene.board.id
                ? _BoardCard(key: const ValueKey('station-board'), scene: scene, still: still, onClose: _close)
                : open == scene.desk.id
                ? _ReportPage(
                    key: const ValueKey('station-desk'),
                    scene: scene,
                    mission: widget.mission,
                    progress: _p,
                    wrongPulse: widget.wrongPulse,
                    onChanged: widget.onChanged,
                    onChoose: widget.onChoose,
                    hintsShown: widget.hintsShown,
                    onHint: widget.onHint,
                    onClose: _close,
                  )
                : _ClockCard(
                    key: ValueKey('station-clock-$open'),
                    scene: scene,
                    clock: scene.clock(open),
                    still: still,
                    onClose: _close,
                  ),
          ),
      ],
    );
  }
}

/// The picture looked round: the clocks' hands, a small glass on each thing
/// worth a look (a tick once looked at), the first "tap here" rings, and an
/// invisible button on every listed place for screen readers. Its taps are
/// in fractions of the picture, wherever it is enlarged or moved to.
class _HallPicture extends StatelessWidget {
  const _HallPicture({
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

  final StationClocksScene scene;
  final StationClocksProgress progress;
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
        Rect place(Rect r) => Rect.fromLTRB(r.left * size.width, r.top * size.height, r.right * size.width, r.bottom * size.height);
        Widget mark(String id, Offset at, bool looked) => Positioned(
              left: at.dx * size.width - markSize / 2,
              top: at.dy * size.height - markSize / 2,
              child: LookMark(key: ValueKey('mark-$id'), looked: looked),
            );
        Widget button(Rect area, String label, Object target) => Positioned.fromRect(
              rect: place(area),
              child: Semantics(button: true, label: label, onTap: () => onSpot(target), child: const SizedBox.expand()),
            );
        final reported = progress.canReport(scene);
        final guideTo = progress.guideTo(scene);
        final deskAt = Offset(scene.desk.mark.dx * size.width, scene.desk.mark.dy * size.height);
        return Semantics(
          label: scene.place,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onTap(Offset(d.localPosition.dx / size.width, d.localPosition.dy / size.height)),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(child: Image.asset(scene.picture, fit: BoxFit.fill, excludeFromSemantics: true)),
                Positioned.fill(child: CustomPaint(painter: PaintedClockHands(scene.clocks))),
                for (final c in scene.clocks) mark(c.optionId, c.mark, progress.hasLooked(c.optionId)),
                // Every clock seen: the board, outlined softly where it is.
                if (guideTo == scene.board.id)
                  Positioned.fromRect(
                    rect: place(scene.board.outline ?? scene.board.area),
                    child: IgnorePointer(child: GuideOutline(key: const ValueKey('board-guide'), still: still)),
                  ),
                mark(scene.board.id, scene.board.mark, progress.boardRead(scene)),
                // The desk is marked once it can be used: the report is its
                // look. Until it is gone to, its glass pulses, REPORT HERE
                // under it (where to go, never which clock).
                if (reported && guideTo == scene.desk.id)
                  Positioned(
                    left: deskAt.dx - GuidePulse.size / 2,
                    top: deskAt.dy - GuidePulse.size / 2,
                    child: IgnorePointer(
                      child: GuidePulse(
                        key: const ValueKey('desk-guide'),
                        still: still,
                        child: const LookMark(key: ValueKey('mark-desk'), looked: false),
                      ),
                    ),
                  )
                else if (reported)
                  mark(scene.desk.id, scene.desk.mark, false),
                // The tag beside the glass, on its left (the desk is near the
                // picture's right edge), on one line, over the desk's own
                // sign: it covers no other place to tap.
                if (reported && guideTo == scene.desk.id)
                  Positioned(
                    right: size.width - deskAt.dx + GuidePulse.size / 2,
                    top: deskAt.dy - 11,
                    child: const IgnorePointer(child: _ReportHere()),
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
                for (final c in scene.clocks)
                  button(c.area, progress.hasLooked(c.optionId) ? '${c.label}, looked at' : c.label, c),
                button(scene.board.area, progress.boardRead(scene) ? '${scene.board.label}, read' : scene.board.label, scene.board),
                button(scene.desk.area, scene.desk.label, scene.desk),
                for (final o in scene.others) button(o.areas.first, o.label, o),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The next place to look on the picture: a soft gold frame round it that
/// breathes slowly (1.3 s); with reduced motion, simply there.
class GuideOutline extends StatefulWidget {
  const GuideOutline({super.key, required this.still});

  final bool still;

  @override
  State<GuideOutline> createState() => _GuideOutlineState();
}

class _GuideOutlineState extends State<GuideOutline> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void initState() {
    super.initState();
    if (!widget.still) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = widget.still ? 0.6 : Curves.easeInOut.transform(_c.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.45 + 0.4 * t), width: AppLine.ink),
            boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: 0.12 + 0.2 * t), blurRadius: 12)],
          ),
        );
      },
    );
  }
}

/// A glass that calls: a gold ring round [child] that brightens and grows a
/// touch (1.0 → 1.08) and back, every 1.3 s; with reduced motion, a still
/// gold ring.
class GuidePulse extends StatefulWidget {
  const GuidePulse({super.key, required this.still, required this.child});

  final bool still;
  final Widget child;

  /// Its whole size: the glass and its ring.
  static const size = 48.0;

  @override
  State<GuidePulse> createState() => _GuidePulseState();
}

class _GuidePulseState extends State<GuidePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void initState() {
    super.initState();
    if (!widget.still) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: GuidePulse.size,
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final t = widget.still ? 0.7 : Curves.easeInOut.transform(_c.value);
          return Transform.scale(
            scale: 1 + 0.08 * t,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: GuidePulse.size - 4,
                  height: GuidePulse.size - 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.5 + 0.45 * t), width: AppLine.ink),
                    boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: 0.2 + 0.3 * t), blurRadius: 10)],
                  ),
                ),
                child!,
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The small paper tag under the desk's glass.
class _ReportHere extends StatelessWidget {
  const _ReportHere();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('report-here'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.paperLight.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: AppColors.gold, width: AppLine.hairline),
        boxShadow: [BoxShadow(color: AppColors.navyDeep.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: Text('REPORT HERE', maxLines: 1, softWrap: false, style: AppText.eyebrow(color: AppColors.burgundy)),
      ),
    );
  }
}

/// The hands of [clocks], drawn over their picture (fractions of it): the
/// minute hand on each dial's XII, the hour hand on the numeral of its hour,
/// sized to the dial, as the Big Ben clock's hands are drawn.
class PaintedClockHands extends CustomPainter {
  PaintedClockHands(this.clocks);

  final List<PaintedClock> clocks;

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(Offset f) => Offset(f.dx * size.width, f.dy * size.height);
    for (final c in clocks) {
      final pivot = at(c.centre);
      final twelve = at(c.twelve) - pivot;
      final hour = at(c.hourNumeral) - pivot;
      final r = twelve.distance;
      // The minute hand into the minute track beyond XII; the hour hand short
      // of its numeral.
      final minute = r * 1.08;
      final hourLength = hour.distance * 0.7;
      ClockHandsPainter.paintHand(canvas, pivot, ClockTime.angleOf(twelve.dx, twelve.dy),
          length: minute, width: minute * 0.045, tip: 1.1);
      ClockHandsPainter.paintHand(canvas, pivot, ClockTime.angleOf(hour.dx, hour.dy),
          length: hourLength, width: hourLength * 0.12, tip: 1.6);
      ClockHandsPainter.paintCap(canvas, pivot, r * 0.075);
    }
  }

  @override
  bool shouldRepaint(PaintedClockHands old) => old.clocks != clocks;
}

/// One clock up close, square: the part of the hall's picture round it,
/// enlarged, its hands on it.
class ClockCloseUp extends StatelessWidget {
  const ClockCloseUp({super.key, required this.scene, required this.clock});

  final StationClocksScene scene;
  final PaintedClock clock;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final side = box.maxWidth;
        final crop = clock.closeUp;
        // The whole picture at the size that makes the close-up [side] wide.
        final w = side / crop.width;
        final h = w / scene.pixels.aspect;
        return SizedBox.square(
          dimension: side,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: 0,
              minHeight: 0,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Transform.translate(
                offset: Offset(-crop.left * w, -crop.top * h),
                child: SizedBox(
                  width: w,
                  height: h,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(scene.picture, fit: BoxFit.fill, excludeFromSemantics: true),
                      CustomPaint(painter: PaintedClockHands([clock])),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The numeral of an hour, and the hour in words: what the close-up says
/// the hour hand points at.
const _numerals = ['XII', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI'];
const _hourWords = ['twelve', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven'];

int _hourOf(String time) => int.parse(time.split(':').first) % 12;

/// A clock looked at up close: its name, its face, its time, and where its
/// hands point. A tap anywhere goes back to the hall.
class _ClockCard extends StatelessWidget {
  const _ClockCard({super.key, required this.scene, required this.clock, required this.still, required this.onClose});

  final StationClocksScene scene;
  final PaintedClock clock;
  final bool still;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final hour = _hourOf(clock.time);
    final hands = 'The short hand points to ${_numerals[hour]}. The long hand points to XII.';
    return Semantics(
      button: true,
      label: '${clock.name}. It shows ${clock.time}. $hands Tap to go back to the hall.',
      excludeSemantics: true,
      onTap: onClose,
      child: OverPicture(
        still: still,
        onTapOutside: onClose,
        child: GestureDetector(
          key: const ValueKey('station-close'),
          onTap: onClose,
          child: PaperSheet(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('LOOKED AT', style: AppText.eyebrow()),
                  const SizedBox(height: AppSpace.xs),
                  Text(clock.name, textAlign: TextAlign.center, style: AppText.placeTitle(size: 26)),
                  const SizedBox(height: AppSpace.xs),
                  const OrnamentRule(),
                  const SizedBox(height: AppSpace.md),
                  ConstrainedBox(
                    // Room for the time and the words under it on a short phone.
                    constraints: BoxConstraints(maxWidth: math.min(240, MediaQuery.sizeOf(context).height * 0.32)),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.paper),
                        border: Border.all(color: AppColors.goldDeep, width: AppLine.rule),
                        boxShadow: AppShadow.paperLift,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.paper),
                        child: ClockCloseUp(key: ValueKey('close-up-${clock.optionId}'), scene: scene, clock: clock),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  _TimePlate(time: clock.time),
                  const SizedBox(height: AppSpace.sm),
                  Text(hands, textAlign: TextAlign.center, style: AppText.letter(size: 16)),
                  Text(
                    'It is ${_hourWords[hour]} o\'clock.',
                    textAlign: TextAlign.center,
                    style: AppText.letter(size: 16, color: AppColors.inkBrown),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text('Tap to keep looking', textAlign: TextAlign.center, style: AppText.caption()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A time in figures on the navy plate the clock puzzles read out on.
class _TimePlate extends StatelessWidget {
  const _TimePlate({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: AppLine.hairline),
      ),
      child: Text(
        time,
        style: AppText.title(size: 30, color: AppColors.goldLight).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

/// The departure board, read up close: its trains on the dark board, in
/// brass letters, and the station notice pinned under it, its key words on
/// their own lines.
class _BoardCard extends StatelessWidget {
  const _BoardCard({super.key, required this.scene, required this.still, required this.onClose});

  final StationClocksScene scene;
  final bool still;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cell = AppText.title(size: 17, color: AppColors.goldLight).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final head = AppText.eyebrow(color: AppColors.paperLight.withValues(alpha: 0.7));
    return OverPicture(
      still: still,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The board: iron, a brass rim, the trains in brass.
            Semantics(
              label: '${scene.boardTitle}: ${[for (final d in scene.departures) '${d.time} to ${d.to}, platform ${d.platform}'].join('; ')}',
              excludeSemantics: true,
              child: Container(
                key: const ValueKey('departure-board'),
                padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.sm),
                decoration: BoxDecoration(
                  color: AppColors.navyDeep,
                  borderRadius: BorderRadius.circular(AppRadius.paper),
                  border: Border.all(color: AppColors.gold, width: AppLine.rule),
                  boxShadow: AppShadow.onNight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(scene.boardTitle, textAlign: TextAlign.center, style: AppText.mark(color: AppColors.goldLight, size: 18)),
                    const SizedBox(height: AppSpace.sm),
                    _row(
                      Text('TIME', style: head),
                      Text('TO', style: head),
                      // One line in its column, whatever the text size.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text('PLATFORM', style: head, maxLines: 1),
                      ),
                    ),
                    Divider(height: AppSpace.md, color: AppColors.gold.withValues(alpha: 0.4), thickness: AppLine.hairline),
                    for (final d in scene.departures)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: _row(
                          Text(d.time, style: cell),
                          Text(d.to, style: cell, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
                          Text(d.platform, style: cell, textAlign: TextAlign.end),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            // The notice pinned under it.
            PaperSheet(
              key: const ValueKey('station-notice'),
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
              child: Column(
                children: [
                  Text(scene.noticeTitle, style: AppText.eyebrow()),
                  const SizedBox(height: AppSpace.xs),
                  const OrnamentRule(),
                  const SizedBox(height: AppSpace.sm),
                  for (final line in scene.notice)
                    for (final (part, key) in _parts(line, scene.noticeKeys))
                      GlossaryText(
                        part,
                        textAlign: TextAlign.center,
                        style: key
                            ? AppText.title(size: 21, color: AppColors.burgundy)
                            : AppText.letter(size: 17),
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            GameButton(
              key: const ValueKey('station-board-close'),
              label: 'BACK TO THE HALL',
              style: GameButtonStyle.glass,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _row(Widget time, Widget to, Widget platform) => Row(
        children: [
          SizedBox(width: 64, child: time),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: to),
          SizedBox(width: 84, child: platform),
        ],
      );

  /// [line] cut at its [keys]: each piece, and whether it is a key.
  static List<(String, bool)> _parts(String line, List<String> keys) {
    final parts = <(String, bool)>[];
    var rest = line;
    while (rest.isNotEmpty) {
      final hits = [
        for (final k in keys)
          if (rest.contains(k)) (rest.indexOf(k), k),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
      if (hits.isEmpty) {
        parts.add((rest.trim(), false));
        break;
      }
      final (at, k) = hits.first;
      // The key keeps its punctuation ("BEHIND,"), on its own line.
      var end = at + k.length;
      while (end < rest.length && ',.'.contains(rest[end])) {
        end++;
      }
      final before = rest.substring(0, at).trim();
      if (before.isNotEmpty) parts.add((before, false));
      parts.add((rest.substring(at, end), true));
      rest = rest.substring(end).trim();
    }
    return parts;
  }
}

/// The Lost Property desk's page, over the hall: the notice's words, the
/// three clocks as they were seen (their faces, names and times), and
/// REPORT IT for the one chosen.
class _ReportPage extends StatefulWidget {
  const _ReportPage({
    super.key,
    required this.scene,
    required this.mission,
    required this.progress,
    required this.wrongPulse,
    required this.onChanged,
    required this.onChoose,
    required this.hintsShown,
    required this.onHint,
    required this.onClose,
  });

  final StationClocksScene scene;
  final Mission mission;
  final StationClocksProgress progress;
  final int wrongPulse;
  final VoidCallback onChanged;
  final Future<void> Function(String optionId) onChoose;
  final int hintsShown;
  final Future<bool> Function() onHint;
  final VoidCallback onClose;

  @override
  State<_ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<_ReportPage> {
  /// A check is on its way: no second one meanwhile.
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
    HapticFeedback.selectionClick();
    widget.progress.chosen = id;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final scene = widget.scene;
    final chosen = widget.progress.chosen;
    return ColoredBox(
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
                      key: const ValueKey('station-desk-close'),
                      tooltip: 'Back to the hall',
                      onPressed: widget.onClose,
                      icon: const InkIcon(InkGlyph.back, color: AppColors.navy),
                    ),
                    Expanded(child: Text(scene.desk.title, textAlign: TextAlign.center, style: AppText.eyebrow())),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.lg),
                  child: Column(
                    children: [
                      GlossaryText(m.question, textAlign: TextAlign.center, style: AppText.title(size: 22)),
                      const SizedBox(height: AppSpace.xs),
                      Text(scene.reportHow, textAlign: TextAlign.center, style: AppText.caption(color: AppColors.inkBrown)),
                      const SizedBox(height: AppSpace.md),
                      const Center(child: OrnamentRule()),
                      const SizedBox(height: AppSpace.lg),
                      ShakeOnChange(
                        trigger: widget.wrongPulse,
                        child: LayoutBuilder(
                          builder: (context, box) {
                            const gap = AppSpace.sm;
                            final n = scene.clocks.length;
                            final tile = (box.maxWidth - gap * (n - 1)) / n;
                            final names = [for (final c in scene.clocks) m.options.firstWhere((o) => o.id == c.optionId).label];
                            final name = _ClockTile.nameBox(context, names, tile);
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final (i, c) in scene.clocks.indexed) ...[
                                  if (i > 0) const SizedBox(width: gap),
                                  SizedBox(
                                    width: tile,
                                    child: _ClockTile(
                                      key: ValueKey('report-${c.optionId}'),
                                      scene: scene,
                                      clock: c,
                                      name: names[i],
                                      nameStyle: name.$1,
                                      nameHeight: name.$2,
                                      selected: chosen == c.optionId,
                                      onTap: () => _pick(c.optionId),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      // The notice's words, as the desk would read them back.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpace.md),
                        decoration: BoxDecoration(
                          color: AppColors.parchment.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.paper),
                          border: Border.all(color: AppColors.parchmentDark, width: AppLine.hairline),
                        ),
                        child: Column(
                          children: [
                            Text(scene.noticeTitle, style: AppText.eyebrow(color: AppColors.inkBrown)),
                            const SizedBox(height: AppSpace.xs),
                            GlossaryText(scene.notice.last, textAlign: TextAlign.center, style: AppText.letter(size: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
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
                        key: const ValueKey('station-report'),
                        label: 'REPORT IT',
                        tap: TapRole.primary,
                        onPressed: chosen == null || _checking ? null : _check,
                      ),
                      if (nextTipLabel(m.hints, widget.hintsShown) case final tip?)
                        InkTextButton(label: tip, glyph: InkGlyph.hint, color: tipLinkColor, onPressed: widget.onHint),
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

/// One clock on the desk's page: its face up close, its name and the time
/// it was seen at; chosen, framed in navy with a tick. The three are laid
/// out alike, whatever their names: the same face, the same room for the
/// name ([nameHeight]), the time on one line across them.
class _ClockTile extends StatelessWidget {
  const _ClockTile({
    super.key,
    required this.scene,
    required this.clock,
    required this.name,
    required this.nameStyle,
    required this.nameHeight,
    required this.selected,
    required this.onTap,
  });

  final StationClocksScene scene;
  final PaintedClock clock;
  final String name;
  final TextStyle nameStyle;
  final double nameHeight;
  final bool selected;
  final VoidCallback onTap;

  static const _padding = AppSpace.xs;

  /// The names' style and the room every tile [tile] wide keeps for its
  /// name: two lines at 14 (13 when a name needs it to stay on two), more
  /// only when large text cannot fit them on two.
  static (TextStyle, double) nameBox(BuildContext context, List<String> names, double tile) {
    final scaler = MediaQuery.textScalerOf(context);
    final width = tile - 2 * _padding - 2 * AppLine.ink;
    TextStyle style(double size) => AppText.bodyText(size: size, weight: FontWeight.w700);
    TextPainter laid(String text, TextStyle s) =>
        TextPainter(text: TextSpan(text: text, style: s), textDirection: TextDirection.ltr, textScaler: scaler, textAlign: TextAlign.center)
          ..layout(maxWidth: width);
    int lines(String n, TextStyle s) => laid(n, s).computeLineMetrics().length;
    var s = style(14);
    if (names.any((n) => lines(n, s) > 2)) s = style(13);
    final most = names.map((n) => lines(n, s)).fold(2, math.max);
    return (s, laid(List.filled(most, 'Ag').join('\n'), s).height);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$name. It shows ${clock.time}.',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(_padding),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: ClockCloseUp(scene: scene, clock: clock),
                  ),
                  if (selected)
                    const Positioned(
                      right: AppSpace.xs,
                      top: AppSpace.xs,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.gold,
                        child: InkIcon(InkGlyph.check, size: AppIconSize.tiny, color: AppColors.navyDeep),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                key: ValueKey('report-name-${clock.optionId}'),
                height: nameHeight,
                child: Center(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: nameStyle.copyWith(color: selected ? AppColors.paperLight : AppColors.ink),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                clock.time,
                key: ValueKey('report-time-${clock.optionId}'),
                style: AppText.title(size: 18, color: selected ? AppColors.goldLight : AppColors.navy)
                    .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              const SizedBox(height: AppSpace.xs),
            ],
          ),
        ),
      ),
    );
  }
}
