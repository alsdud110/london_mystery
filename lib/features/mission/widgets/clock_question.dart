import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart';
import '../../../data/models/clock_puzzle.dart';
import '../../../data/models/mission.dart' show Artwork;
import '../../../widgets/art_assets.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/landmark_art.dart' show ClockHandsPainter;
import '../../game/game_providers.dart' show audioServiceProvider;
import 'question_widgets.dart' show AnswerCallback, PuzzleKey;

/// A clock face whose hands the detective sets ([ClockPuzzle]): drag a hand
/// on the face, or step it with the HOUR and MINUTE keys below. The time
/// set is submitted as the puzzle's typed answer ([ClockTime.answer]).
///
/// The time is kept by the page ([time], [onChanged]), so going back to the
/// letter and returning finds the hands where they were. [moved]: the hands
/// have been set at least once (SET THE TIME waits for it).
class ClockQuestion extends ConsumerStatefulWidget {
  const ClockQuestion({
    super.key,
    required this.puzzle,
    required this.time,
    required this.moved,
    required this.onChanged,
    required this.onSubmit,
  });

  final ClockPuzzle puzzle;
  final ClockTime time;
  final bool moved;
  final ValueChanged<ClockTime> onChanged;
  final AnswerCallback onSubmit;

  @override
  ConsumerState<ClockQuestion> createState() => _ClockQuestionState();
}

class _ClockQuestionState extends ConsumerState<ClockQuestion> {
  /// The hand a drag that does not start on a hand moves, and the one the
  /// face rings in gold. The hour first: the note starts with it.
  ClockHand _hand = ClockHand.hour;

  /// One click per step, never a rattle while a hand sweeps.
  DateTime _lastClick = DateTime.fromMillisecondsSinceEpoch(0);

  void _set(ClockTime next, ClockHand hand) {
    if (hand != _hand) setState(() => _hand = hand);
    if (next == widget.time && widget.moved) return;
    final now = DateTime.now();
    if (now.difference(_lastClick) > const Duration(milliseconds: 70)) {
      _lastClick = now;
      ref.read(audioServiceProvider).play(GameSound.lockDialClick, volume: 0.6);
    }
    HapticFeedback.selectionClick();
    widget.onChanged(next);
  }

  void _step(ClockHand hand, int delta) =>
      _set(widget.time.plusMinutes(hand == ClockHand.hour ? delta * 60 : delta), hand);

