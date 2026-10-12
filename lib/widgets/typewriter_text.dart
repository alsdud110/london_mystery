import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/audio_service.dart';
import '../features/game/game_providers.dart';

/// Reveals [text] one character at a time, with the soft keys of an old
/// typewriter under it while it types (never once the line is whole).
class TypewriterText extends ConsumerStatefulWidget {
  const TypewriterText(
    this.text, {
    super.key,
    required this.style,
    this.charDuration = const Duration(milliseconds: 45),
    this.textAlign = TextAlign.center,
    this.onFinished,
    this.skip = false,
    this.sound = true,
  });

  final String text;
  final TextStyle style;
  final Duration charDuration;
  final TextAlign textAlign;
  final VoidCallback? onFinished;

  /// When true the full text is shown immediately.
  final bool skip;

  /// Whether the typing is heard.
  final bool sound;

  /// No key sounds closer together than this: about every second letter at
  /// the usual speed, so the typing is a texture, not a rattle.
  static const keyGap = Duration(milliseconds: 70);

  @override
  ConsumerState<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends ConsumerState<TypewriterText> {
  Timer? _timer;
  int _visible = 0;
  bool _reported = false;

  /// Kept from the start: the typing is cut off as the line goes away too.
  late final AudioService _audio = ref.read(audioServiceProvider);

  /// Time since the last key, counted in letters typed. Starts full, so the
  /// first letter is heard.
  late Duration _sinceKey = TypewriterText.keyGap;

  /// Whether a key has sounded for this line (and may need cutting off).
  bool _keyed = false;

  bool get _done => _visible >= widget.text.length;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: the line appears whole (the story still goes line by line).
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _visible = 0;
      _reported = false;
      _start();
    } else if (widget.skip && !_done) {
      _finish();
    }
  }

  void _start() {
    _timer?.cancel();
    if (widget.skip) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return;
    }
    _sinceKey = TypewriterText.keyGap;
    _timer = Timer.periodic(widget.charDuration, (_) {
      if (!mounted) return;
      setState(() => _visible++);
      if (_done) {
        _finish();
      } else {
        _typed(widget.text[_visible - 1]);
      }
    });
  }

  static final _pause = RegExp(r'''[.,;:!?…—–\-"'“”‘’()]''');

  /// The key for the letter just typed, if one is due: never for a space,
  /// and a punctuation mark is a small rest (silent, and the next key waits
  /// a little longer). Quiet while something covers the story (a dialog,
  /// another page).
  void _typed(String char) {
    _sinceKey += widget.charDuration;
    if (!widget.sound || char.trim().isEmpty) return;
    if (_pause.hasMatch(char)) {
      _sinceKey = -widget.charDuration;
      return;
    }
    if (_sinceKey < TypewriterText.keyGap) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _sinceKey = Duration.zero;
    _keyed = true;
    _audio.play(GameSound.typewriterKey);
  }

  /// The line is whole (typed out, tapped, skipped) or gone: no key goes on
  /// sounding after it.
  void _silence() {
    if (!_keyed) return;
    _keyed = false;
    _audio.stop(GameSound.typewriterKey);
  }

  void _finish() {
    _timer?.cancel();
    _timer = null;
    _silence();
    if (!mounted || _reported) return;
    _reported = true;
    setState(() => _visible = widget.text.length);
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _silence();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The hidden remainder keeps the layout stable while typing.
    final shown = widget.text.substring(0, _visible.clamp(0, widget.text.length));
    final hidden = widget.text.substring(shown.length);
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: shown),
          TextSpan(text: hidden, style: const TextStyle(color: Colors.transparent)),
        ]),
        style: widget.style,
        textAlign: widget.textAlign,
      ),
    );
  }
}
