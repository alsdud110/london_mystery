import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/season.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/desk_background.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import 'widgets/season_props.dart';

/// Where the detective stands with one season's file in the archives.
enum SeasonFileState {
  /// The season before it is not finished: a sealed file that names nothing
  /// (the last case of that season tells where the next one goes).
  sealed,

  /// Unlocked, but its cases or map are not in the game yet.
  comingSoon,

  /// Can be played, not begun.
  notStarted,

  /// Can be played, under way.
  inProgress,

  /// Every case solved.
  completed,
}

/// One season's file in the Detective Archives. Worked out from the saves
/// (see [SeasonAvailability]); nothing of it is saved.
@immutable
class SeasonFile {
  const SeasonFile({required this.availability, required this.state, required this.current, this.before});

  final SeasonAvailability availability;
  final SeasonFileState state;

  /// The season being played.
  final bool current;

  /// The season whose last case unseals this one (null: the first season).
  final Season? before;

  Season get season => availability.season;

  /// Whether the file can be opened (its season played).
  bool get canOpen => availability.canEnter;
}

/// Every season's file, in play order.
final seasonFilesProvider = Provider<List<SeasonFile>>((ref) {
  final seasons = ref.watch(seasonsProvider);
  final all = ref.watch(allEpisodesProvider);
  final playing = ref.watch(selectedSeasonIdProvider);
  final repo = ref.watch(progressRepositoryProvider);
  // The case being played saves as it goes: its file reads it fresh.
  ref.watch(gameControllerProvider);
  return [
    for (var i = 0; i < seasons.length; i++)
      if (ref.watch(seasonAvailabilityProvider(seasons[i].id)) case final a?)
        SeasonFile(
          availability: a,
          current: seasons[i].id == playing,
          before: i == 0 ? null : seasons[i - 1],
          state: switch (a.status) {
            SeasonStatus.locked => SeasonFileState.sealed,
            SeasonStatus.comingSoon => SeasonFileState.comingSoon,
            SeasonStatus.open when a.isCompleted => SeasonFileState.completed,
            // Begun: a case solved, or a case whose story has been read.
            // Its opening watched to its first case counts as begun too.
            SeasonStatus.open
                when a.solvedCount > 0 ||
                    repo.loadSeason(seasons[i].id).prologueSeen ||
                    SeasonAvailability.casesOf(seasons[i].id, all).any((e) => repo.load(e.id).introSeen) =>
              SeasonFileState.inProgress,
            SeasonStatus.open => SeasonFileState.notStarted,
          },
        ),
  ];
});

/// The Detective Archives: the season files kept in the office, to choose
/// the next adventure. Opened from the completed board and the map menu
/// (and from the title once more than one season can be played). Choosing a
/// file plays its season ([GameController.openSeason]) and opens its board;
/// a sealed or unfinished file only says why. Visiting changes nothing.
///
/// "WORLD MYSTERY" is this page's title only, not the game's name.
class WorldArchiveScreen extends ConsumerStatefulWidget {
  const WorldArchiveScreen({super.key});

  @override
  ConsumerState<WorldArchiveScreen> createState() => _WorldArchiveScreenState();
}

