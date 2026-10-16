import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/audio_service.dart';
import '../../data/models/episode.dart';
import '../../data/models/mission.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/back_to.dart';
import '../../widgets/badge_medal.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/detective_tips.dart';
import '../../widgets/game_button.dart';
import '../../widgets/glossary_text.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/letter_card.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game/scoring.dart';
import '../game/wallet_controller.dart';
import '../mission/widgets/tip_shop.dart';
import '../season/widgets/season_props.dart';
import 'how_to_play_state.dart';

/// How to Play: an eight-page storybook before the first case, shown by
/// the detective partner. It opens and closes on London at night (the
/// cover pages); between them each page is a parchment leaf in a gold frame
/// with its own scene to try — a letter, a witness, a case file, a
/// notebook of words, tip cards, the detective notebook. Everything tried
/// here is practice: no coin, tip, word, clue, badge or case is touched.
///
/// The first time (after registration), its end goes on to the season's
/// casebook, as registration did before; [again] (from the map's menu) goes
/// back where it came from.
class HowToPlayScreen extends ConsumerStatefulWidget {
  const HowToPlayScreen({super.key, this.again = false});

  final bool again;

  /// Pages, in order.
  static const pageCount = 8;

  @override
  ConsumerState<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends ConsumerState<HowToPlayScreen> {
  int _page = 0;

  /// Set once the guide is left: later taps do nothing (no double move).
  bool _leaving = false;

  /// A quick second tap on NEXT / BACK does not skip a page: one move, then
  /// a short rest.
  Timer? _resting;

  // The practice, kept here so BACK and NEXT find each page as it was left.
  bool _letterOpened = false;
  String? _asked;
  String? _chosen;
  bool? _checkedRight;
  final List<String> _wordsSeen = [];
  int _tips = 0;
  int _tipOpen = 0;
  int _practiceCoins = AppConstants.startCoins;
  int _notebookTab = 0;

  bool get _still => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// The open case with no words to look up: the guide's letter and clue
  /// use the game's own widgets, whose dotted words would otherwise be the
  /// case's, and looking one up would be recorded for the parent report.
  late final Episode _noWords = Episode.fromJson({
    ...ref.read(currentEpisodeProvider).toJson(),
    'glossary': const <String, String>{},
  });

  Widget _practice(Widget child) =>
      ProviderScope(overrides: [currentEpisodeProvider.overrideWithValue(_noWords)], child: child);

  @override
  void dispose() {
    _resting?.cancel();
    super.dispose();
  }

  void _move(int to) {
    if (_leaving || to == _page || (_resting?.isActive ?? false)) return;
    _resting = Timer(const Duration(milliseconds: 300), () {});
    setState(() => _page = to.clamp(0, HowToPlayScreen.pageCount - 1));
  }

  void _next() => _move(_page + 1);

  /// Out of the guide, forwards (finished or skipped): learnt, and on.
  void _done() {
    if (_leaving) return;
    _leaving = true;
    ref.read(howToPlaySeenProvider.notifier).complete();
    if (widget.again) {
      context.canPop() ? context.pop() : context.go(Routes.map);
    } else {
      // The way registration always went: the season's casebook, then its
      // opening, then Case 01 (none of them skipped).
      context.go(Routes.season);
    }
  }

  /// BACK (the arrow, or the system back): the page before; from the first
  /// page, where the guide was opened from.
  void _back() {
    if (_leaving) return;
    if (_page > 0) return _move(_page - 1);
    _leaving = true;
    if (widget.again) {
      context.canPop() ? context.pop() : context.go(Routes.map);
    } else {
      context.go(Routes.start);
    }
  }

  void _sound(GameSound s) => ref.read(audioServiceProvider).play(s);

  Future<void> _askTip() async {
    final tip = _tips + 1;
    if (tip > _TipsScene.tips.length) return;
    final price = WalletController.priceOf(tip);
    final state = tipStateOf(tip: tip, revealed: _tips, owns: false, balance: _practiceCoins);
    // As on a case's page: a free hint opens at once; one that costs coins
    // asks first, in the game's own coins dialog.
    if (state != TipState.free) {
      final reveal = await showDialog<bool>(
        context: context,
        barrierColor: AppColors.navyDeep.withValues(alpha: 0.55),
        builder: (dialog) => TipShopCard(
          balance: _practiceCoins,
          price: price,
          state: state,
          onCancel: () => Navigator.of(dialog).pop(false),
          onReveal: () => Navigator.of(dialog).pop(true),
        ),
      );
      if (reveal != true || !mounted) return;
    }
    _sound(GameSound.paperRustle);
    setState(() {
      _tips = tip;
      _tipOpen = tip;
      // Practice coins only; short of them, the partner helps for free.
      if (state == TipState.buy) _practiceCoins -= price;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(gameControllerProvider.select((p) => p.detectiveName));
    return BackTo(
      onBack: _back,
      child: Scaffold(
        backgroundColor: AppColors.nightBottom,
        // Turning a page: the spread fades, a little to the side.
        body: AnimatedSwitcher(
          duration: _still ? Duration.zero : const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          // The page being turned away takes no more taps.
          layoutBuilder: (current, previous) => Stack(
            fit: StackFit.expand,
            children: [
              for (final p in previous) IgnorePointer(child: p),
              ?current,
            ],
          ),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0.03, 0), end: Offset.zero).animate(a),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_page), child: _spread(name)),
        ),
      ),
    );
  }

  Widget _spread(String? name) {
    Widget paper({required String title, required String line, required Widget scene, required String caption}) =>
        _PaperSpread(
          page: _page,
          title: title,
          line: line,
          scene: scene,
          caption: caption,
          onBack: _back,
          onSkip: _done,
          onNext: _next,
        );
    return switch (_page) {
      0 => _WelcomeSpread(name: name, onNext: _next, onBack: _back, onSkip: _done),
      1 => paper(
        title: 'Read the Letter',
        line: 'Every letter holds a clue. Read it carefully!',
        caption: _letterOpened ? 'You can always tap Letter to read it again.' : 'Every case begins with a letter.',
        scene: _practice(
          _LetterScene(
            opened: _letterOpened,
            onOpen: () => _sound(GameSound.envelopeOpen),
            onOpened: () => setState(() => _letterOpened = true),
            onReread: () => _sound(GameSound.paperRustle),
          ),
        ),
      ),
      2 => paper(
        title: 'Talk to People',
        line: 'Ask questions. Listen closely. Every detail matters.',
        caption: 'In some cases, you will meet people to talk to.',
        scene: _WitnessScene(asked: _asked, onAsk: (q) => setState(() => _asked = q)),
      ),
      3 => paper(
        title: 'Solve the Mystery',
        line: 'Look at the clues. Think carefully. Choose your answer.',
        caption: 'This is a practice puzzle. Try any answer!',
        scene: _CaseFileScene(
          chosen: _chosen,
          checkedRight: _checkedRight,
          onChoose: (id) => setState(() {
            _chosen = id;
            _checkedRight = null;
          }),
          onCheck: () {
            final right = _chosen == _CaseFileScene.answer;
            _sound(right ? GameSound.puzzleCorrect : GameSound.puzzleWrong);
            setState(() => _checkedRight = right);
          },
        ),
      ),
      4 => paper(
        title: 'Discover New Words',
        line: 'See a dotted word? Tap it to discover its meaning!',
        caption: "You don't need to know every word. Tap, read, and keep going!",
        scene: _WordsScene(
          seen: _wordsSeen,
          onSeen: (w) => setState(() {
            if (!_wordsSeen.contains(w)) _wordsSeen.add(w);
          }),
        ),
      ),
      5 => paper(
        title: 'Hints When You Need Them',
        line: 'Your first hint is free. More hints cost a few coins.',
        caption: _tips < _TipsScene.tips.length
            ? 'Not enough coins? Your partner still gives you the hint, for free.'
            : 'These were practice coins. Your real coins are safe.',
        scene: _TipsScene(
          revealed: _tips,
          open: _tipOpen,
          coins: _practiceCoins,
          onReveal: _askTip,
          onToggle: (i) => setState(() => _tipOpen = _tipOpen == i ? 0 : i),
        ),
      ),
      6 => paper(
        title: 'Your Detective Notebook',
        line: 'Keep your clues, evidence, and badges in one place.',
        caption: 'Open your notebook at any time during a case.',
        scene: _practice(_NotebookScene(tab: _notebookTab, onTab: (i) => setState(() => _notebookTab = i))),
      ),
      _ => _ReadySpread(
        onStart: _done,
        onBack: _back,
        startLabel: widget.again ? 'BACK TO MY CASE' : 'START FIRST CASE',
      ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The book: its pages, frame, dots and button
// ─────────────────────────────────────────────────────────────────────────────

/// A parchment leaf of the storybook laid on the navy night, inside an
/// antique gold frame: BACK and SKIP at the top, the page's title and line,
/// its scene in the middle, a caption, and the dots with NEXT at the foot.
class _PaperSpread extends StatelessWidget {
  const _PaperSpread({
    required this.page,
    required this.title,
    required this.line,
    required this.scene,
    required this.caption,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
  });

  final int page;
  final String title;
  final String line;
  final Widget scene;
  final String caption;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    // A short phone gives the scene the room: the title and line a little
    // smaller (still the page's largest words).
    final compact = MediaQuery.sizeOf(context).height < 720;
    return ColoredBox(
      color: AppColors.navyDeep,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.sm),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 6))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CustomPaint(
                    foregroundPainter: const _GoldFramePainter(color: AppColors.gold),
                    child: PaperBackground(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.xs, AppSpace.md, AppSpace.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BookBar(onBack: onBack, onSkip: onSkip),
                            MediaQuery.withClampedTextScaling(
                              maxScaleFactor: compact ? 1.1 : 1.2,
                              child: Column(
                                children: [
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: AppText.placeTitle(size: compact ? 24 : 27),
                                  ),
                                  const SizedBox(height: AppSpace.xs),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                                    child: Text(
                                      line,
                                      textAlign: TextAlign.center,
                                      style: AppText.aside(size: compact ? 15 : 16, color: AppColors.inkBrown),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? AppSpace.sm : AppSpace.md),
                            // The scene: centred in the page; on a small
                            // phone, or with large text, it scrolls — its
                            // foot fading into the paper, so more is there.
                            Expanded(
                              child: ShaderMask(
                                blendMode: BlendMode.dstIn,
                                shaderCallback: (rect) => LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: const [Colors.black, Colors.black, Colors.transparent],
                                  stops: [0, 1 - math.min(28 / math.max(rect.height, 1), 0.2), 1],
                                ).createShader(rect),
                                child: LayoutBuilder(
                                  builder: (context, box) => SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpace.sm,
                                      AppSpace.sm,
                                      AppSpace.sm,
                                      AppSpace.xl,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(minHeight: box.maxHeight - AppSpace.sm - AppSpace.xl),
                                      // Large text grows a scene a little, not
                                      // past what its props can hold.
                                      child: Center(
                                        child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.15, child: scene),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            MediaQuery.withClampedTextScaling(
                              maxScaleFactor: compact ? 1.1 : 1.2,
                              child: Text(
                                caption,
                                textAlign: TextAlign.center,
                                style: AppText.bodyText(size: compact ? 14 : 15, color: AppColors.muted),
                              ),
                            ),
                            const SizedBox(height: AppSpace.md),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                              child: Row(
                                children: [
                                  _PageDots(page: page),
                                  const Spacer(),
                                  _StorybookButton(label: 'NEXT', onPressed: onNext),
                                ],
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
        ),
      ),
    );
  }
}

/// BACK and SKIP at the top of a page, in the page's ink (gold on the
/// night cover pages).
class _BookBar extends StatelessWidget {
  const _BookBar({required this.onBack, this.onSkip, this.onNight = false});

  final VoidCallback onBack;
  final VoidCallback? onSkip;
  final bool onNight;

  @override
  Widget build(BuildContext context) {
    final ink = onNight ? AppColors.goldLight : AppColors.inkBrown;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: InkIcon(InkGlyph.back, color: ink),
            onPressed: onBack,
          ),
          const Spacer(),
          if (onSkip != null) InkTextButton(label: 'SKIP', color: ink, onPressed: onSkip),
        ],
      ),
    );
  }
}

