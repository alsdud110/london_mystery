part of 'season_prologue_screen.dart';

/// Season 2's opening sequence — Paris Stands Still — in the shape of
/// Season 1's ([SeasonPrologueScreen]): five scenes, then the first case's
/// file. Its own words and pictures, never London's:
///
///  1. THE LAST CLUE: the Clockmaker's watch from London, PARIS on its back.
///  2. THE JOURNEY: he came on the 11:40 from Paris; the detective follows.
///  3. GARE DU NORD: the station on the Paris map; look at its clocks.
///  4. THE MISSING HOUR: the clocks do not agree; an hour is missing.
///  5. The promise: 12 CASES · ONE STOLEN HOUR → ACCEPT THE CASE.
///  6. Case 01, The Ticking Watch, at Gare du Nord: START CASE 01 once the
///     case is in the game; until then the file says it is coming soon and
///     only leads back.
///
/// A tap finishes a scene's animation, then moves on; SKIP goes to the
/// promise; back goes to the scene before. Reaching the case's file while
/// Season 2 is played is saved (its season record's `prologueSeen`): the
/// season then opens on its board, never on the opening again. No sound is
/// played.
///
/// Played when Season 2 is the season being played, or, in a build with
/// operator tools only (never a release build), as a preview: then it leads
/// back to the Game Master page (or the archives) and opens nothing.
class ParisPrologueScreen extends ConsumerStatefulWidget {
  const ParisPrologueScreen({super.key});

  @override
  ConsumerState<ParisPrologueScreen> createState() => _ParisPrologueScreenState();
}

/// The words of Season 2's opening ([season2PrologueJson]).
class _ParisWords {
  _ParisWords(Map<String, dynamic> json) : _json = json;

  final Map<String, dynamic> _json;

  Map<String, dynamic> _scene(String key) => (_json[key] as Map?)?.cast<String, dynamic>() ?? const {};

  String text(String scene, String key) => _scene(scene)[key] as String? ?? '';

  List<String> lines(String scene, [String key = 'lines']) =>
      (_scene(scene)[key] as List?)?.whereType<String>().toList() ?? const [];

  int number(String scene, String key) => _scene(scene)[key] as int? ?? 0;
}

class _ParisPrologueScreenState extends ConsumerState<ParisPrologueScreen> with SingleTickerProviderStateMixin {
  static const _clue = 0, _journey = 1, _arrival = 2, _missing = 3, _promise = 4, _file = 5;

  /// How long each scene takes to come in (a tap finishes it at once).
  static const _durations = [1400, 1600, 1500, 1900, 1200, 1100];

  static final _words = _ParisWords(season2PrologueJson);

  late final AnimationController _c = AnimationController(vsync: this);
  int _step = _clue;

