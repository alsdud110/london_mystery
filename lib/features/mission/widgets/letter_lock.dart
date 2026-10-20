import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';

/// A letter lock ([MissionType.letterLock]): a brass plate with a slot for
/// each letter, and the letter tiles the detective found, loose below it.
/// A tile goes into a slot by dragging it there, or by a tap (into the first
/// empty slot); a tile in a slot goes back by a tap, or is dragged to
/// another slot (they swap). With every slot filled, OPEN THE LOCK tries the
/// word (checked like a typed one: the tiles' letters, in slot order).
///
/// Nothing here knows the answer: a wrong word comes back from the check,
/// and the tiles stay where they are to be moved again.
class LetterLockQuestion extends StatefulWidget {
  const LetterLockQuestion({super.key, required this.mission, required this.onSubmit, this.onChanged});

  final Mission mission;
  final void Function(String answer) onSubmit;

  /// The letter in each slot (null: empty), after every move: the box the
  /// lock is on shows them in its own slots.
  final ValueChanged<List<String?>>? onChanged;

  @override
  State<LetterLockQuestion> createState() => _LetterLockQuestionState();
}

class _LetterLockQuestionState extends State<LetterLockQuestion> {
  /// The tile in each slot (an option id), or null while it is empty.
  late final List<String?> _slots = List.filled(widget.mission.options.length, null);

  List<ChoiceOption> get _tiles => widget.mission.options;

  String _letter(String id) => _tiles.firstWhere((o) => o.id == id).label;

  /// The tiles not in a slot, in their own order.
  List<ChoiceOption> get _loose => [for (final t in _tiles) if (!_slots.contains(t.id)) t];

  bool get _full => !_slots.contains(null);

  void _report() => widget.onChanged?.call([for (final id in _slots) id == null ? null : _letter(id)]);

  /// [id] into slot [slot]: a tile already there goes where [id] came from
  /// (another slot, or back to the loose tiles).
  void _place(String id, int slot) {
    HapticFeedback.selectionClick();
    setState(() {
      final from = _slots.indexOf(id);
      final there = _slots[slot];
      if (from >= 0) _slots[from] = there;
      _slots[slot] = id;
    });
    _report();
  }

  /// A loose tile tapped: into the first empty slot.
  void _tapLoose(String id) {
    final empty = _slots.indexOf(null);
    if (empty >= 0) _place(id, empty);
  }

  /// A tile in a slot tapped: back with the loose tiles.
  void _tapSlot(int slot) {
    if (_slots[slot] == null) return;
    HapticFeedback.selectionClick();
    setState(() => _slots[slot] = null);
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final word = [for (final id in _slots) id == null ? '' : _letter(id)].join();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The lock: its plate, and the slots in a row.
        Semantics(
          label: 'Letter lock, ${_slots.length} slots${word.isEmpty ? '' : ': $word'}',
          container: true,
          child: Container(
            padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.lg),
            decoration: BoxDecoration(
              color: AppColors.walnut,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.gold, width: AppLine.rule),
              boxShadow: AppShadow.paperLift,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const InkIcon(InkGlyph.gear, size: AppIconSize.small, color: AppColors.goldLight),
                    const SizedBox(width: AppSpace.xs),
                    Text('THE CLOCKMAKER\'S LOCK', style: AppText.eyebrow(color: AppColors.goldLight)),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _slots.length; i++)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                          child: _Slot(
                            key: ValueKey('lock-slot-$i'),
                            index: i,
                            letter: _slots[i] == null ? null : _letter(_slots[i]!),
                            tileId: _slots[i],
                            onAccept: (id) => _place(id, i),
                            onTap: () => _tapSlot(i),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        // The letters found, loose on the desk.
        Text(
          _loose.isEmpty ? 'Every letter is in the lock.' : 'Drag a letter into the lock, or tap it.',
          textAlign: TextAlign.center,
          style: AppText.caption(color: AppColors.inkBrown),
        ),
        const SizedBox(height: AppSpace.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _Tile.size),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.md,
            runSpacing: AppSpace.sm,
            children: [
              for (final t in _loose)
                Draggable<String>(
                  key: ValueKey('lock-tile-${t.id}'),
                  data: t.id,
                  feedback: Material(type: MaterialType.transparency, child: _Tile(t.label, lifted: true)),
                  childWhenDragging: const _TileGap(),
                  child: _Tile(t.label, onTap: () => _tapLoose(t.id)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        GameButton(
          label: 'OPEN THE LOCK',
          style: GameButtonStyle.navy,
          singleLine: true,
          onPressed: _full ? () => widget.onSubmit(word) : null,
        ),
      ],
    );
  }
}

/// One slot of the lock: empty (a recess), or holding a tile.
class _Slot extends StatelessWidget {
  const _Slot({super.key, required this.index, required this.letter, required this.tileId, required this.onAccept, required this.onTap});

  final int index;
  final String? letter;
  final String? tileId;
  final void Function(String id) onAccept;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != tileId,
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (context, candidates, _) {
        final over = candidates.isNotEmpty;
        final tile = letter == null
            ? null
            : Draggable<String>(
                data: tileId,
                feedback: Material(type: MaterialType.transparency, child: _Tile(letter!, lifted: true)),
                childWhenDragging: const _TileGap(),
                child: _Tile(letter!, onTap: onTap),
              );
        return Semantics(
          button: letter != null,
          label: letter == null ? 'Slot ${index + 1}, empty' : 'Slot ${index + 1}: $letter. Tap to take it out.',
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: _Tile.size + 8,
            height: _Tile.size + 8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.walnutDeep,
              borderRadius: BorderRadius.circular(AppRadius.paper),
              border: Border.all(color: over ? AppColors.goldLight : AppColors.goldDeep, width: over ? AppLine.ink : AppLine.hairline),
            ),
            child: tile,
          ),
        );
      },
    );
  }
}