/// Where the reader is in the book: a dot a page, the open one longer.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.page, this.onNight = false});

  final int page;
  final bool onNight;

  @override
  Widget build(BuildContext context) {
    const count = HowToPlayScreen.pageCount;
    final done = onNight ? AppColors.goldLight : AppColors.navy;
    final todo = onNight ? AppColors.goldLight.withValues(alpha: 0.3) : AppColors.parchmentDark;
    return Semantics(
      label: 'Page ${page + 1} of $count',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: i == page ? 14 : 6,
              height: 6,
              decoration: BoxDecoration(color: i <= page ? done : todo, borderRadius: BorderRadius.circular(3)),
            ),
        ],
      ),
    );
  }
}

/// The storybook's way on: a navy plate (or, for the first case, a gold
/// one) with an antique gold edge and a fine rule inside it, capitals and
/// an arrow. It presses in a little under the finger.
class _StorybookButton extends StatefulWidget {
  const _StorybookButton({required this.label, required this.onPressed, this.gold = false, this.wide = false});

  final String label;
  final VoidCallback onPressed;
  final bool gold;

  /// The whole width of the page (the last page's one button).
  final bool wide;

  @override
  State<_StorybookButton> createState() => _StorybookButtonState();
}

class _StorybookButtonState extends State<_StorybookButton> {
  bool _pressed = false;

