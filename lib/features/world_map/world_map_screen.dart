import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../onboarding/detective_form.dart' show DetectivePortrait;
import 'widgets/world_map_view.dart';
import 'world_map_state.dart';

/// The World Map: every city of the game, the detective's own in the
/// middle. Choosing a city on the map only shows its card; its season is
/// played only from the card's button ([GameController.openSeason]), so
/// looking around changes nothing.
class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({super.key});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  /// The city whose card is shown: the home city until another is chosen.
  late String _selected = ref.read(homeCityIdProvider);

  /// Whether a season is being opened (one tap opens one).
  bool _opening = false;

  /// The card's height as last laid out (null: not yet; a guess is used).
  double? _cardHeight;

  /// The header's height under the status bar.
  static const headerHeight = 56.0;

  /// The card's height before it is first laid out.
  static const _cardGuess = 164.0;

  void _enter(WorldCityState city) {
    final seasonId = city.city.seasonId;
    if (_opening || seasonId == null || !city.canEnter) return;
    if (!ref.read(gameControllerProvider.notifier).openSeason(seasonId)) {
      showGameToast(context, 'This file is still being prepared.', glyph: InkGlyph.seal);
      return;
    }
    _opening = true;
    // CONTINUE: on from where the season's case was left, as the title's
    // CONTINUE did (its report, or its map); else the season's own page
    // (its cover when not begun, its board).
    final progress = ref.read(gameControllerProvider);
    context.go(
      city.status != WorldCityStatus.inProgress
          ? Routes.seasonOf(seasonId)
          : progress.isCaseSolved
          ? Routes.solvedSettled
          : progress.introSeen
          ? Routes.map
          : Routes.seasonOf(seasonId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cities = ref.watch(worldCityStatesProvider);
    final home = ref.watch(homeCityIdProvider);
    final selected = cities.firstWhere((c) => c.city.id == _selected, orElse: () => cities.first);
    final pad = MediaQuery.paddingOf(context);
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final top = pad.top + headerHeight;
    final cardBottom = pad.bottom + AppSpace.md;
    final covered = cardBottom + (_cardHeight ?? _cardGuess);
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: Stack(
        children: [
          // The world fills the page; the header and the card lie over it.
          Positioned.fill(
            child: WorldMapView(
              cities: cities,
              selectedId: selected.city.id,
              homeId: home,
              obscured: EdgeInsets.only(top: top, bottom: covered),
              onSelect: (id) => setState(() => _selected = id),
            ),
          ),
          // Night shading behind the header and the card, fading into the map.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top + 56,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.navyDeep.withValues(alpha: 0.9),
                      AppColors.navyDeep.withValues(alpha: 0.6),
                      AppColors.navyDeep.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: covered + 72,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.navyDeep.withValues(alpha: 0), AppColors.navyDeep.withValues(alpha: 0.75)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            key: const ValueKey('world-map-header'),
            left: 0,
            right: 0,
            top: pad.top,
            height: headerHeight,
            child: const _Header(),
          ),
          Positioned(
            left: AppSpace.md + pad.left,
            right: AppSpace.md + pad.right,
            bottom: cardBottom,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _MeasureHeight(
                  key: const ValueKey('world-map-card'),
                  onHeight: (h) {
                    if (mounted && h != _cardHeight) setState(() => _cardHeight = h);
                  },
                  child: AnimatedSwitcher(
                    duration: still ? Duration.zero : const Duration(milliseconds: 200),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.bottomCenter,
                      children: [...previous, ?current],
                    ),
                    child: _CityCard(
                      key: ValueKey('city-card-${selected.city.id}'),
                      state: selected,
                      before: _before(cities, selected),
                      onEnter: () => _enter(selected),
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

  /// The city of the season whose last case unlocks [city]'s (null: none).
  static WorldCityState? _before(List<WorldCityState> cities, WorldCityState city) {
    final before = city.file?.before;
    if (before == null) return null;
    return cities.where((c) => c.city.seasonId == before.id).firstOrNull;
  }
}

/// Reports its child's height after each layout that changes it.
class _MeasureHeight extends SingleChildRenderObjectWidget {
  const _MeasureHeight({super.key, required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasureHeight(onHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasureHeight renderObject) => renderObject.onHeight = onHeight;
}

class _RenderMeasureHeight extends RenderProxyBox {
  _RenderMeasureHeight(this.onHeight);

  ValueChanged<double> onHeight;
  double? _last;

  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if (h == _last) return;
    _last = h;
    WidgetsBinding.instance.addPostFrameCallback((_) => onHeight(h));
  }
}

/// The detective (picture and name, under the game's name) and the way to
/// the World Archive, over the top of the map.
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(detectiveProfileProvider);
    final name = profile.detectiveName ?? ref.watch(gameControllerProvider).detectiveName ?? '';
    final avatar = profile.avatar;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Row(
        children: [
          Expanded(
            child: IgnorePointer(
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.parchment,
                      border: Border.all(color: AppColors.goldLight, width: AppLine.hairline),
                    ),
                    child: avatar == null
                        ? const Center(child: InkIcon(InkGlyph.deerstalker, size: AppIconSize.small, color: AppColors.inkBrown))
                        : DetectivePortrait(avatar: avatar, alignment: Alignment.topCenter),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'WORLD MYSTERY',
                          maxLines: 1,
                          style: AppText.eyebrow(color: AppColors.goldLight).copyWith(fontSize: 10, letterSpacing: 2.4, height: 1.2),
                        ),
                        Text(
                          'Detective $name',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.style(AppText.body, size: 16, weight: FontWeight.w600, color: AppColors.paper, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Semantics(
            button: true,
            label: 'World Archive',
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey('world-map-archive'),
              behavior: HitTestBehavior.opaque,
              onTap: () => context.go(Routes.seasons),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                alignment: Alignment.center,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.6), width: AppLine.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const InkIcon(InkGlyph.folder, size: 16, color: AppColors.goldLight),
                      const SizedBox(width: 6),
                      Text(
                        'Archive',
                        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
                        style: AppText.style(AppText.body, size: 13, weight: FontWeight.w600, color: AppColors.paper),
                      ),
                    ],
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

/// The chosen city's season on a card over the map: its cover, which
/// season and city, its title, where the detective stands with it, and the
/// way in. A city that cannot be entered says why instead of a button.
class _CityCard extends StatelessWidget {
  const _CityCard({super.key, required this.state, required this.before, required this.onEnter});

  final WorldCityState state;

  /// The city whose season unlocks this one (for a locked city).
  final WorldCityState? before;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final season = state.season;
    final status = state.status;
    final city = state.city.name;
    final cover = season == null ? null : ArtAssets.seasonCovers[season.id];
    final file = state.file;
    final label = switch (status) {
      WorldCityStatus.playable => 'BEGIN ADVENTURE',
      WorldCityStatus.inProgress => 'CONTINUE',
      WorldCityStatus.completed => 'REVISIT',
      WorldCityStatus.locked || WorldCityStatus.comingSoon => null,
    };
    final standing = switch (status) {
      WorldCityStatus.playable => '${file!.availability.plannedCount} cases · Not started',
      WorldCityStatus.inProgress => 'In progress · ${file!.availability.solvedCount} of ${file.availability.plannedCount} solved',
      WorldCityStatus.completed => 'Completed · ${file!.availability.solvedCount} of ${file.availability.plannedCount} solved',
      WorldCityStatus.locked => 'Complete ${before?.city.name ?? 'the season before'} to unlock.',
      WorldCityStatus.comingSoon => 'A new mystery is on its way.',
    };
    final shut = status == WorldCityStatus.locked || status == WorldCityStatus.comingSoon;
    final progress = status == WorldCityStatus.inProgress && file!.availability.plannedCount > 0
        ? file.availability.solvedCount / file.availability.plannedCount
        : null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paperLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45), width: AppLine.hairline),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Thumb(cover: cover, locked: shut),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      season == null ? city.toUpperCase() : 'SEASON ${season.number} · ${city.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.eyebrow(color: AppColors.goldDeep).copyWith(fontSize: 11, height: 1.3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      season?.title ?? 'Coming Soon',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.placeTitle(size: 20),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Row(
                      children: [
                        if (status == WorldCityStatus.locked) ...[
                          const InkIcon(InkGlyph.lock, size: 13, color: AppColors.muted),
                          const SizedBox(width: AppSpace.xs),
                        ],
                        Expanded(
                          child: Text(
                            standing,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption(color: AppColors.muted).copyWith(fontSize: 13, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          color: AppColors.gold,
                          backgroundColor: AppColors.parchmentDark.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (label != null) ...[
            const SizedBox(height: AppSpace.md),
            _EnterButton(label: label, onPressed: onEnter),
          ],
        ],
      ),
    );
  }
}

/// The way into the city's season: a flat navy bar across the card.
class _EnterButton extends StatelessWidget {
  const _EnterButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('city-card-enter'),
          onTap: onPressed,
          splashColor: AppColors.goldLight.withValues(alpha: 0.15),
          highlightColor: AppColors.goldLight.withValues(alpha: 0.08),
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label, maxLines: 1, style: AppText.button(size: 15, color: AppColors.paperLight)),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  const InkIcon(InkGlyph.arrow, size: 16, color: AppColors.goldLight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The season's cover as a small print on the card; a city without one
/// shows its sealed file instead.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.cover, required this.locked});

  final SeasonCover? cover;
  final bool locked;

  static const width = 56.0;
  static const height = 72.0;

  @override
  Widget build(BuildContext context) {
    final c = cover;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: AppLine.hairline),
      ),
      child: c == null
          ? const Center(child: InkIcon(InkGlyph.seal, size: AppIconSize.medium, color: AppColors.goldLight))
          : Opacity(
              opacity: locked ? 0.55 : 1,
              child: Image.asset(
                c.file,
                fit: BoxFit.cover,
                alignment: c.crop,
                cacheWidth: math.min((width * dpr).ceil(), c.pixels.width.toInt()),
                excludeFromSemantics: true,
                errorBuilder: (context, error, stack) => const ColoredBox(color: AppColors.navy),
              ),
            ),
    );
  }
}
