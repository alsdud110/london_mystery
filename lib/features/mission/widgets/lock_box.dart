import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart' show Evidence;
import '../../../data/models/scene_exhibit.dart';
import '../../../widgets/evidence_card.dart' show EvidenceLinkRow;
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';

/// A letter-lock box ([LockBoxArt]) on the final case's stage. Shut, the
/// letters the detective has put in the lock below show in the box's own
/// slots ([letters]). Opening ([animation] 0 → 1): the slots light one by
/// one, the latch gives a small jolt, then the box opens round its slots:
/// the two pictures are laid on the slots, so the lock stays where it is
/// while the lid lifts (the shut and open boxes are drawn differently; a
/// plain swap would jump). 1 (solved, or a revisit): the open box, what is
/// inside it ringed until it is looked at ([insideLooked]); a tap on it
/// calls [onInside].
class LockBoxStage extends StatelessWidget {
  const LockBoxStage({
    super.key,
    required this.art,
    required this.animation,
    required this.letters,
    required this.word,
    this.insideLooked = false,
    this.onInside,
  });

  final LockBoxArt art;
  final Animation<double> animation;

  /// The letter in each slot of the lock below, null while it is empty.
  final List<String?> letters;

  /// The word that opened it, shown in the open box's slots.
  final String word;

  final bool insideLooked;
  final VoidCallback? onInside;

  /// The opening's steps (fractions of [animation]): the slots light, the
  /// latch jolts, the box opens.
  static const lit = 0.3;
  static const jolt = 0.4;
  static const opened = 0.78;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = still && animation.value > 0 ? 1.0 : animation.value;
        final shake = t > lit && t < jolt ? math.sin((t - lit) * 140) * 3 : 0.0;
        final open = Curves.easeInOutCubic.transform(((t - jolt) / (opened - jolt)).clamp(0.0, 1.0));
        final shown = t <= 0 ? 0 : (t / lit * art.closedSlots.length).ceil().clamp(0, art.closedSlots.length);
        return LayoutBuilder(
          builder: (context, box) {
            final size = box.biggest;
            // Each picture whole in the stage; the slots of each, on screen.
            final shut = _fit(art.closedPixels.aspect, size);
            final wide = _fit(art.openPixels.aspect, size);
            final shutBand = _on(shut, LockBoxArt.band(art.closedSlots));
            final openBand = _on(wide, LockBoxArt.band(art.openSlots));
            // Where the slots are now: the shut box's, then the open box's.
            final band = Rect.lerp(shutBand, openBand, open)!;
            final shutAt = _laidOn(LockBoxArt.band(art.closedSlots), band, art.closedPixels.aspect);
            final openAt = _laidOn(LockBoxArt.band(art.openSlots), band, art.openPixels.aspect);
            final shutOpacity = 1 - _ease(open, 0.1, 0.7);
            final openOpacity = _ease(open, 0.25, 0.85);
            final done = t >= 1;
            final inside = _on(openAt, art.inside);
            return Transform.translate(
              offset: Offset(shake, 0),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  if (shutOpacity > 0)
                    _picture(
                      art.closed,
                      shutAt,
                      shutOpacity,
                      const ValueKey('lock-box-shut'),
                      [
                        for (final (i, r) in art.closedSlots.indexed)
                          if (i < letters.length && letters[i] != null)
                            (r, letters[i]!, t > 0 && i < shown),
                      ],
                    ),
                  if (openOpacity > 0)
                    _picture(
                      art.open,
                      openAt,
                      openOpacity,
                      const ValueKey('lock-box-open'),
                      [
                        for (final (i, r) in art.openSlots.indexed)
                          if (i < word.length) (r, word[i], false),
                      ],
                    ),
                  // What is inside: ringed until looked at, and a tap away.
                  if (done && onInside != null)
                    Positioned.fromRect(
                      rect: inside,
                      child: Semantics(
                        button: true,
                        label: '${art.insideLabel}. Tap to look closer.',
                        child: GestureDetector(
                          key: const ValueKey('lock-box-inside'),
                          behavior: HitTestBehavior.opaque,
                          onTap: onInside,
                          child: insideLooked || still ? const SizedBox.expand() : const _InsideRing(),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// One of the box's pictures at [at], with [slots]' letters in it (each
  /// lit while its letter is pressed home).
  Widget _picture(String file, Rect at, double opacity, Key key, List<(Rect, String, bool)> slots) {
    return Positioned.fromRect(
      rect: at,
      child: Opacity(
        opacity: opacity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(file, key: key, fit: BoxFit.fill, excludeFromSemantics: true),
            for (final (r, letter, glowing) in slots)
              Positioned.fromRect(
                rect: _on(Offset.zero & at.size, r),
                child: _SlotLetter(letter: letter, glowing: glowing),
              ),
          ],
        ),
      ),
    );
  }

  /// A picture [aspect] wide for 1 high, whole and centred in [size].
  static Rect _fit(double aspect, Size size) {
    var w = size.width, h = w / aspect;
    if (h > size.height) {
      h = size.height;
      w = h * aspect;
    }
    return Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
  }

  /// [f] (fractions of [r]) in [r]'s own space.
  static Rect _on(Rect r, Rect f) =>
      Rect.fromLTRB(r.left + f.left * r.width, r.top + f.top * r.height, r.left + f.right * r.width, r.top + f.bottom * r.height);

  /// Where a picture [aspect] wide for 1 high goes so that its part [band]
  /// (fractions) lies on [target]: as wide, centred on it.
  static Rect _laidOn(Rect band, Rect target, double aspect) {
    final w = target.width / band.width;
    final h = w / aspect;
    return Rect.fromLTWH(target.center.dx - band.center.dx * w, target.center.dy - band.center.dy * h, w, h);
  }

  static double _ease(double v, double from, double to) => Curves.easeInOut.transform(((v - from) / (to - from)).clamp(0.0, 1.0));
}

/// A letter in one of the box's slots, as if stamped on its brass plate:
/// dark ink, a pale rim; lit gold while it is pressed home.
class _SlotLetter extends StatelessWidget {
  const _SlotLetter({required this.letter, required this.glowing});

  final String letter;
  final bool glowing;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: glowing ? Border.all(color: AppColors.goldLight, width: AppLine.rule) : null,
          boxShadow: glowing ? [BoxShadow(color: AppColors.goldLight.withValues(alpha: 0.55), blurRadius: 10)] : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              letter,
              textScaler: TextScaler.noScaling,
              style: AppText.logo(size: 40, color: AppColors.ink).copyWith(
                height: 1,
                shadows: const [Shadow(color: AppColors.goldLight, blurRadius: 1.5)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft gold ring that breathes round what is in the open box: something
/// to look at.
class _InsideRing extends StatefulWidget {
  const _InsideRing();

  @override
  State<_InsideRing> createState() => _InsideRingState();
}

class _InsideRingState extends State<_InsideRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.5 + 0.4 * _c.value), width: AppLine.ink),
          boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: 0.25 * _c.value), blurRadius: 14)],
        ),
      ),
    );
  }
}

