import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// A simple grown-ups-only check (random multiplication) before opening
/// operator tools. It keeps curious kids out; it is not an auth mechanism.
abstract final class ParentGate {
  static Future<bool> show(BuildContext context) async {
    final rnd = math.Random();
    final a = 6 + rnd.nextInt(4);
    final b = 6 + rnd.nextInt(4);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => _ParentGateDialog(a: a, b: b),
    );
    return ok ?? false;
  }
}

/// Owns the answer field's controller. showDialog's future completes as soon
/// as the dialog is popped, while the field is still on screen for the closing
/// animation, so the controller must be disposed with this State, not by the
/// caller.
class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog({required this.a, required this.b});

  final int a;
  final int b;

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isCorrect(String v) => v == '${widget.a * widget.b}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Above the keyboard on a small phone the room is short: scroll inside.
      scrollable: true,
      backgroundColor: AppColors.paper,
      title: Text('For grown-ups', style: AppText.title(size: 22)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('보호자/운영자 확인\nWhat is ${widget.a} × ${widget.b}?', textAlign: TextAlign.center, style: AppText.bodyText()),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            onSubmitted: (v) => Navigator.of(context).pop(_isCorrect(v)),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_isCorrect(_controller.text)),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