  void _press(bool on) {
    if (_pressed != on) setState(() => _pressed = on);
  }

  @override
  Widget build(BuildContext context) {
    final gold = widget.gold;
    final fill = gold
        ? (_pressed ? AppColors.gold : AppColors.goldLight)
        : (_pressed ? AppColors.navyDeep : AppColors.navy);
    final ink = gold ? AppColors.navyDeep : AppColors.creamGold;
    final edge = gold ? AppColors.goldDeep : AppColors.goldLight.withValues(alpha: 0.9);
    final rule = gold ? AppColors.goldDeep.withValues(alpha: 0.45) : AppColors.goldLight.withValues(alpha: 0.4);
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: () {
          playUiTap(context, gold ? TapRole.primary : TapRole.secondary);
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            constraints: BoxConstraints(
              minHeight: widget.wide ? 58 : 52,
              minWidth: widget.wide ? double.infinity : 136,
            ),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: edge, width: 1.4),
              boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: rule, width: AppLine.hairline),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: widget.wide ? AppSpace.md + 1 : AppSpace.sm + 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          style: AppText.style(
                            AppText.body,
                            size: widget.wide ? 18 : 16,
                            weight: FontWeight.w600,
                            color: ink,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    InkIcon(InkGlyph.arrow, size: AppIconSize.small, color: ink),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The antique gold frame round a storybook page: a firm outer line, a
/// fine one inside it, and a small diamond pressed into each corner.
class _GoldFramePainter extends CustomPainter {
  const _GoldFramePainter({this.color = AppColors.goldLight});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius((Offset.zero & size).deflate(1), const Radius.circular(13));
    final inner = outer.deflate(5);
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = color.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppLine.hairline
        ..color = color.withValues(alpha: 0.45),
    );
    final dot = Paint()..color = color;
    final r = inner.outerRect.deflate(9);
    for (final c in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - 4)
          ..lineTo(c.dx + 4, c.dy)
          ..lineTo(c.dx, c.dy + 4)
          ..lineTo(c.dx - 4, c.dy)
          ..close(),
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(_GoldFramePainter oldDelegate) => oldDelegate.color != color;
}

/// One of the guide's own pictures (see `ArtAssets.onboardingPartner`), at
/// [height], decoded no larger than it shows. A missing file leaves its
/// place empty — never a stand-in drawing. [label]: what it shows, for
/// screen readers (none: decoration).
class _Art extends StatelessWidget {
  const _Art(this.file, {required this.height, this.label, this.fit = BoxFit.contain, this.width, this.alignment});

  final String file;
  final double height;
  final double? width;
  final String? label;
  final BoxFit fit;
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.asset(
      file,
      height: height,
      width: width,
      fit: fit,
      alignment: alignment ?? Alignment.center,
      // Cropped pictures are decoded by width (they are wider than shown).
      cacheHeight: width == null ? (height * dpr).ceil() : null,
      cacheWidth: width == null ? null : (width! * dpr * 1.3).ceil(),
      semanticLabel: label,
      excludeFromSemantics: label == null,
      errorBuilder: (context, error, stack) => SizedBox(width: width, height: width == null ? 0 : height),
    );
  }
}

/// London at night from the opening, filling a cover page: [focus] picks
/// the part of the embankment the page shows, [zoom] how close.
class _NightLondon extends StatelessWidget {
  const _NightLondon({required this.focus, this.zoom = 1});

  final Alignment focus;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    const pixels = ArtAssets.season1LondonNightPixels;
    final size = MediaQuery.sizeOf(context);
    return ClipRect(
      child: Transform.scale(
        scale: zoom,
        alignment: focus,
        child: Image.asset(
          ArtAssets.season1LondonNight,
          fit: BoxFit.cover,
          alignment: focus,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: (size.height * pixels.aspectRatio * zoom * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(
            1,
            pixels.width.toInt(),
          ),
          excludeFromSemantics: true,
          errorBuilder: (context, error, stack) => const ColoredBox(color: AppColors.nightBottom),
        ),
      ),
    );
  }
}

/// A night cover page: [background] full bleed, darkened by [shade]
/// (alphas top to bottom), and [child] inside the gold frame.
class _NightCover extends StatelessWidget {
  const _NightCover({required this.background, required this.shade, required this.child});

