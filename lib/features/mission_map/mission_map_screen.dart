import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/audio_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/mission.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game/scoring.dart';
import 'map_camera.dart';
import 'map_world.dart';
import 'widgets/london_map_painter.dart';
import 'widgets/map_pin.dart';

/// The detective's map of London. One purpose: go to the next place.
/// Case status (name, XP, play time) lives in the menu, not on the map.
class MissionMapScreen extends ConsumerStatefulWidget {
  const MissionMapScreen({super.key});

  @override
  ConsumerState<MissionMapScreen> createState() => _MissionMapScreenState();
}

class _MissionMapScreenState extends ConsumerState<MissionMapScreen> with SingleTickerProviderStateMixin {
  /// The place being travelled to (GO TO): the camera zooms right in on its
  /// pin, the map fades out, then its mission page fades in — once. Null
  /// when not going.
  Mission? _goingTo;

  /// The map fading out as the camera comes in on the pin (it starts while
  /// the zoom is finishing, so the two blend).
  late final AnimationController _leave = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void dispose() {
    _leave.dispose();
    super.dispose();
  }

  /// GO TO a place: travel there on the map first. A second tap while
  /// travelling does nothing.
  void _goTo(Mission m) {
    if (_goingTo != null) return;
    setState(() => _goingTo = m);
  }

  /// The camera is nearly in on the pin: the map fades out over the end of
  /// the zoom, then the mission page fades in.
  Future<void> _onArriving() async {
    final m = _goingTo;
    if (!mounted || m == null) return;
    try {
      await _leave.forward(from: 0).orCancel;
    } on TickerCanceled {
      return; // the map went away meanwhile
    }
    if (!mounted) return;
    await context.push(m.isFinal ? Routes.finalMission : Routes.mission(m.id));
    // Back on the map (the mission was left with back): the map as it was.
    if (!mounted) return;
    _leave.value = 0;
    setState(() => _goingTo = null);
  }

  Future<void> _confirmLeave() async {
    final leave = await GameDialog.confirm(
      context,
      title: 'Leave the case?',
      message: 'Your clues are saved. You can come back to the map any time.',
      confirmLabel: 'TITLE SCREEN',
      cancelLabel: 'Keep investigating',
    );
    if (leave && mounted) context.go(Routes.start);
  }

  PinState _stateOf(GameProgress p, Episode e, Mission m) {
    if (p.isCompleted(m.id)) return PinState.completed;
    if (p.isUnlocked(e, m.id)) return PinState.current;
    return PinState.locked;
  }

  void _openMission(BuildContext context, WidgetRef ref, Mission m) {
    final progress = ref.read(gameControllerProvider);
    final episode = ref.read(currentEpisodeProvider);

    switch (_stateOf(progress, episode, m)) {
      case PinState.locked:
        final current = progress.currentMission(episode);
        showGameToast(
          context,
          m.isFinal
              ? 'Locked! Solve all ${episode.missions.length} places to open the final case.'
              : 'Locked! First solve the case at ${current?.location ?? ''}.',
        );
      case PinState.current:
        _goTo(m);
      case PinState.completed:
        _showSolvedSheet(context, progress, episode, m);
    }
  }

  void _showSolvedSheet(BuildContext context, GameProgress progress, Episode episode, Mission m) {
    final clues = progress.collectedClues(episode);
    final clueIndex = m.clue == null ? -1 : clues.indexWhere((c) => c.id == m.clue!.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(m.location, style: AppText.title(size: 24))),
                  const InkStamp('SOLVED', color: AppColors.success, size: 13),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              if (clueIndex >= 0) ClueCard(clue: m.clue!, index: clueIndex),
              if (!m.isFinal) ...[
                const SizedBox(height: AppSpace.lg),
                GameButton(
                  label: 'READ THE CASE AGAIN',
                  style: GameButtonStyle.outline,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(Routes.mission(m.id));
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // A page of the casebook slid over the map (this sheet only; the
      // other sheets keep the app's sheet theme): the case files' paper,
      // nearly square corners, a thin ink-brown tab printed on it (the
      // theme's grey handle is off; the whole sheet still drags to close).
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.paper))),
      showDragHandle: false,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final soundOn = ref.watch(soundEnabledProvider);
          final progress = ref.watch(gameControllerProvider);
          final episode = ref.watch(currentEpisodeProvider);
          final playTime = ref.read(gameControllerProvider.notifier).playTime;
          final xp = XpBreakdown.totalFor(episode, progress);

