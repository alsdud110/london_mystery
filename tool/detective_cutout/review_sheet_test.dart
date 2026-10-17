// Review sheet for the detective cut-outs: every picture on the game's
// night navy, on parchment, and on magenta (any white or grey fringe left
// from the checker shows at once), plus a close-up of an edge.
//
//   LM_REVIEW=<folder> flutter test tool/detective_cutout/review_sheet_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _avatars = ['boy', 'girl'];
const _expressions = ['thinking', 'surprised', 'investigating', 'happy', 'confident'];

void main() {
  final out = Platform.environment['LM_REVIEW'];

  testWidgets('review sheet', (t) async {
    if (out == null) return;
    final images = <String, ui.Image>{};
    await t.runAsync(() async {
      for (final a in _avatars) {
        for (final e in _expressions) {
          final codec = await ui.instantiateImageCodec(File('assets/art/detectives/$a/$e.png').readAsBytesSync());
          images['$a/$e'] = (await codec.getNextFrame()).image;
        }
      }
    });
    const cell = 220.0;
    const backs = [Color(0xFF151D30), Color(0xFFEDE2C9), Color(0xFFFF00FF)];
    t.view.physicalSize = Size(cell * 10, cell * 3 + 30);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: Colors.black,
          child: Column(children: [
            for (final back in backs)
              Row(children: [
                for (final a in _avatars)
                  for (final e in _expressions)
                    Container(
                      width: cell,
                      height: cell,
                      color: back,
                      child: RawImage(image: images['$a/$e'], fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                    ),
              ]),
          ]),
        ),
      ),
    ));
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage();
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$out/cutout_sheet.png').writeAsBytesSync(png!.buffer.asUint8List());
    });

    // Close-ups at full size on magenta: the edge pixels themselves.
    for (final name in images.keys) {
      t.view.physicalSize = const Size(700, 700);
      await t.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFFFF00FF),
            child: ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                alignment: Platform.environment['LM_REVIEW_FOCUS'] == 'left'
                    ? const Alignment(-1, 0.2)
                    : const Alignment(-0.2, -0.3),
                child: RawImage(image: images[name], scale: 1),
              ),
            ),
          ),
        ),
      ));
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage();
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$out/closeup_${name.replaceAll('/', '_')}.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
  });
}