  final Widget background;
  final List<(double, double)> shade;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkSurface(
      night: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          background,
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [for (final (_, a) in shade) AppColors.navyDeep.withValues(alpha: a)],
                stops: [for (final (s, _) in shade) s],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  child: CustomPaint(
                    foregroundPainter: const _GoldFramePainter(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.xs, AppSpace.sm, AppSpace.lg),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Words over the night: a soft dark edge under them.
List<Shadow> _nightLift() => [
  Shadow(color: AppColors.navyDeep.withValues(alpha: 0.75), blurRadius: 10, offset: const Offset(0, 1)),
];

/// The partner standing in the scene, lit by the lamps: a warm glow behind
/// them and their boots [behind] the part of the page below (a card, the
/// button), so they stand in the street, not on top of the page.
class _PartnerInScene extends StatelessWidget {
  const _PartnerInScene({required this.file, required this.label, this.behind = 0});

  final String file;
  final String label;
  final double behind;

  /// Never taller than this, on a tall phone or a tablet.
  static const maxHeight = 440.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final h = math.min(box.maxHeight + behind, maxHeight);
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: -behind,
              child: IgnorePointer(
                child: Container(
                  width: h * 0.95,
                  height: h * 0.95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppColors.goldLight.withValues(alpha: 0.24), AppColors.goldLight.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -behind,
              child: _Art(file, height: h, label: label),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 01 · Welcome (night cover)
// ─────────────────────────────────────────────────────────────────────────────

/// The storybook's cover: London at night inside the gold frame, the game's
/// name at the top, the detective partner standing in the street as the
/// page's hero, and a parchment card laid in front of them with the
/// welcome. The dots and NEXT sit at the foot of the frame.
class _WelcomeSpread extends StatelessWidget {
  const _WelcomeSpread({required this.name, required this.onNext, required this.onBack, required this.onSkip});

  final String? name;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    // A short phone keeps the partner the page's hero: a smaller name, one
    // flourish, a tighter card (the words stay readable).
    final compact = screen.height < 720;
    final size = compact ? (screen.width * 0.08).clamp(26.0, 30.0) : (screen.width * 0.1).clamp(30.0, 40.0);
    return _NightCover(
      // The gas lamp on the left, Big Ben on the right, the partner between.
      background: const _NightLondon(focus: Alignment(0.3, 0)),
      shade: const [(0, 0.78), (0.26, 0.4), (0.48, 0.12), (0.66, 0.3), (1, 0.88)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BookBar(onBack: onBack, onSkip: onSkip, onNight: true),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: compact ? 1.05 : 1.15,
            child: Column(
              children: [
                if (!compact) ...[
                  const OrnamentRule(color: AppColors.goldLight, width: 110),
                  const SizedBox(height: AppSpace.xs),
                ],
                for (final word in const ['LONDON', 'MYSTERY'])
                  Text(
                    word,
                    textAlign: TextAlign.center,
                    style: AppText.logo(
                      size: size,
                      color: AppColors.creamGold,
                    ).copyWith(letterSpacing: size * 0.08, height: 1.05, shadows: _nightLift()),
                  ),
                const SizedBox(height: AppSpace.xs),
                const OrnamentRule(color: AppColors.goldLight, width: 110),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Every great mystery begins with a curious mind.',
                  textAlign: TextAlign.center,
                  style: AppText.aside(
                    size: compact ? 15 : 16,
                    color: AppColors.paperLight.withValues(alpha: 0.92),
                  ).copyWith(shadows: _nightLift()),
                ),
              ],
            ),
          ),
          const Expanded(
            child: _PartnerInScene(
              file: ArtAssets.onboardingPartner,
              label: 'Your detective partner, waving hello',
              behind: 40,
            ),
          ),
          // The welcome, on a card laid in front of the partner.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: compact ? 1.1 : 1.2,
              child: PaperSheet(
                color: AppColors.parchment,
                ruled: true,
                tilt: -0.008,
                padding: EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: compact ? AppSpace.md : AppSpace.lg),
                child: Column(
                  children: [
                    Text(
                      'Welcome, Detective!',
                      textAlign: TextAlign.center,
                      style: AppText.placeTitle(size: compact ? 21 : 23),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    const OrnamentRule(width: 96),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      "Hello, Detective${name == null ? '' : ' $name'}! I'm your detective partner. "
                      "Let's find clues and solve mysteries in London together.",
                      textAlign: TextAlign.center,
                      style: AppText.bodyText(size: compact ? 15 : 16, color: AppColors.inkBrown),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            child: Row(
              children: [
                const _PageDots(page: 0, onNight: true),
                const Spacer(),
                _StorybookButton(label: 'NEXT', onPressed: onNext),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 02 · The letter
// ─────────────────────────────────────────────────────────────────────────────

/// The envelope of every mission, large on the page, in the lamplight of a
/// soft ink shadow; once open, its letter, and a paper tab to read it again.
class _LetterScene extends StatelessWidget {
  const _LetterScene({required this.opened, required this.onOpen, required this.onOpened, required this.onReread});

  final bool opened;
  final VoidCallback onOpen;
  final VoidCallback onOpened;
  final VoidCallback onReread;

  static const letter =
      'Dear Detective,\n\n'
      'My little cat, Pip, is lost!\n'
      'Pip loves warm places.\n'
      'Please help me find her.\n\n'
      '— Mr Finch';

  void _reread(BuildContext context) {
    onReread();
    // The open case's words are kept out of the sheet too (practice).
    final scope = ProviderScope.containerOf(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: paperSheetShape,
      showDragHandle: false,
      builder: (sheet) => UncontrolledProviderScope(
        container: scope,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PaperSheetTab(),
                const LetterCard(text: letter),
                const SizedBox(height: AppSpace.lg),
                GameButton(label: 'BACK', onPressed: () => Navigator.of(sheet).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A soft pool of shadow on the page under the letter, where the
        // lamp light falls off.
        CustomPaint(
          painter: const _InkPoolPainter(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: EnvelopeReveal(letterText: letter, initiallyOpen: opened, onOpen: onOpen, onOpened: onOpened),
          ),
        ),
        if (opened) ...[
          const SizedBox(height: AppSpace.md),
          Align(
            alignment: Alignment.centerRight,
            child: _PaperTab(glyph: InkGlyph.letter, label: 'Letter', onTap: () => _reread(context)),
          ),
        ],
      ],
    );
  }
}

/// A soft oval of shadow on the paper, blurred to nothing at its edge.
class _InkPoolPainter extends CustomPainter {
  const _InkPoolPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final pool = Rect.fromCenter(
      center: size.center(const Offset(0, 16)),
      width: size.width * 0.86,
      height: size.height * 0.62,
    );
    canvas.drawOval(
      pool,
      Paint()
        ..color = AppColors.inkBrown.withValues(alpha: 0.13)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
  }

  @override
  bool shouldRepaint(_InkPoolPainter oldDelegate) => false;
}

/// A paper card's lift off the page: its shadow outside it, never on its face.
Widget _lifted({required Widget child, double radius = AppRadius.button}) => DecoratedBox(
  decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: AppShadow.paperLift),
  child: child,
);

/// A small card of paper to tap, lifted off the page (Letter, a question).
class _PaperTab extends StatelessWidget {
  const _PaperTab({required this.label, required this.onTap, this.glyph, this.done = false, this.tilt = 0});

  final String label;
  final VoidCallback onTap;
  final InkGlyph? glyph;
  final bool done;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final tab = Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: _lifted(
        child: Material(
          color: done ? AppColors.parchment : AppColors.paperLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(color: done ? AppColors.gold : AppLine.faint(0.35), width: AppLine.hairline),
          ),
          shadowColor: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.button),
            splashColor: AppColors.inkBrown.withValues(alpha: 0.08),
            onTap: () {
              playUiTap(context, TapRole.select);
              onTap();
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 50),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (glyph != null || done) ...[
                    InkIcon(
                      done ? InkGlyph.check : glyph!,
                      size: AppIconSize.small,
                      color: done ? AppColors.goldDeep : AppColors.navy,
                    ),
                    const SizedBox(width: AppSpace.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: AppText.bodyText(size: 17, weight: FontWeight.w600, color: AppColors.navy),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return tilt == 0 ? tab : Transform.rotate(angle: tilt, child: tab);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 03 · A witness
// ─────────────────────────────────────────────────────────────────────────────

/// Mrs Moss in a gold medallion over a sepia London street, what she says
/// in a paper bubble, and the questions as paper slips to tap.
class _WitnessScene extends StatelessWidget {
  const _WitnessScene({required this.asked, required this.onAsk});

  final String? asked;
  final ValueChanged<String> onAsk;

  static const questions = {'seen': 'Did you see a cat?', 'where': 'Where did she go?'};
  static const answers = {
    null: '"Hello, Detective! I sell tea here every day. Ask me anything!"',
    'seen': '"Yes! A little cat with a red collar ran past my stall."',
    'where': '"She jumped up to the roof, next to the warm chimney."',
  };

  @override
  Widget build(BuildContext context) {
    // A narrow phone gives her words the room.
    final portrait = MediaQuery.sizeOf(context).width < 380 ? 80.0 : 96.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          // A London street, faded into the page like an old print.
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.39, 0.77, 0.19, 0, 0, //
                0.35, 0.69, 0.17, 0, 0,
                0.27, 0.53, 0.13, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: Image.asset(
                ArtAssets.season1LondonNight,
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.1),
                cacheWidth: 700,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stack) => const SizedBox.expand(),
              ),
            ),
          ),
          Positioned.fill(child: ColoredBox(color: AppColors.parchment.withValues(alpha: 0.62))),
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: AppLine.hairline),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        // Her portrait in a gold medallion, as a witness
                        // is shown in the cases.
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.goldLight,
                            border: Border.all(color: AppColors.goldDeep, width: 1.2),
                            boxShadow: AppShadow.paperLift,
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: portrait,
                              height: portrait,
                              child: _Art(
                                ArtAssets.onboardingWitness,
                                width: portrait,
                                height: portrait,
                                fit: BoxFit.cover,
                                alignment: const Alignment(0, -0.55),
                                label: 'Mrs Moss, the tea seller, with a teapot',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text('MRS MOSS', style: AppText.title(size: 16)),
                        Text('Tea seller', style: AppText.aside(size: 13)),
                      ],
                    ),
                    const SizedBox(width: AppSpace.md),
                    // What she says, in a paper bubble.
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpace.sm),
                        child: PaperSheet(
                          padding: const EdgeInsets.all(AppSpace.md),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(answers[asked]!, key: ValueKey(asked), style: AppText.letter(size: 16)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  'ASK A QUESTION',
                  textAlign: TextAlign.center,
                  style: AppText.eyebrow(color: AppColors.goldDeep),
                ),
                const SizedBox(height: AppSpace.sm),
                // The questions, as slips placed a little apart, like notes.
                for (final (i, MapEntry(key: id, value: q)) in questions.entries.indexed)
                  Padding(
                    padding: EdgeInsets.only(bottom: AppSpace.sm, left: i.isOdd ? 28 : 0, right: i.isOdd ? 0 : 28),
                    child: _PaperTab(label: q, done: asked == id, tilt: i.isOdd ? 0.01 : -0.01, onTap: () => onAsk(id)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 04 · A practice case file
// ─────────────────────────────────────────────────────────────────────────────

/// A manila case folder: the lost cat's photo pinned on it, the question,
/// the answers on slips of paper, CHECK ANSWER, and a gentle slip after it.
class _CaseFileScene extends StatelessWidget {
  const _CaseFileScene({
    required this.chosen,
    required this.checkedRight,
    required this.onChoose,
    required this.onCheck,
  });

  final String? chosen;
  final bool? checkedRight;
  final ValueChanged<String> onChoose;
  final VoidCallback onCheck;

  static const answer = 'roof';
  static const options = {'river': 'In the cold river', 'roof': 'On the warm roof', 'garden': 'In the snowy garden'};

  @override
  Widget build(BuildContext context) {
    return CaseFolder(
      tab: 'PRACTICE CASE · THE LOST CAT',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Pip's photo, pinned to the folder.
                Transform.rotate(
                  angle: -0.05,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      PrintFrame(
                        border: 4,
                        bottom: 10,
                        child: Container(
                          width: 104,
                          height: 104,
                          color: AppColors.paperLight,
                          child: const _Art(
                            ArtAssets.onboardingCat,
                            height: 104,
                            label: 'Pip, a little ginger cat with a red collar',
                          ),
                        ),
                      ),
                      const Positioned(top: -4, child: PushPin(size: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MISSING', style: AppText.eyebrow(color: AppColors.burgundy)),
                      const SizedBox(height: AppSpace.xs),
                      Text('Where is Pip, the little cat?', style: AppText.title(size: 20)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            for (final MapEntry(key: id, value: label) in options.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: _Choice(label: label, chosen: chosen == id, onTap: () => onChoose(id)),
              ),
            const SizedBox(height: AppSpace.xs),
            GameButton(label: 'CHECK ANSWER', onPressed: chosen == null ? null : onCheck),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: switch (checkedRight) {
                null => const SizedBox(width: double.infinity),
                true => const _Slip(
                  key: ValueKey('right'),
                  title: 'Well done!',
                  text: 'Pip loves warm places, and Mrs Moss saw her by the chimney.',
                  color: AppColors.success,
                ),
                false => const _Slip(
                  key: ValueKey('wrong'),
                  title: 'Not quite!',
                  text: 'Good detectives look again. What does Pip love? Read the letter again.',
                  color: AppColors.tryAgain,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// An answer on a slip of paper, inked navy when chosen.
class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.chosen, required this.onTap});

  final String label;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: chosen,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: chosen ? AppColors.navy : AppColors.paperLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          side: BorderSide(
            color: chosen ? AppColors.goldLight.withValues(alpha: 0.7) : AppLine.faint(0.4),
            width: AppLine.hairline,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          onTap: () {
            playUiTap(context, TapRole.select);
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
              child: Row(
                children: [
                  // A tick box, printed on the slip.
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: chosen ? AppColors.goldLight : AppColors.inkBrown.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: chosen ? const InkIcon(InkGlyph.check, size: 16, color: AppColors.goldLight) : null,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      label,
                      style: AppText.bodyText(size: 17, color: chosen ? AppColors.paperLight : AppColors.ink),
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

/// The answer's slip, as gentle as the game's: never a red cross.
class _Slip extends StatelessWidget {
  const _Slip({super.key, required this.title, required this.text, required this.color});

  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: PaperSheet(
        tilt: 0.008,
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          children: [
            Text(title, style: AppText.title(size: 22, color: color)),
            const SizedBox(height: AppSpace.xs),
            OrnamentRule(color: color, width: 90),
            const SizedBox(height: AppSpace.xs),
            Text(text, textAlign: TextAlign.center, style: AppText.bodyText(size: 16)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 05 · Words
// ─────────────────────────────────────────────────────────────────────────────

/// The detective's word book: a leather-bound page with ruled lines and a
/// red margin, a sentence with dotted words, and a paper note pinned to the
/// page for each word looked up.
class _WordsScene extends StatefulWidget {
  const _WordsScene({required this.seen, required this.onSeen});

  final List<String> seen;
  final ValueChanged<String> onSeen;

  static const sentence = 'Pip is asleep by the warm chimney.';
  static const meanings = {'asleep': '잠든', 'chimney': '굴뚝'};

  @override
  State<_WordsScene> createState() => _WordsSceneState();
}

class _WordsSceneState extends State<_WordsScene> {
  final List<TapGestureRecognizer> _taps = [];

  @override
  void dispose() {
    for (final t in _taps) {
      t.dispose();
    }
    super.dispose();
  }

  /// The word card of the game — practice words, not recorded anywhere.
  void _show(String word) {
    widget.onSeen(word);
    showWordMeaning(context, word, _WordsScene.meanings[word]!);
  }

  @override
  Widget build(BuildContext context) {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
    final spans = <InlineSpan>[];
    for (final m in RegExp(r'[A-Za-z]+|[^A-Za-z]+').allMatches(_WordsScene.sentence)) {
      final token = m.group(0)!;
      if (!_WordsScene.meanings.containsKey(token)) {
        spans.add(TextSpan(text: token));
        continue;
      }
      final tap = TapGestureRecognizer()..onTap = () => _show(token);
      _taps.add(tap);
      // Dotted like every word with a meaning in the game.
      spans.add(
        TextSpan(
          text: token,
          recognizer: tap,
          semanticsLabel: '$token (tap for meaning)',
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: AppColors.royalBlue,
            decorationThickness: 2.2,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.sm, AppSpace.sm, AppSpace.sm),
      decoration: BoxDecoration(
        color: AppColors.leather,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppShadow.paperLift,
      ),
      child: CustomPaint(
        painter: const _RuledPagePainter(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 230),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(44, AppSpace.lg, AppSpace.lg, AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MY WORD BOOK', style: AppText.eyebrow(color: AppColors.burgundy)),
                const SizedBox(height: AppSpace.sm),
                Text.rich(TextSpan(children: spans), style: AppText.letter(size: 23).copyWith(height: 1.6)),
                const SizedBox(height: AppSpace.md),
                // The words looked up, as paper notes on the page.
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (final (i, w) in widget.seen.indexed)
                      Transform.rotate(
                        angle: i.isEven ? -0.03 : 0.025,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E7B8),
                            boxShadow: AppShadow.paperLift,
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: AppLine.hairline),
                          ),
                          child: Text('$w = ${_WordsScene.meanings[w]}', style: AppText.letter(size: 17)),
                        ),
                      ),
                    if (widget.seen.isEmpty)
                      Text('Tap a dotted word.', style: AppText.aside(size: 15, color: AppColors.royalBlue)),
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

/// A notebook page inside its leather: paper, faint blue lines, a red
/// margin and the dots of a binding down the left.
class _RuledPagePainter extends CustomPainter {
  const _RuledPagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final page = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6));
    canvas.drawRRect(page, Paint()..color = AppColors.paperLight);
    canvas.save();
    canvas.clipRRect(page);
    final line = Paint()
      ..color = AppColors.royalBlue.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    for (var y = 52.0; y < size.height - 8; y += 30) {
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), line);
    }
    canvas.drawLine(
      const Offset(34, 0),
      Offset(34, size.height),
      Paint()
        ..color = AppColors.burgundy.withValues(alpha: 0.35)
        ..strokeWidth = 1.2,
    );
    final hole = Paint()..color = AppColors.leather.withValues(alpha: 0.55);
    for (var y = 22.0; y < size.height - 12; y += 34) {
      canvas.drawCircle(Offset(15, y), 3.2, hole);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RuledPagePainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 06 · Tips and coins
// ─────────────────────────────────────────────────────────────────────────────

/// The coins in hand (practice ones), and the two Detective Tips as paper
/// cards: the next one to ask for (GET A TIP, its price), the ones opened,
/// folding open and shut, and the one after it still sealed.
class _TipsScene extends StatelessWidget {
  const _TipsScene({
    required this.revealed,
    required this.open,
    required this.coins,
    required this.onReveal,
    required this.onToggle,
  });

  final int revealed;
  final int open;
  final int coins;
  final VoidCallback onReveal;
  final ValueChanged<int> onToggle;

  static const tips = [
    'Read the letter again. What does Pip love?',
    'Mrs Moss saw Pip next to the warm chimney. Where are chimneys?',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The coins in hand, top right, as on a case's page.
        Align(
          alignment: Alignment.centerRight,
          child: Semantics(
            label: 'Practice coins: $coins',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs + 2),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.8), width: 1.2),
                boxShadow: AppShadow.paperLift,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('PRACTICE', style: AppText.eyebrow(color: AppColors.goldLight).copyWith(fontSize: 11)),
                  const SizedBox(width: AppSpace.sm),
                  const InkIcon(InkGlyph.coin, size: AppIconSize.small, color: AppColors.goldLight),
                  const SizedBox(width: AppSpace.xs),
                  Text('$coins', style: AppText.title(size: 18, color: AppColors.creamGold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        for (var i = 1; i <= tips.length; i++) ...[
          _TipCard(
            number: i,
            text: tips[i - 1],
            state: i <= revealed ? (open == i ? _Tip.open : _Tip.shut) : (i == revealed + 1 ? _Tip.next : _Tip.sealed),
            price: WalletController.priceOf(i),
            onTap: i <= revealed ? () => onToggle(i) : (i == revealed + 1 ? onReveal : null),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        Text(
          revealed == 0
              ? 'Good detectives use hints.'
              : 'Hint ${math.min(revealed + 1, tips.length)} of ${tips.length}',
          textAlign: TextAlign.center,
          style: AppText.caption(color: AppColors.inkBrown),
        ),
      ],
    );
  }
}

enum _Tip { next, open, shut, sealed }

/// One Detective Tip as a paper card with its lamp-bulb: GET A TIP and its
/// price on the next, its words when open, a fold when shut.
class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.number,
    required this.text,
    required this.state,
    required this.price,
    required this.onTap,
  });

  final int number;
  final String text;
  final _Tip state;
  final int price;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sealed = state == _Tip.sealed;
    final lit = state == _Tip.open || state == _Tip.shut;
    final header = Row(
      children: [
        InkIcon(
          InkGlyph.hint,
          size: AppIconSize.medium,
          color: lit ? AppColors.goldDeep : (sealed ? AppColors.locked : AppColors.gold),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            'DETECTIVE HINT $number',
            style: AppText.eyebrow(color: sealed ? AppColors.locked : AppColors.goldDeep),
          ),
        ),
        switch (state) {
          _Tip.next => Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.6), width: AppLine.hairline),
            ),
            child: Text(
              price == 0 ? 'GET A FREE HINT' : tipButtonLabel,
              style: AppText.eyebrow(color: AppColors.creamGold).copyWith(fontSize: 11),
            ),
          ),
          _Tip.open => const InkIcon(InkGlyph.down, size: AppIconSize.small, color: AppColors.inkBrown),
          _Tip.shut => Transform.rotate(
            angle: -math.pi / 2,
            child: const InkIcon(InkGlyph.down, size: AppIconSize.small, color: AppColors.inkBrown),
          ),
          _Tip.sealed => const InkIcon(InkGlyph.lock, size: AppIconSize.small, color: AppColors.locked),
        },
      ],
    );
    return Semantics(
      button: onTap != null,
      child: Opacity(
        opacity: sealed ? 0.6 : 1,
        child: _lifted(
          child: Material(
            color: lit ? AppColors.paperLight : AppColors.parchment,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              side: BorderSide(
                color: AppColors.gold.withValues(alpha: lit ? 0.7 : 0.4),
                width: AppLine.hairline,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.button),
              onTap: onTap == null
                  ? null
                  : () {
                      playUiTap(context, TapRole.select);
                      onTap!();
                    },
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.all(AppSpace.md),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      // What the next tip costs: FREE, or its coins.
                      if (state == _Tip.next)
                        Padding(
                          padding: const EdgeInsets.only(left: AppIconSize.medium + AppSpace.sm, top: 2),
                          child: Row(
                            children: [
                              if (price > 0) ...[
                                const InkIcon(InkGlyph.coin, size: AppIconSize.tiny, color: AppColors.goldDeep),
                                const SizedBox(width: AppSpace.xs),
                              ],
                              Text(
                                price > 0 ? '$price coins' : 'FREE',
                                style: AppText.bodyText(size: 15, weight: FontWeight.w700, color: AppColors.navy),
                              ),
                            ],
                          ),
                        ),
                      if (state == _Tip.open) ...[
                        const SizedBox(height: AppSpace.sm),
                        Divider(height: 1, color: AppColors.gold.withValues(alpha: 0.3)),
                        const SizedBox(height: AppSpace.sm),
                        Text(text, style: AppText.letter(size: 17)),
                      ],
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// 07 · The notebook
// ─────────────────────────────────────────────────────────────────────────────

/// The detective notebook as a leather book: a stitched cover, a ribbon, a
/// gold name plate, and a page of three index rows — CLUES, EVIDENCE,
/// BADGES — the open one showing what it keeps.
class _NotebookScene extends StatelessWidget {
  const _NotebookScene({required this.tab, required this.onTab});

  final int tab;
  final ValueChanged<int> onTab;

  static const rows = [
    (glyph: InkGlyph.search, label: 'CLUES', about: 'What you found out.'),
    (glyph: InkGlyph.folder, label: 'EVIDENCE', about: 'Things you collect on a case.'),
    (glyph: InkGlyph.seal, label: 'BADGES', about: 'Awards for good detective work.'),
  ];

  @override
  Widget build(BuildContext context) {
    final contents = [
      const ClueCard(
        clue: Clue(id: 'howToPlay.clue', title: 'Warm Places', value: 'Warm', note: 'Pip loves warm places.'),
        index: 0, // CLUE #01
      ),
      const _PracticeEvidence(),
      const Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpace.lg,
        runSpacing: AppSpace.md,
        children: [
          BadgeMedal(badge: GameBadge.firstClue, size: 56),
          BadgeMedal(badge: GameBadge.puzzleSolver, earned: false, size: 56),
          BadgeMedal(badge: GameBadge.masterDetective, earned: false, size: 56),
        ],
      ),
    ];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5A3529), AppColors.leather, AppColors.leatherDeep],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 6))],
          ),
          foregroundDecoration: const _StitchedEdge(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The gold name plate on the cover.
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs + 2),
                  decoration: BoxDecoration(
                    color: AppColors.leatherDeep,
                    border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.85), width: 1.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('DETECTIVE NOTEBOOK', style: AppText.eyebrow(color: AppColors.goldLight)),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              // The page inside.
              Container(
                padding: const EdgeInsets.all(AppSpace.sm),
                decoration: BoxDecoration(
                  color: AppColors.paperLight,
                  borderRadius: BorderRadius.circular(AppRadius.paper),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: AppLine.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, r) in rows.indexed) ...[
                      _IndexRow(glyph: r.glyph, label: r.label, about: r.about, open: tab == i, onTap: () => onTab(i)),
                      if (tab == i)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xs, AppSpace.xs, AppSpace.md),
                          child: contents[i],
                        ),
                      if (i < rows.length - 1) Divider(height: 1, color: AppColors.inkBrown.withValues(alpha: 0.15)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // The ribbon bookmark over the top edge.
        Positioned(
          left: 16,
          top: -6,
          child: Container(
            width: 14,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.burgundy,
              boxShadow: [BoxShadow(color: Color(0x44000000), blurRadius: 3, offset: Offset(1, 2))],
            ),
          ),
        ),
      ],
    );
  }
}

/// A row of the notebook's index: its picture, its name, what it keeps,
/// and a chevron that turns when it is open.
class _IndexRow extends StatelessWidget {
  const _IndexRow({
    required this.glyph,
    required this.label,
    required this.about,
    required this.open,
    required this.onTap,
  });

  final InkGlyph glyph;
  final String label;
  final String about;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: open,
      child: InkWell(
        onTap: () {
          playUiTap(context, TapRole.select);
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.sm),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: open ? AppColors.navy : AppColors.parchment,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: 1),
                  ),
                  child: InkIcon(
                    glyph,
                    size: AppIconSize.small,
                    color: open ? AppColors.goldLight : AppColors.inkBrown,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppText.style(
                          AppText.body,
                          size: 15,
                          weight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(about, style: AppText.bodyText(size: 14, color: AppColors.muted)),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: open ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: const InkIcon(InkGlyph.down, size: AppIconSize.small, color: AppColors.inkBrown),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The stitching round the notebook's leather cover.
class _StitchedEdge extends Decoration {
  const _StitchedEdge();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _StitchedEdgePainter();
}

class _StitchedEdgePainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final r = RRect.fromRectAndRadius((offset & configuration.size!).deflate(5), const Radius.circular(8));
    final paint = Paint()
      ..color = AppColors.goldLight.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final m in (Path()..addRRect(r)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), paint);
      }
    }
  }
}

/// A piece of evidence in the notebook, as practice (the letter of page 2).
class _PracticeEvidence extends StatelessWidget {
  const _PracticeEvidence();

  @override
  Widget build(BuildContext context) {
    return PaperSheet(
      ruled: true,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(AppRadius.paper),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: AppLine.rule),
            ),
            child: const InkIcon(InkGlyph.letter, size: AppIconSize.large, color: AppColors.inkBrown),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Mr Finch's Letter", style: AppText.title(size: 18)),
                Text('Tap evidence to look closer.', style: AppText.bodyText(size: 14, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 08 · The first case (night cover)
// ─────────────────────────────────────────────────────────────────────────────

/// The book's last page, the cover's twin: the same London night, further
/// along the embankment towards Big Ben, the partner setting off with the
/// letter and the magnifying glass, the season's name, and the gold
/// START FIRST CASE.
class _ReadySpread extends ConsumerWidget {
  const _ReadySpread({required this.onStart, required this.onBack, required this.startLabel});

  final VoidCallback onStart;
  final VoidCallback onBack;
  final String startLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(seasonInfoProvider);
    return _NightCover(
      // Closer in, towards the clock tower: the adventure begins there.
      background: const _NightLondon(focus: Alignment(0.75, -0.1), zoom: 1.12),
      shade: const [(0, 0.8), (0.3, 0.42), (0.55, 0.15), (0.78, 0.45), (1, 0.92)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BookBar(onBack: onBack, onNight: true),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.15,
            child: Column(
              children: [
                Text(
                  'Your First Case Awaits!',
                  textAlign: TextAlign.center,
                  style: AppText.placeTitle(size: 28, color: AppColors.creamGold).copyWith(shadows: _nightLift()),
                ),
                const SizedBox(height: AppSpace.xs),
                const OrnamentRule(color: AppColors.goldLight, width: 120),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Trust your eyes. Follow the clues. The mystery begins!',
                  textAlign: TextAlign.center,
                  style: AppText.aside(
                    size: 16,
                    color: AppColors.paperLight.withValues(alpha: 0.92),
                  ).copyWith(shadows: _nightLift()),
                ),
              ],
            ),
          ),
          const Expanded(
            child: _PartnerInScene(
              file: ArtAssets.onboardingPartnerReady,
              label: 'Your detective partner, setting off',
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.15,
            child: Column(
              children: [
                Text(
                  season.label,
                  textAlign: TextAlign.center,
                  style: AppText.eyebrow(color: AppColors.goldLight),
                ),
                Text(
                  season.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppText.placeTitle(size: 20, color: AppColors.paperLight).copyWith(shadows: _nightLift()),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  "I'll be right here with tips whenever you need me.",
                  textAlign: TextAlign.center,
                  style: AppText.aside(
                    size: 15,
                    color: AppColors.paperLight.withValues(alpha: 0.85),
                  ).copyWith(shadows: _nightLift()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            child: _StorybookButton(label: startLabel, gold: true, wide: true, onPressed: onStart),
          ),
          const SizedBox(height: AppSpace.md),
          const Center(child: _PageDots(page: HowToPlayScreen.pageCount - 1, onNight: true)),
        ],
      ),
    );
  }
}