  @override
  void initState() {
    super.initState();
    _show(_clue);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _still => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Season 2 is the season being played (not a preview).
  bool get _playing => ref.read(selectedSeasonIdProvider) == SeasonIds.paris;

  /// Where the sequence leads back to: the season, the operator's page the
  /// preview was opened from, or the archives.
  String get _way => _playing
      ? Routes.season
      : ref.read(gameMasterAccessProvider)
      ? Routes.gameMaster
      : Routes.seasons;

  void _show(int step, {bool complete = false}) {
    setState(() => _step = step);
    // The opening watched to its end (never in a preview).
    if (step == _file && _playing) ref.read(seasonProvider.notifier).markPrologueSeen();
    _c.duration = Duration(milliseconds: _durations[step]);
    if (complete) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _still) _c.value = 1;
      });
    }
  }

  void _tap() {
    if (_c.isAnimating) {
      _c.value = 1;
    } else if (_step < _promise) {
      _show(_step + 1);
    }
  }

  void _back() {
    if (_step == _clue) {
      context.go(_way);
    } else {
      _show(_step - 1, complete: true);
    }
  }

  double _iv(double a, double b) => Curves.easeOutCubic.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  /// Case 01 can be played: Season 2 is being played and its first case is
  /// in the game (never in a preview).
  int? _firstCaseIndex(SeasonOverview overview) {
    if (!_playing) return null;
    final i = overview.cases.indexWhere((e) => e.id == _words.text('firstCase', 'id'));
    return i < 0 ? null : i;
  }

  @override
  Widget build(BuildContext context) {
    return BackTo(
      onBack: _back,
      child: Scaffold(
        backgroundColor: AppColors.nightBottom,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          foregroundColor: AppColors.goldLight,
          iconTheme: const IconThemeData(color: AppColors.goldLight),
          leading: IconButton(tooltip: 'Back', icon: const InkIcon(InkGlyph.back), onPressed: _back),
          actions: [
            if (_step < _promise)
              TextButton(
                onPressed: () => _show(_promise),
                style: TextButton.styleFrom(foregroundColor: AppColors.goldLight, minimumSize: const Size(64, 48)),
                child: Text('SKIP ›', style: AppText.eyebrow(color: AppColors.goldLight.withValues(alpha: 0.85))),
              ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _tap,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey('paris-scene-$_step'),
              child: AnimatedBuilder(animation: _c, builder: (context, _) => _scene()),
            ),
          ),
        ),
      ),
    );
  }

  /// The scene's title, small, over its words.
  Widget _eyebrow(String text, double opacity) => Opacity(
    opacity: opacity,
    child: Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Text(text, textAlign: TextAlign.center, style: AppText.eyebrow(color: AppColors.goldLight)),
    ),
  );

  /// The scene's lines, one after the other from [from].
  List<Widget> _lines(List<String> lines, {double from = 0.35, double size = 18}) => [
    for (final (i, line) in lines.indexed)
      Opacity(
        opacity: _iv(from + 0.22 * i, from + 0.22 * i + 0.3),
        child: Padding(padding: const EdgeInsets.only(bottom: AppSpace.xs), child: _Line(line, size: size)),
      ),
  ];

  Widget _scene() {
    final w = _words;
    switch (_step) {
      case _clue:
        return _SceneLayout(
          art: _Watch(appear: _iv(0, 0.45), engraving: w.text('lastClue', 'engraving'), engraved: _iv(0.45, 0.8)),
          words: _Words(children: [_eyebrow(w.text('lastClue', 'title'), _iv(0, 0.3)), ..._lines(w.lines('lastClue'))]),
          footer: _NextBar(step: _step, onNext: _tap),
        );
      case _journey:
        final name = ref.watch(detectiveProfileProvider).detectiveName;
        return _SceneLayout(
          art: _Ticket(
            from: w.text('journey', 'from'),
            to: w.text('journey', 'to'),
            passenger: name == null || name.isEmpty ? null : 'DETECTIVE ${name.toUpperCase()}',
            appear: _iv(0, 0.5),
          ),
          words: _Words(children: [_eyebrow(w.text('journey', 'title'), _iv(0, 0.3)), ..._lines(w.lines('journey'))]),
          footer: _NextBar(step: _step, onNext: _tap),
        );
      case _arrival:
        return _SceneLayout(
          // The whole screen is the station, as Season 1's first scene is
          // London: a little shade at the top for Back / SKIP, more at the
          // bottom for the words (the lit platform shows through it).
          background: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: AppColors.nightBottom),
              Opacity(opacity: _iv(0, 0.35), child: _StationHero(push: _iv(0, 1))),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      for (final a in const [0.5, 0.0, 0.0, 0.62, 0.86]) AppColors.navyDeep.withValues(alpha: a),
                    ],
                    stops: const [0, 0.14, 0.54, 0.76, 1],
                  ),
                ),
              ),
            ],
          ),
          night: true,
          words: _Words(children: [_eyebrow(w.text('arrival', 'title'), _iv(0.1, 0.4)), ..._lines(w.lines('arrival'))]),
          footer: _NextBar(step: _step, onNext: _tap),
        );
      case _missing:
        return _SceneLayout(
          art: _StationClocks(times: w.lines('missingHour', 'clocks'), appear: (i) => _iv(0.12 * i, 0.12 * i + 0.35)),
          words: _Words(
            children: [_eyebrow(w.text('missingHour', 'title'), _iv(0.3, 0.55)), ..._lines(w.lines('missingHour'), from: 0.5)],
          ),
          footer: _NextBar(step: _step, onNext: _tap),
        );
      case _promise:
        final season = ref.watch(seasonsProvider).firstWhere((s) => s.id == SeasonIds.paris);
        return _SceneLayout(
          art: Stack(
            fit: StackFit.expand,
            children: [
              // The Paris map, in the dark behind the promise.
              const Opacity(opacity: 0.22, child: _MapPrint(at: Offset(0.5, 0.5), zoom: 1, appear: 1, framed: false)),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: _iv(0, 0.4),
                          child: Column(
                            children: [
                              Text(season.label, style: AppText.eyebrow(color: AppColors.goldLight)),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                season.title.toUpperCase(),
                                style: AppText.logo(size: 20, color: AppColors.paperLight).copyWith(letterSpacing: 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.xl),
                        Opacity(
                          opacity: _iv(0.2, 0.6),
                          child: Column(
                            children: [
                              Text('${w.number('promise', 'cases')} CASES', style: AppText.logo(size: 38, color: AppColors.goldLight)),
                              const SizedBox(height: AppSpace.sm),
                              const OrnamentRule(color: AppColors.goldLight, width: 150),
                              const SizedBox(height: AppSpace.sm),
                              Text(season.tagline, style: AppText.logo(size: 32, color: AppColors.paperLight)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          words: _Words(
            children: [
              for (final (i, line) in w.lines('promise').indexed)
                Opacity(opacity: _iv(0.45 + 0.12 * i, 0.75 + 0.08 * i), child: _Line(line, size: 17)),
            ],
          ),
          footer: _Footer(
            raised: true,
            child: GameButton(
              label: 'ACCEPT THE CASE',
              arrow: true,
              singleLine: true,
              style: GameButtonStyle.glass,
              onPressed: () => _show(_file),
            ),
          ),
        );
      default:
        final overview = ref.watch(seasonOverviewProvider);
        final index = _firstCaseIndex(overview);
        return _SceneLayout(
          art: _ParisCaseFile(
            number: w.text('firstCase', 'number'),
            title: w.text('firstCase', 'title'),
            place: w.text('firstCase', 'place'),
            picture: w.text('firstCase', 'picture'),
            line: w.text('firstCase', 'line'),
            ready: index != null,
            t: _c.value,
          ),
          footer: _Footer(
            raised: true,
            child: Opacity(
              opacity: 0.3 + 0.7 * _iv(0.5, 1),
              child: index != null
                  ? GameButton(
                      label: 'START CASE ${w.text('firstCase', 'number')}',
                      arrow: true,
                      singleLine: true,
                      style: GameButtonStyle.glass,
                      // Into the case's file first (what happened, what to
                      // find out, BEGIN INVESTIGATION), as from the case files.
                      onPressed: () => context.go(Routes.caseFile(overview.cases[index].id)),
                    )
                  // The case is not in the game yet: no way into it, only back.
                  : GameButton(
                      label: _way == Routes.gameMaster ? 'BACK TO GAME MASTER' : 'BACK TO THE ARCHIVE',
                      singleLine: true,
                      style: GameButtonStyle.glass,
                      onPressed: () => context.go(_way),
                    ),
            ),
          ),
        );
    }
  }
}

/// The Clockmaker's watch from London, and the word on its back.
class _Watch extends StatelessWidget {
  const _Watch({required this.appear, required this.engraving, required this.engraved});

  final double appear;
  final String engraving;

  /// How far the word has come up (0..1).
  final double engraved;

  @override
  Widget build(BuildContext context) {
    final file = ArtAssets.objects['pocketWatch'];
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: appear,
                child: Transform.scale(
                  scale: 0.94 + 0.06 * appear,
                  child: Transform.rotate(
                    angle: -0.03,
                    child: SizedBox(
                      width: 210,
                      height: 210,
                      child: file == null ? const SizedBox.shrink() : PrintFrame.file(file, border: 6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              Opacity(
                opacity: engraved,
                child: Text(
                  engraving,
                  style: AppText.logo(size: 44, color: AppColors.goldLight).copyWith(
                    letterSpacing: 12 + 4 * (1 - engraved),
                    shadows: [Shadow(color: AppColors.navyDeep.withValues(alpha: 0.8), blurRadius: 14)],
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

/// The train ticket from London to Paris, in the detective's name.
class _Ticket extends StatelessWidget {
  const _Ticket({required this.from, required this.to, required this.passenger, required this.appear});

  final String from;
  final String to;
  final String? passenger;
  final double appear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Opacity(
            opacity: appear,
            child: Transform.translate(
              offset: Offset(-40 * (1 - appear), 0),
              child: Transform.rotate(
                angle: -0.04,
                child: TrainTicket(from: from, to: to, passenger: passenger),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gare du Nord's hall, full screen ([ArtAssets.season2GareDuNord]), the
/// camera moving in a little on its clocks as [push] goes 0 → 1.
class _StationHero extends StatelessWidget {
  const _StationHero({required this.push});

  final double push;

  /// The closest the camera comes.
  static const _maxPush = 1.04;

  /// Where the picture is held when the phone is narrower than the picture
  /// (9:16): the great clocks stand at the right, so the crop leans right
  /// and keeps them whole; the train on the left gives up its outer edge.
  static const _focus = Alignment(0.45, -0.1);

  @override
  Widget build(BuildContext context) {
    const pixels = ArtAssets.season2GareDuNordPixels;
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, box) => Transform.scale(
          scale: 1 + (_maxPush - 1) * push,
          // Towards the station clocks.
          alignment: const Alignment(0.6, -0.15),
          child: Image.asset(
            ArtAssets.season2GareDuNord,
            fit: BoxFit.cover,
            alignment: _focus,
            width: double.infinity,
            height: double.infinity,
            // Decoded once at the width it covers, with room for the push:
            // from the screen only, never from the push (no new decode while
            // it moves), and never above the file.
            cacheWidth: math.min(
              (math.max(box.maxWidth, box.maxHeight * pixels.aspectRatio) * _maxPush * MediaQuery.devicePixelRatioOf(context))
                  .ceil(),
              pixels.width.toInt(),
            ),
            excludeFromSemantics: true,
            // Never another picture in its place: only the night.
            errorBuilder: (context, error, stack) => const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// The Paris map, close in on [at] (a place on it: fractions), as a print.
class _MapPrint extends StatelessWidget {
  const _MapPrint({required this.at, required this.zoom, required this.appear, this.framed = true});

  final Offset at;
  final double zoom;
  final double appear;

  /// A print on the desk (else the map fills the scene).
  final bool framed;

  /// The closest the map comes (its decode size holds it).
  static const _maxZoom = 2.5;

  @override
  Widget build(BuildContext context) {
    final map = LayoutBuilder(
      builder: (context, box) => ClipRect(
        child: Transform.scale(
          scale: zoom,
          alignment: Alignment(at.dx * 2 - 1, at.dy * 2 - 1),
          child: Image.asset(
            ArtAssets.parisMap,
            fit: BoxFit.cover,
            alignment: Alignment(at.dx * 2 - 1, at.dy * 2 - 1),
            width: double.infinity,
            height: double.infinity,
            // Decoded once at a size that holds the closest zoom: never from
            // the zoom itself, which moves every frame (a new decode each time).
            cacheWidth: math.min(
              (box.maxWidth * _maxZoom * MediaQuery.devicePixelRatioOf(context)).ceil(),
              ArtAssets.parisMapPixels.width.toInt(),
            ),
            excludeFromSemantics: true,
            // Never London's map in its place: only the night.
            errorBuilder: (context, error, stack) => const SizedBox.expand(),
          ),
        ),
      ),
    );
    if (!framed) return map;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.sm),
      child: Opacity(opacity: appear, child: PrintFrame(border: 6, child: map)),
    );
  }
}

/// The station's clocks, side by side: they do not show the same time.
class _StationClocks extends StatelessWidget {
  const _StationClocks({required this.times, required this.appear});

  final List<String> times;
  final double Function(int i) appear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, time) in times.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                  child: Opacity(
                    opacity: appear(i),
                    child: Transform.translate(
                      offset: Offset(0, -12 * (1 - appear(i))),
                      child: Transform.rotate(
                        angle: const [-0.05, 0.03, -0.02].elementAt(i % 3),
                        child: SizedBox(
                          width: 92,
                          child: PaperSheet(
                            padding: const EdgeInsets.symmetric(vertical: AppSpace.md, horizontal: AppSpace.sm),
                            child: Column(
                              children: [
                                const InkIcon(InkGlyph.clock, size: AppIconSize.emblem, color: AppColors.navy),
                                const SizedBox(height: AppSpace.sm),
                                Text(
                                  time,
                                  style: AppText.title(size: 22, color: i == times.length - 1 ? AppColors.burgundy : AppColors.navy)
                                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

/// Season 2's first case file. Stamped ASSIGNED once the case can be played;
/// until then COMING SOON.
class _ParisCaseFile extends StatelessWidget {
  const _ParisCaseFile({
    required this.number,
    required this.title,
    required this.place,
    required this.picture,
    required this.line,
    required this.ready,
    required this.t,
  });

  final String number;
  final String title;
  final String place;
  final String picture;
  final String line;
  final bool ready;
  final double t;

  double _iv(double a, double b) => Curves.easeOutCubic.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final slide = _iv(0, 0.5);
    final stamp = Curves.easeInCubic.transform(((t - 0.55) / 0.25).clamp(0.0, 1.0));
    final file = ArtAssets.objects[picture];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 328,
            child: Opacity(
              opacity: slide,
              child: Transform.translate(
                offset: Offset(0, 60 * (1 - slide)),
                child: Transform.rotate(
                  angle: -0.02,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CaseFolder(
                        tab: 'CASE $number',
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CASE FILE', style: AppText.mark(color: AppColors.burgundy)),
                              const SizedBox(height: AppSpace.xs),
                              Text(title.toUpperCase(), style: AppText.logo(size: 24, color: AppColors.navy)),
                              const SizedBox(height: AppSpace.xs),
                              Text(place, style: AppText.eyebrow()),
                              const SizedBox(height: AppSpace.md),
                              if (file != null)
                                Align(
                                  child: Transform.rotate(
                                    angle: 0.03,
                                    child: SizedBox(width: 170, height: 150, child: PrintFrame.file(file, border: 5)),
                                  ),
                                ),
                              const SizedBox(height: AppSpace.lg),
                              Text(line, style: AppText.aside(size: 16, color: AppColors.inkBrown)),
                            ],
                          ),
                        ),
                      ),
                      if (stamp > 0)
                        Positioned(
                          right: AppSpace.lg,
                          bottom: AppSpace.xl,
                          child: Opacity(
                            opacity: stamp,
                            child: Transform.scale(
                              scale: 1.6 - 0.6 * stamp,
                              child: ready
                                  ? const InkStamp('ASSIGNED', size: 13)
                                  : const InkStamp('COMING SOON', color: AppColors.goldDeep, size: 12),
                            ),
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
    );
  }
}
