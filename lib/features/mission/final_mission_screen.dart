import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/audio_service.dart';
import '../../data/models/mission.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/evidence_card.dart';
import '../../widgets/game_button.dart';
import '../../widgets/glossary_text.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/landmark_art.dart';
import '../../widgets/letter_card.dart';
import '../../widgets/paper.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/desk_background.dart';
import '../../widgets/symbol_icon.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import 'widgets/answer_feedback.dart';
import 'widgets/question_widgets.dart';

/// The final case: four picture locks. The player must combine what they
/// collected — the lock order (Crown Symbol evidence) and the number each
/// place gave them (clues) — to open the Royal Box.
class FinalMissionScreen extends ConsumerStatefulWidget {
  const FinalMissionScreen({super.key});

  @override
  ConsumerState<FinalMissionScreen> createState() => _FinalMissionScreenState();
}

class _FinalMissionScreenState extends ConsumerState<FinalMissionScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  final _scroll = ScrollController();
  late List<int> _digits;
  int _wrongPulse = 0;

  /// The locks (question, dials, OPEN): a returning detective lands here,
  /// and the letter is one tap away instead of a scroll back up.
  final _locksKey = GlobalKey();

  Mission get _mission => ref.read(currentEpisodeProvider).finalMission;

  @override
  void initState() {
    super.initState();
    final length = _mission.codeLength ?? _mission.answer.length;
    _digits = List.filled(length, 0);
    final progress = ref.read(gameControllerProvider);
    if (progress.isCaseSolved) {
      _open.value = 1;
    } else {
      // Back again (the story and the letter were read before): open on the locks.
      final returning = progress.missionStartedAt.containsKey(_mission.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gameControllerProvider.notifier).markMissionStarted(_mission.id);
        final locks = _locksKey.currentContext;
        if (returning && locks != null && locks.mounted) Scrollable.ensureVisible(locks, alignment: 0.05);
      });
    }
  }

  @override
  void dispose() {
    _open.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _turn(int index, int delta) {
    ref.read(audioServiceProvider).play(GameSound.tap);
    setState(() => _digits[index] = (_digits[index] + delta) % 10);
  }

  void _showHint() => ref.read(gameControllerProvider.notifier).useHint(_mission);

  Future<void> _tryOpen() => _submit(_digits.join());

  Future<void> _submit(String answer) async {
    final audio = ref.read(audioServiceProvider);
    final outcome = ref.read(gameControllerProvider.notifier).submitAnswer(_mission, answer);
    switch (outcome.result) {
      case SubmitResult.locked:
        context.go(Routes.map);
      case SubmitResult.tryAgain:
        audio.play(GameSound.wrong);
        setState(() => _wrongPulse++);
        final canHint = ref.read(gameControllerProvider).hintsFor(_mission.id) < _mission.hints.length;
        final choice = await showTryAgainSheet(context, hintAvailable: canHint);
        if (choice == TryAgainChoice.hint && mounted) _showHint();
      case SubmitResult.correct:
        audio.play(GameSound.finale);
        // Bring the box into view so the child sees it open.
        // (The puzzle is removed now, so wait a frame for the new layout.)
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        if (_scroll.hasClients && _scroll.offset > 0) {
          await _scroll.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
        }
        if (mounted) await _open.forward();
    }
  }

  void _rereadLetter() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xl),
          child: Column(
            children: [
              LetterCard(text: _mission.letter),
              const SizedBox(height: AppSpace.xl),
              GameButton(label: 'BACK TO THE LOCKS', onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }

  void _peekNotebook() {
    final episode = ref.read(currentEpisodeProvider);
    final progress = ref.read(gameControllerProvider);
    final clues = progress.collectedClues(episode);
    final evidence = progress.collectedEvidence(episode);
    String locationOfClue(Clue c) => episode.allMissions.firstWhere((m) => m.clue?.id == c.id).location;
    String locationOfEvidence(Evidence e) => episode.allMissions.firstWhere((m) => m.evidence?.id == e.id).location;
    final earlierCases = ref.read(seasonProvider).solvedEpisodeIds.any((id) => id != episode.id);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Paper, not an app sheet (this sheet only; the others keep the app's
      // sheet theme): nearly square corners, and a thin ink-brown tab in
      // place of the grey handle (it still drags to close).
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.paper))),
      showDragHandle: false,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (context, scroll) => Column(
          children: [
            // The tab, in the handle's own 48 dp slot, fixed above the
            // scrolling notebook as the handle was.
            Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.only(top: 22, bottom: 23),
              decoration: BoxDecoration(
                color: AppColors.inkBrown.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text('DETECTIVE NOTEBOOK', style: AppText.eyebrow(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Evidence', style: AppText.title(size: 20)),
            const SizedBox(height: 8),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: evidenceGridDelegate(context),
              children: [for (final e in evidence) EvidenceTile(evidence: e, location: locationOfEvidence(e))],
            ),
            const SizedBox(height: 16),
            Text('Clues', style: AppText.title(size: 20)),
            const SizedBox(height: 8),
            for (final (i, c) in clues.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClueCard(clue: c, index: i, location: locationOfClue(c)),
              ),
            // Earlier cases (e.g. Case 12 needs them): their evidence is in
            // the archive. Hidden while no other case has been solved.
            if (earlierCases) ...[
              const SizedBox(height: 8),
              GameButton(
                label: 'OPEN THE CASE ARCHIVE',
                glyph: InkGlyph.folder,
                style: GameButtonStyle.outline,
                onPressed: () {
                  Navigator.of(context).pop();
                  this.context.push(Routes.archive);
                },
              ),
            ],
          ],
        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(currentEpisodeProvider).finalMission;
    final progress = ref.watch(gameControllerProvider);
    final solved = progress.isCaseSolved;

    return Scaffold(
      // The night page runs up under the app bar (no paper band on top).
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: AppColors.goldLight,
        iconTheme: const IconThemeData(color: AppColors.goldLight),
        titleTextStyle: AppText.eyebrow(color: AppColors.goldLight),
        title: const Text('FINAL MISSION'),
        leading: IconButton(
          tooltip: 'Back to map',
          icon: const InkIcon(InkGlyph.back),
          onPressed: () => context.go(Routes.map),
        ),
      ),
      // The last evidence and papers, examined on the detective's desk.
      body: DeskBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              // Built whole (not lazily), so the page can open on the locks.
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.sm, AppSpace.xl, AppSpace.xxxl),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The app bar already says FINAL MISSION: the page starts on the place.
                  Text(
                    m.location,
                    style: AppText.logo(size: 28, color: AppColors.goldLight),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  const Center(child: OrnamentRule(color: AppColors.goldLight)),
                  const SizedBox(height: 12),
                  // A smaller stage on a small phone, so the story and the locks
                  // come sooner; the full 250 on taller screens.
                  SizedBox(
                    height: (MediaQuery.sizeOf(context).height * 0.3).clamp(160.0, 250.0),
                    child: ClipRect(
                      child: m.scene == Artwork.royalBox
                          ? RoyalBoxAnimation(animation: _open)
                          : _SceneReveal(scene: m.scene, animation: _open),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // The story gives way to the banner: the height eases over
                  // instead of jumping.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: AnimatedBuilder(
                      animation: _open,
                      builder: (context, _) => _open.value > 0.55
                          ? _CaseSolvedBanner(
                              progress: _open.value,
                              message: m.successMessage,
                              detectiveName: progress.detectiveName ?? '',
                            )
                          : _intro(m),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  if (!solved) ..._puzzle(m, progress.hintsFor(m.id)) else _solvedActions(),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _intro(Mission m) => Column(
    children: [
      for (final line in m.story)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlossaryText(
            line,
            textAlign: TextAlign.center,
            style: AppText.subtitle(color: AppColors.paperLight),
          ),
        ),
      const SizedBox(height: 12),
      LetterCard(text: m.letter, tilt: 0.01),
    ],
  );

  List<Widget> _puzzle(Mission m, int hintsShown) => [
    Text(
      key: _locksKey,
      m.question,
      textAlign: TextAlign.center,
      style: AppText.title(size: 24, color: AppColors.goldLight),
    ),
    const SizedBox(height: 16),
    if (m.type == MissionType.finalCode) ...[
      ShakeOnChange(
        trigger: _wrongPulse,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _digits.length; i++)
              Flexible(
                child: _Dial(
                  value: _digits[i],
                  index: i,
                  symbol: i < m.dialSymbols.length ? m.dialSymbols[i] : null,
                  onUp: () => _turn(i, 1),
                  onDown: () => _turn(i, 9),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      // Custom Asset Required: an open-lock glyph for this button.
      GameButton(
        label: m.scene == Artwork.royalBox ? 'OPEN THE BOX' : 'UNLOCK',
        style: GameButtonStyle.glass,
        onPressed: _tryOpen,
      ),
      // The letter again, without scrolling back up (as on every puzzle).
      Center(
        child: InkTextButton(label: 'Letter', glyph: InkGlyph.letter, color: AppColors.goldLight, onPressed: _rereadLetter),
      ),
    ] else
      // Any other puzzle type: the case's last page, laid on the desk.
      ShakeOnChange(
        trigger: _wrongPulse,
        child: PaperSheet(padding: const EdgeInsets.all(AppSpace.lg), child: questionFor(m, _submit)),
      ),
    const SizedBox(height: 12),
    GameButton(
      label: 'OPEN MY NOTEBOOK',
      glyph: InkGlyph.notebook,
      style: GameButtonStyle.outline,
      onPressed: _peekNotebook,
    ),
    const SizedBox(height: 18),
    TipsPanel(hints: m.hints, revealed: hintsShown, onReveal: _showHint, dark: true),
  ];

  Widget _solvedActions() => AnimatedBuilder(
    animation: _open,
    builder: (context, child) => Opacity(opacity: ((_open.value - 0.8) / 0.2).clamp(0, 1), child: child),
    child: GameButton(
      label: 'SEE MY CASE REPORT',
      glyph: InkGlyph.folder,
      style: GameButtonStyle.glass,
      onPressed: () => context.go(Routes.solved),
    ),
  );
}

/// One lock: a picture on top and a number wheel below.
class _Dial extends StatelessWidget {
  const _Dial({
    required this.value,
    required this.index,
    required this.symbol,
    required this.onUp,
    required this.onDown,
  });

  final int value;
  final int index;
  final String? symbol;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final label = GameSymbol.of(symbol).label;
    // A brass lock plate with its picture, wheel and two levers.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDeep],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.goldDeep, width: AppLine.hairline),
        boxShadow: AppShadow.onNight,
      ),
      foregroundDecoration: const RuledFrame(color: AppColors.navyDeep, inset: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (symbol != null) SymbolBadge(symbol, size: 46, light: true),
          IconButton(
            tooltip: 'Lock ${index + 1} up',
            onPressed: onUp,
            color: AppColors.navy,
            // The ink "down" arrow turned over (no separate up glyph).
            icon: const RotatedBox(quarterTurns: 2, child: InkIcon(InkGlyph.down, size: AppIconSize.large)),
          ),
          Container(
            width: 58,
            height: 66,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.goldDeep, width: AppLine.rule),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Text(
                '$value',
                key: ValueKey(value),
                semanticsLabel: 'Lock ${index + 1}, $label: $value',
                style: AppText.title(size: 36, color: AppColors.goldLight),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Lock ${index + 1} down',
            onPressed: onDown,
            color: AppColors.navy,
            icon: const InkIcon(InkGlyph.down, size: AppIconSize.large),
          ),
        ],
      ),
    );
  }
}

class _CaseSolvedBanner extends StatelessWidget {
  const _CaseSolvedBanner({required this.progress, required this.message, required this.detectiveName});

  final double progress;
  final String message;
  final String detectiveName;

  @override
  Widget build(BuildContext context) {
    final t = ((progress - 0.55) / 0.35).clamp(0.0, 1.0);
    return Opacity(
      opacity: t,
      child: Transform.scale(
        scale: 0.92 + 0.08 * Curves.easeOutCubic.transform(t),
        child: Column(
          children: [
            const InkStamp('CASE SOLVED', color: AppColors.gold, size: 26),
            const SizedBox(height: 14),
            Text(
              message,
              style: AppText.title(size: 24, color: AppColors.paperLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Brilliant work, Detective $detectiveName!',
              style: AppText.subtitle(color: AppColors.goldLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// The final place of a case other than Episode 01: its scene, printed like
/// a storybook picture, settles into place when the case is solved.
class _SceneReveal extends StatelessWidget {
  const _SceneReveal({required this.scene, required this.animation});

  final Artwork scene;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(animation.value);
        return Transform.scale(
          scale: 1 + 0.04 * t,
          child: Center(
            child: AspectRatio(
              aspectRatio: LandmarkArt.aspectOf(scene),
              child: PaperSheet(
                padding: const EdgeInsets.all(AppSpace.sm),
                tilt: -0.01,
                // The picture changes with the solve (the Case 02 clock starts again).
                child: LandmarkArt(scene, borderRadius: 2, solved: t),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The Royal Box: closed → lid lifts → light rays → crown rises.
class RoyalBoxAnimation extends StatelessWidget {
  const RoyalBoxAnimation({super.key, required this.animation, this.art = ArtAssets.royalBox});

  /// 0 = shut (the puzzle), 1 = open with the Crown (solved, or a revisit).
  final Animation<double> animation;

  /// The box's two pictures, or null to draw it in code (see [ArtAssets.royalBox]).
  final RoyalBoxArt? art;

  @override
  Widget build(BuildContext context) {
    final pictures = art;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final shake = t < 0.2 ? math.sin(t * 90) * 4 * (1 - t / 0.2) : 0.0;
        // The heavy lid swings open and settles (no spring back).
        final lid = Curves.easeOutCubic.transform(((t - 0.2) / 0.3).clamp(0, 1));
        final crown = Curves.easeOutCubic.transform(((t - 0.4) / 0.45).clamp(0, 1));
        final drawn = CustomPaint(
          painter: _RoyalBoxPainter(lid: lid, crown: crown, rays: t),
          child: const SizedBox.expand(),
        );
        if (pictures == null) return Transform.translate(offset: Offset(shake, 0), child: drawn);
        // The painted box: the same timing — it shakes, the light comes
        // out as it opens (drawn behind it), the open picture (Crown in it)
        // takes over from the shut one as the lid would swing.
        Widget picture(String file, double opacity) => Opacity(
              opacity: opacity,
              child: Image.asset(
                file,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                width: double.infinity,
                height: double.infinity,
                excludeFromSemantics: true,
                // A missing or broken picture: the box drawn in code.
                errorBuilder: (context, error, stack) => drawn,
              ),
            );
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _RoyalBoxPainter(lid: lid, crown: 0, rays: t, raysOnly: true)),
              if (lid < 1) picture(pictures.closed, 1 - lid),
              if (lid > 0) picture(pictures.open, lid),
            ],
          ),
        );
      },
    );
  }
}

class _RoyalBoxPainter extends CustomPainter {
  _RoyalBoxPainter({required this.lid, required this.crown, required this.rays, this.raysOnly = false});

  /// Only the light from the opening box (behind a painted box).
  final bool raysOnly;

  final double lid;
  final double crown;
  final double rays;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final boxW = math.min(size.width * 0.7, 260.0);
    final boxH = boxW * 0.5;
    final boxTop = size.height - boxH - 8;
    final body = Rect.fromLTWH(cx - boxW / 2, boxTop, boxW, boxH);
    final ink = Paint()
      ..color = AppColors.navyDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Light rays (kept inside the canvas so clipping never shows hard edges).
    if (lid > 0) {
      final center = Offset(cx, boxTop);
      final len = math.min(size.height, size.width / 2) * 0.95;
      for (var i = 0; i < 12; i++) {
        final a = -math.pi + (i + 0.5) * math.pi / 12 + math.sin(rays * math.pi) * 0.08;
        final path = Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx + math.cos(a - 0.06) * len, center.dy + math.sin(a - 0.06) * len)
          ..lineTo(center.dx + math.cos(a + 0.06) * len, center.dy + math.sin(a + 0.06) * len)
          ..close();
        canvas.drawPath(path, Paint()..color = AppColors.goldLight.withValues(alpha: 0.18 * lid));
      }
      canvas.drawCircle(center, 90 * lid, Paint()..color = AppColors.goldLight.withValues(alpha: 0.25 * lid));
    }

    if (raysOnly) return;

    // Paint order: an opening lid goes behind the crown; a closed lid sits
    // in front of the body.
    if (lid > 0) _lid(canvas, body, boxH, cx, ink);

    // Crown rising out of the box (its base is hidden by the body).
    if (crown > 0) {
      final cw = boxW * 0.42;
      final cy = boxTop - cw * 0.55 * crown + cw * 0.2;
      _crown(canvas, Offset(cx, cy), cw);
    }

    // Box body.
    final rBody = RRect.fromRectAndRadius(body, const Radius.circular(10));
    canvas.drawRRect(rBody, Paint()..color = AppColors.gold);
    canvas.drawRRect(rBody, ink);
    for (final f in [0.18, 0.82]) {
      final x = body.left + body.width * f;
      final band = Rect.fromLTWH(x - 7, body.top, 14, body.height);
      canvas.drawRect(band, Paint()..color = AppColors.goldLight);
      canvas.drawRect(band, ink..strokeWidth = 2);
    }
    // Lock plate.
    final plate = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, body.top + body.height * 0.45), width: 44, height: 50),
      const Radius.circular(8),
    );
    canvas.drawRRect(plate, Paint()..color = lid > 0 ? AppColors.success : AppColors.navy);
    canvas.drawCircle(plate.center.translate(0, -6), 6, Paint()..color = AppColors.goldLight);
    canvas.drawRect(
      Rect.fromCenter(center: plate.center.translate(0, 6), width: 5, height: 14),
      Paint()..color = AppColors.goldLight,
    );

    if (lid == 0) _lid(canvas, body, boxH, cx, ink);
  }

  /// The lid pivots on its back-right edge and lifts away as [lid] grows.
  void _lid(Canvas canvas, Rect body, double boxH, double cx, Paint ink) {
    canvas.save();
    canvas.translate(body.right, body.top - lid * 6);
    canvas.rotate(lid * 0.55);
    canvas.translate(-body.right, -body.top);
    final lidRect = Rect.fromLTWH(body.left - 8, body.top - boxH * 0.42, body.width + 16, boxH * 0.44);
    final lidPath = Path()
      ..moveTo(lidRect.left, lidRect.bottom)
      ..lineTo(lidRect.left, lidRect.top + lidRect.height * 0.45)
      ..quadraticBezierTo(cx, lidRect.top - lidRect.height * 0.45, lidRect.right, lidRect.top + lidRect.height * 0.45)
      ..lineTo(lidRect.right, lidRect.bottom)
      ..close();
    canvas.drawPath(lidPath, Paint()..color = AppColors.goldDeep);
    canvas.drawPath(lidPath, ink..strokeWidth = 3);
    if (lid < 0.3) _crown(canvas, Offset(cx, lidRect.top + lidRect.height * 0.35), 26, emblem: true);
    canvas.restore();
  }

  void _crown(Canvas c, Offset center, double w, {bool emblem = false}) {
    final h = w * 0.62;
    final l = center.dx - w / 2;
    final r = center.dx + w / 2;
    final top = center.dy - h / 2;
    final bottom = center.dy + h / 2;
    final path = Path()
      ..moveTo(l, bottom)
      ..lineTo(l, top + h * 0.2)
      ..lineTo(l + w * 0.25, top + h * 0.55)
      ..lineTo(center.dx, top)
      ..lineTo(r - w * 0.25, top + h * 0.55)
      ..lineTo(r, top + h * 0.2)
      ..lineTo(r, bottom)
      ..close();
    c.drawPath(path, Paint()..color = emblem ? AppColors.goldLight : AppColors.gold);
    c.drawPath(
      path,
      Paint()
        ..color = AppColors.navyDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = emblem ? 1.5 : 3,
    );
    if (!emblem) {
      c.drawRect(Rect.fromLTRB(l, bottom - h * 0.22, r, bottom), Paint()..color = AppColors.goldDeep);
      for (final (fx, color) in [(0.2, AppColors.royalBlue), (0.5, AppColors.waxRed), (0.8, AppColors.royalBlue)]) {
        c.drawCircle(Offset(l + w * fx, bottom - h * 0.11), w * 0.05, Paint()..color = color);
      }
      for (final p in [Offset(l, top + h * 0.2), Offset(center.dx, top), Offset(r, top + h * 0.2)]) {
        c.drawCircle(p, w * 0.045, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(_RoyalBoxPainter old) =>
      old.lid != lid || old.crown != crown || old.rays != rays || old.raysOnly != raysOnly;
}