/// What was found in the box, looked at closer, over the page: its own
/// picture whole, its name and what it shows; TURN IT OVER shows what is
/// written on its back ([onBackRead] the first time), and under it the
/// evidence it matches ([evidence]'s link, `EvidenceLinkRow`).
Future<void> showFoundInspect(
  BuildContext context, {
  required LockBoxArt art,
  required Evidence? evidence,
  required bool backRead,
  required VoidCallback onBackRead,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: _FoundInspect(art: art, evidence: evidence, backRead: backRead, onBackRead: onBackRead),
      ),
    ),
  );
}

class _FoundInspect extends StatefulWidget {
  const _FoundInspect({required this.art, required this.evidence, required this.backRead, required this.onBackRead});

  final LockBoxArt art;
  final Evidence? evidence;
  final bool backRead;
  final VoidCallback onBackRead;

  @override
  State<_FoundInspect> createState() => _FoundInspectState();
}

class _FoundInspectState extends State<_FoundInspect> with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  /// Its back has been read on this look (the link shows under it then).
  bool _read = false;

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  void _flip() {
    if (_turn.isAnimating) return;
    final toBack = _turn.value < 0.5;
    if (MediaQuery.disableAnimationsOf(context)) {
      _turn.value = toBack ? 1 : 0;
    } else {
      toBack ? _turn.forward() : _turn.reverse();
    }
    if (toBack && !_read) {
      setState(() => _read = true);
      if (!widget.backRead) widget.onBackRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    final art = widget.art;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AnimatedBuilder(
                animation: _turn,
                builder: (context, _) {
                  final angle = Curves.easeInOutCubic.transform(_turn.value) * math.pi;
                  final back = angle > math.pi / 2;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(back ? 'ON THE BACK' : art.foundTitle, style: AppText.mark(color: AppColors.goldLight)),
                      const SizedBox(height: AppSpace.lg),
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..rotateY(angle),
                        child: AspectRatio(
                          aspectRatio: art.foundPixels.aspect,
                          child: back
                              // Turned round, so it reads the right way.
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..rotateY(math.pi),
                                  child: _Back(text: art.back),
                                )
                              : Semantics(
                                  image: true,
                                  label: art.foundLine,
                                  child: Image.asset(art.found, key: const ValueKey('found-front'), fit: BoxFit.contain, excludeFromSemantics: true),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      GlossaryText(
                        back ? 'Three words are written on the back.' : art.foundLine,
                        textAlign: TextAlign.center,
                        linkColor: AppColors.goldLight,
                        style: AppText.aside(size: 17, color: AppColors.paperLight),
                      ),
                      // Once its back is read: the evidence it matches.
                      if (_read && widget.evidence != null)
                        EvidenceLinkRow(evidenceId: widget.evidence!.id, dark: true),
                      const SizedBox(height: AppSpace.xl),
                      GameButton(
                        key: const ValueKey('found-turn'),
                        label: back ? 'TURN IT BACK' : 'TURN IT OVER',
                        style: back ? GameButtonStyle.glass : GameButtonStyle.navy,
                        tap: back ? TapRole.secondary : TapRole.primary,
                        onPressed: _flip,
                      ),
                      const SizedBox(height: AppSpace.sm),
                      if (_read || widget.backRead)
                        GameButton(
                          key: const ValueKey('found-close'),
                          label: 'BACK TO THE BOX',
                          style: GameButtonStyle.glass,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The painting's back: plain stretched canvas behind its frame, and the
/// words written on it in ink.
class _Back extends StatelessWidget {
  const _Back({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'On the back: $text',
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('found-back'),
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(AppRadius.paper),
          border: Border.all(color: AppColors.goldDeep, width: 6),
          boxShadow: AppShadow.onNight,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const InkIcon(InkGlyph.letter, size: AppIconSize.small, color: AppColors.inkBrown),
            const SizedBox(height: AppSpace.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text, style: AppText.title(size: 30, color: AppColors.burgundy)),
            ),
          ],
        ),
      ),
    );
  }
}
