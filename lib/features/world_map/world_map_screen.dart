import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/audio_service.dart' show TapRole;
import '../../widgets/art_assets.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
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

  void _enter(WorldCityState city) {
    final seasonId = city.city.seasonId;
    if (_opening || seasonId == null || !city.canEnter) return;
    if (!ref.read(gameControllerProvider.notifier).openSeason(seasonId)) {
      showGameToast(context, 'This file is still being prepared.', glyph: InkGlyph.seal);
      return;
    }
    _opening = true;
    context.go(Routes.seasonOf(seasonId));
  }

  @override
  Widget build(BuildContext context) {
    final cities = ref.watch(worldCityStatesProvider);
    final home = ref.watch(homeCityIdProvider);
    final selected = cities.firstWhere((c) => c.city.id == _selected, orElse: () => cities.first);
    return Scaffold(
      backgroundColor: AppColors.nightBottom,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: WorldMapView(
                cities: cities,
                selectedId: selected.city.id,
                homeId: home,
                onSelect: (id) => setState(() => _selected = id),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.md),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _CityCard(
                    key: ValueKey('city-card-${selected.city.id}'),
                    state: selected,
                    before: _before(cities, selected),
                    onEnter: () => _enter(selected),
                  ),
                ),
              ),
            ),
          ],
        ),
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

/// WORLD MYSTERY, the detective, and the way to the archives.
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(detectiveProfileProvider);
    final name = profile.detectiveName ?? ref.watch(gameControllerProvider).detectiveName ?? '';
    final avatar = profile.avatar;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.sm),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.parchment,
              border: Border.all(color: AppColors.gold, width: AppLine.rule),
            ),
            child: avatar == null
                ? const Center(child: InkIcon(InkGlyph.deerstalker, size: AppIconSize.medium, color: AppColors.inkBrown))
                : DetectivePortrait(avatar: avatar, alignment: Alignment.topCenter),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('WORLD MYSTERY', style: AppText.logo(size: 24, color: AppColors.goldLight)),
                ),
                Text(
                  'Detective $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption(color: AppColors.creamGold),
                ),
              ],
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold, width: AppLine.hairline),
                  borderRadius: BorderRadius.circular(AppRadius.paper),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const InkIcon(InkGlyph.folder, size: AppIconSize.small, color: AppColors.goldLight),
                    Text(
                      'ARCHIVE',
                      textScaler: TextScaler.noScaling,
                      style: AppText.eyebrow(color: AppColors.goldLight).copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The chosen city's season: its number, the city, the season's title,
/// where the detective stands with it, and the way in.
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
    final cover = season == null ? null : ArtAssets.seasonCovers[season.id];
    final file = state.file;
    final (label, onPressed) = switch (status) {
      WorldCityStatus.playable => ('BEGIN ADVENTURE', onEnter),
      WorldCityStatus.inProgress => ('CONTINUE', onEnter),
      WorldCityStatus.completed => ('REVISIT', onEnter),
      WorldCityStatus.locked => ('LOCKED', null),
      WorldCityStatus.comingSoon => ('COMING SOON', null),
    };
    final standing = switch (status) {
      WorldCityStatus.playable => '${file!.availability.plannedCount} CASES • NOT STARTED',
      WorldCityStatus.inProgress => 'IN PROGRESS • ${file!.availability.solvedCount} / ${file.availability.plannedCount} SOLVED',
      WorldCityStatus.completed => 'COMPLETED • ${file!.availability.solvedCount} / ${file.availability.plannedCount} SOLVED',
      WorldCityStatus.locked => 'Complete ${before?.city.name ?? 'the season before'} to unlock.',
      WorldCityStatus.comingSoon => 'A new mystery is on its way.',
    };
    return CaseFolder(
      tab: season == null ? 'COMING SOON' : 'SEASON ${season.number}',
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(cover: cover, locked: !state.canEnter),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    state.city.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.placeTitle(size: 24),
                  ),
                  Text(
                    season?.title ?? 'Coming Soon',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.aside(size: 15, color: AppColors.inkBrown),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    children: [
                      if (status == WorldCityStatus.locked) ...[
                        const InkIcon(InkGlyph.lock, size: AppIconSize.tiny, color: AppColors.inkBrown),
                        const SizedBox(width: AppSpace.xs),
                      ],
                      Expanded(
                        child: Text(
                          standing,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: status == WorldCityStatus.locked || status == WorldCityStatus.comingSoon
                              ? AppText.caption(color: AppColors.inkBrown)
                              : AppText.eyebrow(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  GameButton(
                    key: const ValueKey('city-card-enter'),
                    label: label,
                    glyph: onPressed == null ? InkGlyph.lock : null,
                    arrow: onPressed != null,
                    singleLine: true,
                    style: GameButtonStyle.navy,
                    tap: onPressed == null ? null : TapRole.primary,
                    onPressed: onPressed,
                  ),
                ],
              ),
            ),
          ],
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

  static const width = 72.0;
  static const height = 100.0;

  @override
  Widget build(BuildContext context) {
    final c = cover;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(color: AppColors.paperLight, boxShadow: AppShadow.pinned),
      child: c == null
          ? const ColoredBox(
              color: AppColors.navy,
              child: Center(child: InkIcon(InkGlyph.seal, size: AppIconSize.large, color: AppColors.goldLight)),
            )
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