  @override
  Widget build(BuildContext context) {
    final p = widget.puzzle;
    final time = widget.time;
    return Column(
      children: [
        Text(
          p.lead,
          textAlign: TextAlign.center,
          style: AppText.bodyText(size: 16, color: AppColors.inkBrown),
        ),
        const SizedBox(height: AppSpace.lg),
        ClockDial(
          key: const ValueKey('clock-dial'),
          face: p.face,
          time: time,
          selected: _hand,
          label: p.dialLabel,
          onMove: _set,
        ),
        const SizedBox(height: AppSpace.lg),
        _Readout(time: time),
        const SizedBox(height: AppSpace.sm),
        Text(
          p.guide,
          textAlign: TextAlign.center,
          style: AppText.caption(color: AppColors.inkBrown),
        ),
        const SizedBox(height: AppSpace.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _HandKeys(
                hand: ClockHand.hour,
                selected: _hand == ClockHand.hour,
                onSelect: () => setState(() => _hand = ClockHand.hour),
                onStep: (d) => _step(ClockHand.hour, d),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: _HandKeys(
                hand: ClockHand.minute,
                selected: _hand == ClockHand.minute,
                onSelect: () => setState(() => _hand = ClockHand.minute),
                onStep: (d) => _step(ClockHand.minute, d),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        GameButton(
          key: const ValueKey('clock-submit'),
          label: p.submitLabel,
          semanticLabel: '${p.submitLabel}: ${time.label}',
          onPressed: widget.moved ? () => widget.onSubmit(time.answer) : null,
        ),
      ],
    );
  }
}

/// The clock face with the detective's hands on it. A touch that starts on
/// a hand takes that hand; anywhere else on the face it moves the
/// [selected] hand. The hand turns to the finger at once (a tap points it
/// there too), the minute hand one minute mark at a time.
///
/// The face claims the touch as it lands, so a drag across it turns a hand
/// and never scrolls the page.
class ClockDial extends StatefulWidget {
  const ClockDial({
    super.key,
    required this.face,
    required this.time,
    required this.selected,
    required this.label,
    required this.onMove,
  });

  final Artwork face;
  final ClockTime time;
  final ClockHand selected;
  final String label;
  final void Function(ClockTime time, ClockHand hand) onMove;

  /// The widest the face is drawn (a small phone shows it narrower).
  static const maxSize = 320.0;

  /// How near a hand a touch takes it: this fraction of the face's width,
  /// and never under a fingertip.
  static const reach = 0.09;
  static const minReach = 24.0;

  @override
  State<ClockDial> createState() => _ClockDialState();
}

class _ClockDialState extends State<ClockDial> {
  int? _pointer;
  ClockHand? _dragging;

  ClockHandsArt get _art => ArtAssets.clockHands[widget.face]!;

  Offset _pivot(double w) => Offset(_art.pivot.dx * w, _art.pivot.dy * w);

  double _length(ClockHand hand) => hand == ClockHand.hour ? _art.hourLength : _art.minuteLength;

  /// The hand under [p] (in a face [w] wide), if any: the nearer of the two
  /// blades; where both are under it (one over the other), the long hand
  /// beyond the short one's tip, else the hand in use.
  ClockHand? _handAt(Offset p, double w) {
    final pivot = _pivot(w);
    final tolerance = math.max(ClockDial.reach * w, ClockDial.minReach);
    double distance(ClockHand hand) {
      final a = widget.time.degreesOf(hand) * math.pi / 180;
      final tip = pivot + Offset(math.sin(a), -math.cos(a)) * (_length(hand) * w * 1.12);
      return _toSegment(p, pivot, tip);
    }

    final hour = distance(ClockHand.hour) <= tolerance;
    final minute = distance(ClockHand.minute) <= tolerance;
    if (hour && minute) {
      final r = (p - pivot).distance;
      return r > _art.hourLength * w * 1.12 ? ClockHand.minute : widget.selected;
    }
    if (hour) return ClockHand.hour;
    if (minute) return ClockHand.minute;
    return null;
  }

  static double _toSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / ab.distanceSquared).clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }

  void _turn(Offset p, double w, {bool carry = true}) {
    final d = p - _pivot(w);
    // At the pivot itself the direction means nothing.
    if (d.distance < w * 0.03) return;
    final hand = _dragging!;
    widget.onMove(widget.time.withHandAt(hand, ClockTime.angleOf(d.dx, d.dy), carry: carry), hand);
  }

  void _down(PointerDownEvent e, double w) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    _dragging = _handAt(e.localPosition, w) ?? widget.selected;
    // Landing, the hand is put where the finger is (the hour kept); then
    // it is swept round with it.
    _turn(e.localPosition, w, carry: false);
  }

  void _moveTo(PointerMoveEvent e, double w) {
    if (e.pointer == _pointer) _turn(e.localPosition, w);
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    _dragging = null;
  }