/// A letter tile: a square of card with a letter stamped on it.
class _Tile extends StatelessWidget {
  const _Tile(this.letter, {this.onTap, this.lifted = false});

  final String letter;
  final VoidCallback? onTap;
  final bool lifted;

  /// Comfortably over a fingertip.
  static const size = 56.0;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.paperLight,
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: AppColors.inkBrown.withValues(alpha: 0.6), width: AppLine.hairline),
        boxShadow: lifted ? AppShadow.onNight : AppShadow.paperLift,
      ),
      child: Text(letter, style: AppText.logo(size: 30, color: AppColors.navy)),
    );
    if (onTap == null) return tile;
    return Semantics(
      button: true,
      label: 'Letter $letter',
      excludeSemantics: true,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: tile),
    );
  }
}

/// A letter lock's final stage: the case's place, with the lock's brass
/// plate over it. Opening ([animation] 0 → 1): the word's letters are pressed
/// into the slots one by one, the plate gives a small jolt as it unlocks,
/// then it drops away and the place settles into view. 1 (solved, or a
/// revisit) shows the place alone.
class LetterLockReveal extends StatelessWidget {
  const LetterLockReveal({super.key, required this.animation, required this.word, required this.place});

  final Animation<double> animation;

  /// The word that opens the lock, one letter a slot.
  final String word;

  /// The place behind the lock (the case's own picture).
  final Widget place;

  @override
  Widget build(BuildContext context) {
    final letters = word.split('');
    return AnimatedBuilder(
      animation: animation,
      child: place,
      builder: (context, place) {
        final t = animation.value;
        // 0–0.35: the letters go in; 0.35–0.45: the jolt; 0.45–0.75: it drops.
        final shown = t <= 0 ? 0 : (t / 0.35 * letters.length).ceil().clamp(0, letters.length);
        final jolt = t > 0.35 && t < 0.45 ? math.sin((t - 0.35) * 160) * 3 : 0.0;
        final drop = Curves.easeInCubic.transform(((t - 0.45) / 0.3).clamp(0.0, 1.0));
        final open = drop >= 1;
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: 0.55 + 0.45 * drop, child: place),
            if (!open)
              Align(
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(jolt, drop * 80),
                  child: Opacity(
                    opacity: 1 - drop,
                    child: Semantics(
                      label: t >= 0.35 ? 'The lock opens' : 'The Clockmaker\'s lock',
                      child: _LockPlate(letters: letters, shown: shown, glowing: t >= 0.35),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The lock's brass plate on its own: its slots, the first [shown] holding
/// their letters.
class _LockPlate extends StatelessWidget {
  const _LockPlate({required this.letters, required this.shown, required this.glowing});

  final List<String> letters;
  final int shown;
  final bool glowing;

  static const _slot = 40.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.walnut,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: glowing ? AppColors.goldLight : AppColors.gold, width: AppLine.rule),
        boxShadow: AppShadow.onNight,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < letters.length; i++)
            Container(
              width: _slot,
              height: _slot,
              margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs / 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i < shown ? AppColors.paperLight : AppColors.walnutDeep,
                borderRadius: BorderRadius.circular(AppRadius.paper),
                border: Border.all(color: AppColors.goldDeep, width: AppLine.hairline),
              ),
              child: i < shown ? Text(letters[i], style: AppText.logo(size: 22, color: AppColors.navy)) : null,
            ),
        ],
      ),
    );
  }
}

/// Where a tile was, while it is dragged.
class _TileGap extends StatelessWidget {
  const _TileGap();

  @override
  Widget build(BuildContext context) => Container(
    width: _Tile.size,
    height: _Tile.size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.paper),
      border: Border.all(color: AppColors.inkBrown.withValues(alpha: 0.25), width: AppLine.hairline),
    ),
  );
}