          // A press leaves a faint ink mark on the paper, not a Material ripple.
          final press = AppColors.inkBrown.withValues(alpha: 0.08);

          Widget item(InkGlyph glyph, String label, VoidCallback onTap) => ListTile(
            leading: InkIcon(glyph, color: AppColors.ink),
            title: Text(label, style: AppText.subtitle()),
            splashColor: press,
            hoverColor: press,
            focusColor: press,
            onTap: onTap,
          );

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 3,
                      margin: const EdgeInsets.only(top: 22, bottom: 23),
                      decoration: BoxDecoration(
                        color: AppColors.inkBrown.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Case status: shown here, on request, instead of on the map.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(episode.title, style: AppText.aside()),
                        Text('Detective ${progress.detectiveName}', style: AppText.title(size: 22)),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          '$xp XP  ·  ${Formatters.clock(playTime)}',
                          style: AppText.caption(color: AppColors.goldDeep)
                              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                  ),
                  // A faint printed rule in the paper's own ink.
                  Divider(color: AppColors.inkBrown.withValues(alpha: 0.18)),
                  // Its press and focus marks in the same faint ink (this row only).
                  Theme(
                    data: Theme.of(context)
                        .copyWith(focusColor: press, hoverColor: press, splashColor: press, highlightColor: press),
                    child: SwitchListTile(
                      secondary: InkIcon(soundOn ? InkGlyph.speaker : InkGlyph.speakerOff, color: AppColors.ink),
                      title: Text('Sound effects', style: AppText.subtitle()),
                      hoverColor: press,
                      activeThumbColor: AppColors.goldLight,
                      activeTrackColor: AppColors.navy,
                      inactiveThumbColor: AppColors.paperLight,
                      inactiveTrackColor: AppColors.parchmentDark,
                      value: soundOn,
                      onChanged: (_) => ref.read(soundEnabledProvider.notifier).toggle(),
                    ),
                  ),
                  item(InkGlyph.notebook, 'Detective Notebook', () {
                    Navigator.of(sheetContext).pop();
                    context.push(Routes.notebook);
                  }),
                  if (progress.isCaseSolved)
                    item(InkGlyph.folder, 'Case results', () {
                      Navigator.of(sheetContext).pop();
                      context.go(Routes.solved);
                    }),
                  item(InkGlyph.pin, 'Season board', () {
                    Navigator.of(sheetContext).pop();
                    context.go(Routes.season);
                  }),
                  item(InkGlyph.folder, 'Case files', () {
                    Navigator.of(sheetContext).pop();
                    context.go(Routes.episodes);
                  }),
                  item(InkGlyph.home, 'Title screen', () {
                    Navigator.of(sheetContext).pop();
                    context.go(Routes.start);
                  }),
                  const SizedBox(height: AppSpace.sm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final going = _goingTo;
    final episode = ref.watch(currentEpisodeProvider);
    final progress = ref.watch(gameControllerProvider);
    final recentUnlock = ref.watch(recentUnlockProvider);
    final current = progress.currentMission(episode);
    final all = episode.allMissions;
    final places = MapWorld.places(episode);
    // Back from solving a place: the map opens on the place it unlocked.
    final unlockedAt = all.indexWhere((m) => m.id == recentUnlock);
    final arrivedFrom = unlockedAt > 0 && current?.id == recentUnlock ? all[unlockedAt - 1] : null;

    // The place is named in the next lead above the button; the button keeps
    // one short word at a steady size (a long place name used to shrink it).
    final ctaLabel = current == null
        ? 'SEE MY CASE FILE'
        : current.isFinal
        ? 'OPEN THE FINAL CASE'
        : 'GO';
    final ctaSemantics = current == null || current.isFinal ? null : 'GO TO ${current.location}';

    final map = Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.sm, AppSpace.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CASE ${episode.numberLabel}', style: AppText.eyebrow()),
                              const SizedBox(height: 2),
                              Text(
                                episode.title,
                                style: AppText.title(size: 21),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Menu',
                          onPressed: going != null ? null : () => _showMenu(context, ref),
                          icon: const InkIcon(InkGlyph.menu),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.md),
                      // The map and the next lead under it, one group in the
                      // middle of the page (no empty band above or below).
                      // The lead keeps its natural height (larger text grows
                      // it); the map takes the rest, up to its own shape.
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: _MapViewport(
                              // The camera follows the game: the current place,
                              // or the last one once every place is solved.
                              focus: places[(current ?? all.last).id]!,
                              // Just back from solving a place: start the camera
                              // there and travel to the place it unlocked.
                              arriveFrom: arrivedFrom == null ? null : places[arrivedFrom.id],
                              // GO TO: the camera moves in on the place.
                              zoomIn: going != null,
                              onArriving: _onArriving,
                              world: (size, heading) => _MapWorldView(
                                heading: heading,
                                size: size,
                                route: [for (final m in all) places[m.id]!],
                                completedLegs: progress.completedMissionIds.length,
                                // The current place's own name is on its pin.
                                hideName: current == null ? null : MapWorld.missionLandmarks[current.id],
                                pins: [
                                  // The current place last, so its note is on top.
                                  for (final m in [...all.where((m) => m != current), ?current])
                                    // A place stays off the map until it is
                                    // unlocked: where it is would tell the answer
                                    // of the case before it.
                                    if (_stateOf(progress, episode, m) != PinState.locked)
                                      (
                                        at: places[m.id]!,
                                        pin: MapPin(
                                          key: ValueKey('pin-${m.id}'),
                                          label: m.location,
                                          isFinal: m.isFinal,
                                          state: _stateOf(progress, episode, m),
                                          celebrateUnlock: recentUnlock == m.id,
                                          onUnlockBurst: () => ref.read(audioServiceProvider).play(GameSound.unlock),
                                          onUnlockShown: () => ref.read(recentUnlockProvider.notifier).set(null),
                                          onTap: () => _openMission(context, ref, m),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.md),
                          _LeadNote(episode: episode, progress: progress, current: current),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
                    child: Row(
                      children: [
                        _NotebookButton(onTap: () => context.push(Routes.notebook)),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: GameButton(
                            label: ctaLabel,
                            semanticLabel: ctaSemantics,
                            arrow: true,
                            singleLine: true,
                            onPressed: going != null
                                ? null
                                : current == null
                                ? () => context.go(Routes.solved)
                                : () => _openMission(context, ref, current),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return PopScope(
      // The map is the root of a case (nothing under it): Android back asks
      // before going to the title page instead of closing the app. While
      // travelling it does nothing: the trip ends in the mission.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _goingTo == null) _confirmLeave();
      },
      // While travelling the map takes no taps (pins, menu, notebook).
      child: AbsorbPointer(
        absorbing: going != null,
        // Fades out to the page colour; the mission page fades in from it.
        child: ColoredBox(
          color: AppColors.paper,
          child: FadeTransition(
            key: const ValueKey('map-page'),
            opacity: Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _leave, curve: Curves.easeInOut)),
            child: map,
          ),
        ),
      ),
    );
  }
}

/// The camera over the London map: a tall viewport, the size of a page,
/// showing one part of the map world. It follows the game (it is never
/// dragged or zoomed): the current place sits at the centre, and when a new
/// place is unlocked the whole world pans there, pins and all.
class _MapViewport extends StatefulWidget {
  const _MapViewport({
    required this.focus,
    required this.arriveFrom,
    required this.world,
    this.zoomIn = false,
    this.onArriving,
  });

  /// Moves the camera in on [focus] (GO TO); false puts it back at once.
  final bool zoomIn;

  /// Called once, as the camera is nearly in ([arrivingAt] of the zoom), so
  /// the next step can overlap the end of the zoom.
  final VoidCallback? onArriving;

  /// Share of the zoom after which [onArriving] is called.
  static const arrivingAt = 0.5;

  /// How close the camera comes on GO TO: right in on the pin's tip.
  static const travelZoom = 3.0;
  static const zoomDuration = Duration(milliseconds: 1200);

  /// The place the camera shows (fractions of the map).
  final Offset focus;

  /// Where the camera starts when the map opens, if not at [focus].
  final Offset? arriveFrom;

  /// Builds the map world at its size in the viewport.
  final Widget Function(Size size, Animation<double> heading) world;

  /// Height / width of the viewport (the map world is 3:2, much wider).
  static const tallness = 1.25;

  /// Parchment margin around the map, inside its hairline border.
  static const frame = 4.0;

  /// From the viewport's outer edge to the map: border and margin.
  static const inset = frame + AppLine.hairline;

  /// The pan from one place to the next, after a short pause so the screen
  /// has opened first.
  static const panDuration = Duration(milliseconds: 950);
  static const panCurve = Interval(0.2, 1, curve: Curves.easeInOutCubic);

  @override
  State<_MapViewport> createState() => _MapViewportState();
}

class _MapViewportState extends State<_MapViewport> with TickerProviderStateMixin {
  late final AnimationController _pan = AnimationController(vsync: this, duration: _MapViewport.panDuration, value: 1);
  late final AnimationController _zoom = AnimationController(vsync: this, duration: _MapViewport.zoomDuration)
    ..addListener(_checkArriving);

  /// The camera's travel to the current place (the pan, as drawn): the red
  /// dashed way grows with it. Complete when the camera is not travelling.
  late final Animation<double> _heading = CurvedAnimation(parent: _pan, curve: _MapViewport.panCurve);

  /// Whether [_MapViewport.onArriving] was called for this zoom.
  bool _arriving = false;

  void _checkArriving() {
    if (_arriving || !widget.zoomIn || _zoom.value < _MapViewport.arrivingAt) {
      return;
    }
    _arriving = true;
    widget.onArriving?.call();
  }

  late Offset _from = widget.arriveFrom ?? widget.focus;
  late Offset _to = widget.focus;

  @override
  void initState() {
    super.initState();
    // First look: already on the current place, unless just arriving.
    if (_from != _to) _pan.forward(from: 0);
  }

  @override
  void didUpdateWidget(_MapViewport old) {
    super.didUpdateWidget(old);
    if (widget.zoomIn && !old.zoomIn) {
      _arriving = false;
      _zoom.forward(from: 0);
    } else if (!widget.zoomIn && old.zoomIn) {
      _zoom.value = 0;
    }
    if (widget.focus == _to) return; // same place: the camera stays
    _from = Offset.lerp(_from, _to, _MapViewport.panCurve.transform(_pan.value))!;
    _to = widget.focus;
    _pan.forward(from: 0);
  }

  @override
  void dispose() {
    _pan.dispose();
    _zoom.dispose();
    super.dispose();
  }

  /// Where the world is, and how large, for the pan and the zoom: the zoom
  /// moves from the panned camera to the zoomed-in one (same clamping, so
  /// the world covers the viewport at every step, map edges included).
  Matrix4 _camera(MapCamera camera) {
    final pan = Offset.lerp(
      camera.offsetFor(_from),
      camera.offsetFor(_to),
      _MapViewport.panCurve.transform(_pan.value),
    )!;
    final z = Curves.easeInOutCubic.transform(_zoom.value);
    final offset = z == 0 ? pan : Offset.lerp(pan, camera.zoomed(_MapViewport.travelZoom).offsetFor(_to), z)!;
    final scale = 1 + (_MapViewport.travelZoom - 1) * z;
    return Matrix4.diagonal3Values(scale, scale, 1)..setTranslationRaw(offset.dx, offset.dy, 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const f = _MapViewport.inset;
        final width = box.maxWidth;
        final height = math.min(box.maxHeight, width * _MapViewport.tallness);
        final camera = MapCamera.cover(Size(width - 2 * f, height - 2 * f), aspect: ArtAssets.londonMapAspect);
        // Between the header and the buttons, with the spare height shared.
        return Center(
          child: Container(
            key: const ValueKey('map-viewport'),
            width: width,
            height: height,
            padding: const EdgeInsets.all(_MapViewport.frame),
            decoration: BoxDecoration(
              color: AppColors.paperLight,
              borderRadius: BorderRadius.circular(AppRadius.paper),
              border: Border.all(color: AppLine.faint(0.3), width: AppLine.hairline),
              boxShadow: const [
                BoxShadow(color: Color(0x1A2A2622), blurRadius: 2, offset: Offset(0, 1)),
                BoxShadow(color: Color(0x2E2A2622), blurRadius: 18, offset: Offset(0, 8)),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.paper),
              border: Border.all(color: AppLine.faint(0.3), width: AppLine.hairline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.paper / 2),
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: camera.world.width,
                maxWidth: camera.world.width,
                minHeight: camera.world.height,
                maxHeight: camera.world.height,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pan, _zoom]),
                  builder: (context, world) => Transform(transform: _camera(camera), child: world),
                  // Built once per game state, not per frame of the pan.
                  child: RepaintBoundary(key: const ValueKey('map-world'), child: widget.world(camera.world, _heading)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The London map world: the artwork, the route inked on it, the landmark
/// names, and the pins of the places found so far — all at map positions,
/// so they all move together with the camera.
class _MapWorldView extends StatelessWidget {
  const _MapWorldView({
    required this.size,
    required this.route,
    required this.completedLegs,
    required this.heading,
    required this.pins,
    required this.hideName,
  });

  final Size size;

  /// Every place of the case in play order (fractions of the map), and how
  /// many are solved: the route inked between them.
  final List<Offset> route;
  final int completedLegs;

  /// How much of the red dashed way to the current place is drawn: it
  /// follows the camera as it travels there.
  final Animation<double> heading;

  /// Each pin with its place on the map (fractions of the map).
  final List<({Offset at, MapPin pin})> pins;

  /// A landmark whose name is not lettered (the current pin names it).
  final Landmark? hideName;

  static const _nameWidth = 140.0;

  /// The landmark name sits this far below the landmark point.
  static const _nameDrop = 18.0;

  /// Where to draw a solved place's mark, at [at] (world px): there, or —
  /// if it would cover the current pin's note, pin or name around [current]
  /// — just clear of them, at the nearest spot inside the world. Only the
  /// drawing moves; the place itself stays where it is.
  static Offset clearOf(Offset at, Offset current, Size world) {
    const r = MapPin.markRadius;
    const gap = 3.0;
    final keepOut = [for (final k in MapPin.currentMarks) k.shift(current).inflate(gap)];
    bool clear(Offset p) => keepOut.every((k) => !k.overlaps(Rect.fromCircle(center: p, radius: r)));
    bool inside(Offset p) => p.dx >= r && p.dy >= r && p.dx <= world.width - r && p.dy <= world.height - r;
    if (clear(at)) return at;
    final spots = [
      for (final k in keepOut) ...[
        Offset(k.left - r, at.dy),
        Offset(k.right + r, at.dy),
        Offset(at.dx, k.top - r),
        Offset(at.dx, k.bottom + r),
      ],
    ].where((p) => clear(p) && inside(p)).toList()..sort((a, b) => (a - at).distance.compareTo((b - at).distance));
    return spots.isEmpty ? at : spots.first;
  }

  @override
  Widget build(BuildContext context) {
    final w = size.width;
    final h = size.height;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    Offset px(Offset p) => Offset(p.dx * w, p.dy * h);
    // Solved marks step aside from the current pin's note, pin and name.
    final current = pins.where((p) => p.pin.state == PinState.current).map((p) => px(p.at)).firstOrNull;
    final drawnAt = {
      for (final p in pins)
        p.at: current == null || p.pin.state != PinState.completed ? px(p.at) : clearOf(px(p.at), current, size),
    };
    final ink = LondonMapPainter(
      route: [for (final r in route) drawnAt[r] == null ? r : Offset(drawnAt[r]!.dx / w, drawnAt[r]!.dy / h)],
      completedLegs: completedLegs,
      drawMap: false,
      heading: heading,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Image.asset(
            ArtAssets.londonMap,
            // The world has the artwork's ratio: nothing is stretched or cut.
            fit: BoxFit.cover,
            // Decode once at display size (never above the source size); the
            // world keeps its size while the camera pans, so no re-decode.
            cacheWidth: math.min(w * dpr, ArtAssets.londonMapPixels.width).round(),
            excludeFromSemantics: true,
            errorBuilder: (context, error, stack) =>
                CustomPaint(painter: LondonMapPainter(route: const [], completedLegs: 0)),
          ),
        ),
        for (final l in Landmark.values)
          if (l != hideName)
            Positioned(
              left: l.at.dx * w - _nameWidth / 2,
              top: l.at.dy * h + _nameDrop,
              width: _nameWidth,
              child: IgnorePointer(
                child: MapLettering(
                  l.name,
                  maxLines: 1,
                  style: AppText.style(
                    AppText.heading,
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: AppColors.inkBrown,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        Positioned.fill(
          // Its own layer: the red way is redrawn as it grows, not the map.
          child: IgnorePointer(
            child: RepaintBoundary(child: CustomPaint(painter: ink)),
          ),
        ),
        for (final p in pins)
          Positioned(left: drawnAt[p.at]!.dx - MapPin.width / 2, top: drawnAt[p.at]!.dy - MapPin.anchorY, child: p.pin),
      ],
    );
  }
}

/// The notebook, one tap away (secondary action next to the main button).
class _NotebookButton extends StatelessWidget {
  const _NotebookButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Detective notebook',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.paperLight.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppLine.faint(0.45), width: AppLine.hairline),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button - 3),
              border: Border.all(color: AppLine.faint(0.2), width: AppLine.hairline),
            ),
            child: const InkIcon(InkGlyph.notebook, size: AppIconSize.large, semanticLabel: 'Detective notebook'),
          ),
        ),
      ),
    );
  }
}

/// The next lead, written under the map: how far the case has gone (one
/// mark per place), the place to go next — named here, right above the GO
/// button — and the title of the mission waiting there.
class _LeadNote extends StatelessWidget {
  const _LeadNote({required this.episode, required this.progress, required this.current});

  final Episode episode;
  final GameProgress progress;
  final Mission? current;

  @override
  Widget build(BuildContext context) {
    final all = episode.allMissions;
    final m = current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          m == null
              ? 'EVERY PLACE SOLVED'
              : m.isFinal
              ? 'NEXT LEAD · FINAL CASE'
              : 'NEXT LEAD · MISSION ${m.numberLabel}',
          style: AppText.eyebrow(color: AppColors.burgundy),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpace.xs),
        if (m != null && !m.isFinal)
          // The full width of the page for the name: it shrinks only a
          // little for the longest places, never like the old button label.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              m.location,
              key: const ValueKey('next-place'),
              maxLines: 1,
              style: AppText.title(size: 20).copyWith(letterSpacing: 0.8),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                m?.title ?? 'The case is closed.',
                style: AppText.aside(size: 15, color: AppColors.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            // One mark per place: solved, the current one, still ahead.
            ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final x in all)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpace.xs),
                      child: _ProgressMark(done: progress.isCompleted(x.id), here: x == m, isFinal: x.isFinal),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressMark extends StatelessWidget {
  const _ProgressMark({required this.done, required this.here, required this.isFinal});

  final bool done;
  final bool here;
  final bool isFinal;

  @override
  Widget build(BuildContext context) {
    final size = isFinal ? 16.0 : 12.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isFinal ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isFinal ? BorderRadius.circular(3) : null,
        color: done ? AppColors.navy : (here ? AppColors.paperLight : Colors.transparent),
        border: Border.all(
          color: done ? AppColors.navy : (here ? AppColors.burgundy : AppLine.faint(0.35)),
          width: here ? AppLine.ink : AppLine.rule,
        ),
      ),
    );
  }
}