  @override
  Widget build(BuildContext context) {
    final file = ArtAssets.scenes[widget.face]!;
    return LayoutBuilder(
      builder: (context, c) {
        final w = math.min(c.maxWidth, ClockDial.maxSize);
        final art = _art;
        return Semantics(
          label: widget.label,
          value: widget.time.label,
          hint: 'Use the hour and minute keys below to set the hands.',
          child: SizedBox.square(
            dimension: w,
            child: RawGestureDetector(
              gestures: {
                EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                  EagerGestureRecognizer.new,
                  (_) {},
                ),
              },
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _down(e, w),
                onPointerMove: (e) => _moveTo(e, w),
                onPointerUp: _up,
                onPointerCancel: _up,
                child: _FaceCard(
                  // A face cut out in its own frame (Paris's old clock) sits
                  // on the page as it is; a square one on a paper card.
                  cutOut: ArtAssets.cutOutClockFaces.contains(widget.face),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ExcludeSemantics(child: Image.asset(file, fit: BoxFit.cover)),
                      CustomPaint(
                        painter: _HandRing(
                          pivot: art.pivot,
                          degrees: widget.time.degreesOf(widget.selected),
                          length: _length(widget.selected),
                        ),
                      ),
                      CustomPaint(
                        painter: ClockHandsPainter(
                          art,
                          hourDegrees: widget.time.hourDegrees,
                          minuteDegrees: widget.time.minuteDegrees,
                          aspect: 1,
                        ),
                      ),
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

/// The face's card: a paper card with its lift for a square face; nothing
/// for a face [cutOut] in its own frame (a card would show round it).
class _FaceCard extends StatelessWidget {
  const _FaceCard({required this.cutOut, required this.child});

  final bool cutOut;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (cutOut) return child;
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: AppShadow.paperLift),
      child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.paper), child: child),
    );
  }
}

/// A soft gold ring at the tip of the hand in use, under the hands: which
/// one a drag on the face moves.
class _HandRing extends CustomPainter {
  _HandRing({required this.pivot, required this.degrees, required this.length});

  final Offset pivot;
  final double degrees;
  final double length;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final a = degrees * math.pi / 180;
    final tip = Offset(pivot.dx * w, pivot.dy * w) + Offset(math.sin(a), -math.cos(a)) * (length * w);
    canvas.drawCircle(tip, w * 0.055, Paint()..color = AppColors.goldLight.withValues(alpha: 0.35));
    canvas.drawCircle(
      tip,
      w * 0.055,
      Paint()
        ..color = AppColors.goldLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.008,
    );
  }

  @override
  bool shouldRepaint(_HandRing old) => old.degrees != degrees || old.length != length || old.pivot != pivot;
}

/// The time on the clock in figures, on the lock wheels' navy plate.
class _Readout extends StatelessWidget {
  const _Readout({required this.time});

  final ClockTime time;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Time on the clock: ${time.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.sm),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: AppLine.hairline),
        ),
        child: Text(
          time.label,
          key: const ValueKey('clock-time'),
          style: AppText.title(size: 36, color: AppColors.goldLight),
        ),
      ),
    );
  }
}

/// One hand's keys: its name, then − and + (an hour, or a minute, a step).
/// Its name rings in gold while a drag on the face moves this hand; a tap
/// on the name chooses it.
class _HandKeys extends StatelessWidget {
  const _HandKeys({required this.hand, required this.selected, required this.onSelect, required this.onStep});

  final ClockHand hand;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final name = hand == ClockHand.hour ? 'HOUR' : 'MINUTE';
    final id = hand.name;
    Widget key(String sign, int delta, String spoken) => Expanded(
          child: Semantics(
            button: true,
            label: spoken,
            excludeSemantics: true,
            child: SizedBox(
              height: 52,
              child: PuzzleKey(key: ValueKey('clock-$id-${delta > 0 ? 'plus' : 'minus'}'), label: sign, onTap: () => onStep(delta)),
            ),
          ),
        );
    return Column(
      children: [
        Semantics(
          button: true,
          selected: selected,
          label: '$name hand',
          excludeSemantics: true,
          child: GestureDetector(
            key: ValueKey('clock-$id-hand'),
            behavior: HitTestBehavior.opaque,
            onTap: onSelect,
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: AppSpace.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(
                  color: selected ? AppColors.gold : Colors.transparent,
                  width: AppLine.rule,
                ),
              ),
              child: Text(name, style: AppText.eyebrow(color: selected ? AppColors.goldDeep : AppColors.inkBrown)),
            ),
          ),
        ),
        Row(
          children: [
            key('−', -1, '$name back'),
            const SizedBox(width: AppSpace.sm),
            key('+', 1, '$name forward'),
          ],
        ),
      ],
    );
  }
}
