import 'dart:async';

import 'package:flutter/material.dart';

/// Reveals [text] one character at a time.
class TypewriterText extends StatefulWidget {
  const TypewriterText(
    this.text, {
    super.key,
    required this.style,
    this.charDuration = const Duration(milliseconds: 45),
    this.textAlign = TextAlign.center,
    this.onFinished,
    this.skip = false,
  });

  final String text;
  final TextStyle style;
  final Duration charDuration;
  final TextAlign textAlign;
  final VoidCallback? onFinished;

  /// When true the full text is shown immediately.
  final bool skip;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  int _visible = 0;
  bool _reported = false;

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
    _timer = Timer.periodic(widget.charDuration, (_) {
      if (!mounted) return;
      setState(() => _visible++);
      if (_done) _finish();
    });
  }

  void _finish() {
    _timer?.cancel();
    _timer = null;
    if (!mounted || _reported) return;
    _reported = true;
    setState(() => _visible = widget.text.length);
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