class _WorldArchiveScreenState extends ConsumerState<WorldArchiveScreen> with SingleTickerProviderStateMixin {
  /// The files laid on the desk one by one.
  late final AnimationController _lay = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  /// Whether a file is being opened (one tap opens one).
  bool _opening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: every file is simply in place.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _lay.value = 1;
    } else if (!_lay.isAnimating && !_lay.isCompleted) {
      _lay.forward();
    }
  }

  @override
  void dispose() {
    _lay.dispose();
    super.dispose();
  }

  /// A file's button: its season, played from its board.
  void _open(SeasonFile file) {
    if (_opening) return;
    if (!ref.read(gameControllerProvider.notifier).openSeason(file.season.id)) {
      _explain(file);
      return;
    }
    _opening = true;
    context.go(Routes.seasonFromArchive);
  }

  /// Why a file does not open (it is sealed, or still being prepared).
  void _explain(SeasonFile file) {
    final before = file.before;
    showGameToast(
      context,
      file.state == SeasonFileState.sealed && before != null
          ? 'Solve ${before.title} to unseal this file.'
          : 'This file is still being prepared.',
      glyph: file.state == SeasonFileState.sealed ? InkGlyph.lock : InkGlyph.seal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(seasonFilesProvider);
    return Scaffold(
      backgroundColor: AppColors.walnutDeep,
      appBar: AppBar(
        backgroundColor: AppColors.walnutDeep,
        foregroundColor: AppColors.goldLight,
        iconTheme: const IconThemeData(color: AppColors.goldLight),
        leading: IconButton(
          tooltip: 'Back',
          icon: const InkIcon(InkGlyph.back),
          onPressed: () => context.go(Routes.start),
        ),
      ),
      body: DeskBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AnimatedBuilder(
                animation: _lay,
                builder: (context, _) {
                  // Each file comes down a little after the one before it.
                  Widget laid(int i, Widget child) {
                    final start = math.min(0.15 * i, 0.6);
                    final t = Curves.easeOutCubic.transform(((_lay.value - start) / 0.4).clamp(0.0, 1.0));
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xxl),
                    children: [
                      laid(0, const _Heading()),
                      for (final (i, f) in files.indexed) ...[
                        const SizedBox(height: AppSpace.xl),
                        laid(
                          i + 1,
                          _SeasonFileCard(
                            key: ValueKey('season-file-${f.season.id}'),
                            file: f,
                            onOpen: () => _open(f),
                            onExplain: () => _explain(f),
                          ),
                        ),
                      ],
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

/// WORLD MYSTERY, over the archives.
class _Heading extends StatelessWidget {
  const _Heading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        children: [
          const InkIcon(InkGlyph.deerstalker, size: AppIconSize.emblem, color: AppColors.goldLight),
          const SizedBox(height: AppSpace.sm),
          Text(
            'WORLD MYSTERY',
            style: AppText.logo(size: 34, color: AppColors.goldLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Choose your next adventure',
            style: AppText.aside(color: AppColors.creamGold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.md),
          const OrnamentRule(),
        ],
      ),
    );
  }
}

/// One season's file: a manila case folder with its season on the tab.
class _SeasonFileCard extends StatelessWidget {
  const _SeasonFileCard({super.key, required this.file, required this.onOpen, required this.onExplain});

  final SeasonFile file;
  final VoidCallback onOpen;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    final body = switch (file.state) {
      SeasonFileState.sealed => _SealedFile(file),
      SeasonFileState.comingSoon => _ComingSoonFile(file),
      _ => _OpenFile(file, onOpen: onOpen),
    };
    final folder = CaseFolder(tab: file.season.label, child: body);
    if (file.canOpen) return folder;
    // A file that does not open answers a tap with why.
    return Semantics(
      button: true,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onExplain, child: folder),
    );
  }
}

/// A season's cover, as a 2:1 strip at the top of its file. Shown only on a
/// file that is unsealed (the cover names the city).
class _CoverStrip extends StatelessWidget {
  const _CoverStrip(this.cover);

  /// The season's cover (see [ArtAssets.seasonCovers]).
  final SeasonCover cover;

  @override
  Widget build(BuildContext context) {
    final SeasonCover(:file, :pixels, archiveLook: look) = cover;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return AspectRatio(
      aspectRatio: 2,
      child: LayoutBuilder(
        builder: (context, box) => Image.asset(
          file,
          fit: BoxFit.cover,
          alignment: look,
          cacheWidth: math.min((box.maxWidth * dpr).ceil(), pixels.width.toInt()),
          excludeFromSemantics: true,
          errorBuilder: (context, error, stack) => const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// A season that can be played: its cover, its title, how far it has come
/// and the way in.
class _OpenFile extends StatelessWidget {
  const _OpenFile(this.file, {required this.onOpen});

  final SeasonFile file;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final a = file.availability;
    final season = file.season;
    final cover = ArtAssets.seasonCovers[season.id];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cover != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              _CoverStrip(cover),
              // The season being played: its file is pinned, and tagged while
              // it is under way (on the print, so the title keeps its width).
              if (file.current) const Positioned(top: -5, right: AppSpace.lg, child: PushPin(size: 12)),
              if (file.current && file.state == SeasonFileState.inProgress)
                const Positioned(
                  left: AppSpace.md,
                  bottom: AppSpace.md,
                  child: PaperTag('CURRENT FILE', glyph: InkGlyph.pin),
                ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(season.title.toUpperCase(), style: AppText.placeTitle(size: 22))),
                  if (file.state == SeasonFileState.completed)
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpace.sm, top: AppSpace.xs),
                      child: InkStamp('SOLVED', color: AppColors.success, size: 13),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(_tagline(a), style: AppText.eyebrow()),
              const SizedBox(height: AppSpace.md),
              _Progress(a),
              const SizedBox(height: AppSpace.md),
              GameButton(
                label: switch (file.state) {
                  SeasonFileState.inProgress => 'CONTINUE THE FILE',
                  SeasonFileState.completed => 'REVIEW THE FILE',
                  _ => 'BEGIN ${season.label}',
                },
                arrow: true,
                singleLine: true,
                style: GameButtonStyle.parchment,
                onPressed: onOpen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// "12 CASES • ONE MYSTERY".
  static String _tagline(SeasonAvailability a) =>
      a.hasCases ? '${a.plannedCount} CASES • ${a.season.tagline}' : a.season.tagline;
}

/// How many of the season's cases are solved, as on the board.
class _Progress extends StatelessWidget {
  const _Progress(this.a);

  final SeasonAvailability a;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${a.solvedCount} of ${a.plannedCount} cases solved',
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (var i = 0; i < a.plannedCount; i++)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < a.solvedCount ? AppColors.navy : null,
                      border: Border.all(color: AppColors.navy.withValues(alpha: 0.55), width: AppLine.hairline),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            '${a.solvedCount} / ${a.plannedCount}',
            style: AppText.title(
              size: 18,
              color: AppColors.navy,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

/// A season not yet unsealed: its number only. Its city and title stay
/// inside until the season before it is solved.
class _SealedFile extends StatelessWidget {
  const _SealedFile(this.file);

  final SeasonFile file;

  @override
  Widget build(BuildContext context) {
    final before = file.before;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          const InkIcon(InkGlyph.seal, size: AppIconSize.emblem, color: AppColors.leather),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SEALED FILE', style: AppText.placeTitle(size: 20, color: AppColors.locked)),
                if (before != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text('Solve ${before.title} to unseal this file.', style: AppText.caption(color: AppColors.inkBrown)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          const InkStamp('SEALED', size: 12),
        ],
      ),
    );
  }
}

/// A season unsealed but not in the game yet: its name, and that it is
/// still being prepared.
class _ComingSoonFile extends StatelessWidget {
  const _ComingSoonFile(this.file);

  final SeasonFile file;

  @override
  Widget build(BuildContext context) {
    final season = file.season;
    // Unsealed: its cover may show the city now.
    final cover = ArtAssets.seasonCovers[season.id];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?(cover == null ? null : _CoverStrip(cover)),
        Padding(padding: const EdgeInsets.all(AppSpace.lg), child: _comingSoon(season)),
      ],
    );
  }

  Widget _comingSoon(Season season) {
    // The title and tagline keep the full width; the stamp sits by the note.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(season.title.toUpperCase(), style: AppText.placeTitle(size: 22)),
        const SizedBox(height: 2),
        Text(season.tagline, style: AppText.eyebrow()),
        const SizedBox(height: AppSpace.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text('This file is still being prepared.', style: AppText.caption(color: AppColors.inkBrown)),
            ),
            const SizedBox(width: AppSpace.sm),
            const InkStamp('COMING SOON', color: AppColors.goldDeep, size: 12),
          ],
        ),
      ],
    );
  }
}
