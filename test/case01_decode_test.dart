import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/core/utils/audio_service.dart';
import 'package:world_mystery/data/mock/season1/season1_decodes.dart';
import 'package:world_mystery/data/mock/season1/season1_discoveries.dart';
import 'package:world_mystery/data/mock/season1/season1_learning.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/scoring.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/features/mission/widgets/scene_explore.dart' show LookMark;
import 'package:world_mystery/widgets/game_button.dart';
import 'package:world_mystery/widgets/royal_box_picture.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Case 01 Mission 05: the crown card by the palace gate. The detective
/// finds an old card leaning on the gate's stone pier (a crown, and a
/// square symbol drawn like a QR code), taps it to look closer, examines its
/// code — a short scan drawn by the game: no camera, no real decoding — and
/// the code's hidden message appears on the card: the four pictures of the
/// Royal Box locks, in order (CLOCK → TRAIN → PARK → MUSEUM), never their
/// numbers. Taking the card gives the Crown Symbol (e05) and the Royal Box
/// clue (c05), and opens the final case, where 7924 is still put together
/// and typed by the detective.
void main() {
  final season = MockEpisodeRepository.bundled();
  final ep01 = season.firstWhere((e) => e.id == 'ep01');
  final m05 = ep01.missionById('m05')!;
  final scene = decodeOf(m05)!;
  const order = ['clock', 'train', 'park', 'museum'];
  final digits = RegExp(r'\d');

  // The code as drawn on the card (measured on the picture).
  const qr = Rect.fromLTRB(652 / 1536, 420 / 1024, 972 / 1536, 706 / 1024);

  Size pngSize(String path) {
    final b = File(path).readAsBytesSync();
    int word(int at) => (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3];
    return Size(word(16).toDouble(), word(20).toDouble());
  }

  group('the scene', () {
    test('the new picture is in the app, at the size its places are measured on', () {
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/seasons/season_01_london/cases/case_01/'));
      expect(scene.picture, 'assets/seasons/season_01_london/cases/case_01/buckingham_palace_crown_card.png');
      expect(File(scene.picture).existsSync(), isTrue);
      expect(pngSize(scene.picture), Size(scene.pixels.width, scene.pixels.height));
      expect(scene.pixels.width, 1536);
      expect(scene.pixels.height, 1024);
    });

    test('the card, its code and the cleared part are inside the paper edge; only the code is cleared', () {
      for (final r in [...scene.areas, scene.closer, scene.code, scene.clearedArea, scene.revealed]) {
        expect(scene.inside.contains(r.topLeft) && scene.inside.contains(r.bottomRight - const Offset(1e-6, 1e-6)), isTrue,
            reason: '$r');
      }
      expect(scene.closer.contains(scene.code.topLeft) && scene.closer.contains(scene.code.bottomRight), isTrue);
      // The cleared part holds the whole code as drawn (measured: about
      // x 652–972, y 420–706) …
      expect(scene.clearedArea.contains(qr.topLeft) && scene.clearedArea.contains(qr.bottomRight), isTrue);
      // … and, measured on the picture, stops short of the crown (it ends
      // about x 620) and of the card's border lines (about x 1000 on the
      // right, y 740 below): they cannot be touched.
      expect(scene.clearedArea.left * 1536, greaterThan(620), reason: 'the crown stays as drawn');
      expect(scene.clearedArea.right * 1536, lessThan(1000), reason: "the card's border stays as drawn");
      expect(scene.clearedArea.bottom * 1024, lessThan(740), reason: "the card's lower border stays as drawn");
      // Decoded, the view comes closer still, the message whole in it.
      expect(scene.revealed.width, lessThan(scene.closer.width));
      expect(scene.revealed.contains(scene.clearedArea.topLeft) && scene.revealed.contains(scene.clearedArea.bottomRight), isTrue);
      expect(scene.ink.computeLuminance(), lessThan(0.1));
    });

    // The card once decoded: its own pixels in the cleared part, the code's
    // ink taken off and the paper restored (tool/card_code_clear); the card
    // itself never changed.
    test('the cleared part: the card where there was no ink, plain paper where the code was', () async {
      Future<({int w, int h, Uint8List px})> load(String path) async {
        final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
        final img = (await codec.getNextFrame()).image;
        final data = (await img.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!;
        return (w: img.width, h: img.height, px: data.buffer.asUint8List());
      }

      final card = await load(scene.picture);
      final cleared = await load(scene.cleared);
      final ax = (scene.clearedArea.left * 1536).round(), ay = (scene.clearedArea.top * 1024).round();
      expect((cleared.w, cleared.h), ((scene.clearedArea.width * 1536).round(), (scene.clearedArea.height * 1024).round()));
      double lum(Uint8List px, int i) => 0.299 * px[i] + 0.587 * px[i + 1] + 0.114 * px[i + 2];
      var same = 0, inkBefore = 0, inkAfter = 0, keptSame = 0, kept = 0;
      for (var y = 0; y < cleared.h; y++) {
        for (var x = 0; x < cleared.w; x++) {
          final c = (y * cleared.w + x) * 4, o = ((ay + y) * card.w + ax + x) * 4;
          final identical = cleared.px[c] == card.px[o] && cleared.px[c + 1] == card.px[o + 1] && cleared.px[c + 2] == card.px[o + 2];
          if (identical) same++;
          // The code's dark ink, within the code itself.
          final inCode = ax + x >= 655 && ax + x <= 970 && ay + y >= 422 && ay + y <= 704;
          final fleurOrStains = (ax + x < 686 && ay + y > 690) || (ax + x > 932 && ay + y < 520);
          if (inCode && !fleurOrStains) {
            if (lum(card.px, o) < 110) inkBefore++;
            if (lum(cleared.px, c) < 110) inkAfter++;
          }
          if (fleurOrStains) {
            kept++;
            if (identical) keptSame++;
          }
        }
      }
      final n = cleared.w * cleared.h;
      expect(inkBefore / n, greaterThan(0.2), reason: 'the code was there');
      expect(inkAfter / n, lessThan(0.002), reason: 'no ink of the code is left');
      expect(same / n, greaterThan(0.25), reason: 'the card as it was wherever there was no ink');
      expect(keptSame, kept, reason: 'the fleur-de-lis and the old stains untouched');
    });

    // Measured on the picture (1536 × 1024): the card leans from about x 145
    // to 1115, y 250 to 830; the crown about (295–620, 380–690); the square
    // symbol about (650–975, 420–705); the palace, lamps and sky above and
    // right of it, wet paving below.
    test('a tap reaches the card where it is drawn, and nothing else', () {
      Offset px(double x, double y) => Offset(x / 1536, y / 1024);
      for (final (label, p) in [
        ('the crown', px(455, 535)),
        ('the square symbol', px(810, 560)),
        ('the glass on the symbol', scene.mark),
        ("the card's left edge", px(200, 600)),
        ("the card's lower right, leaning out", px(1050, 760)),
        ("the card's top-left corner", px(250, 280)),
      ]) {
        expect(scene.hits(p), isTrue, reason: label);
      }
      for (final (label, p) in [
        ('the sky', px(1300, 120)),
        ('the palace', px(1250, 300)),
        ('the railings, right', px(1300, 520)),
        ('the paving, below', px(700, 930)),
        ('the leaves, bottom left', px(120, 880)),
        ('the stone pier, above the card', px(250, 150)),
      ]) {
        expect(scene.hits(p), isFalse, reason: label);
      }
    });

    test('on the narrowest phone the card is far more than a fingertip wide', () {
      final scale = 360 / (scene.inside.width * scene.pixels.width);
      final card = scene.areas.first;
      expect(card.width * scene.pixels.width * scale, greaterThan(150));
      expect(card.height * scene.pixels.height * scale, greaterThan(100));
    });
  });

  group('the mission', () {
    test('a card examined: nothing to type or choose, never a wrong answer', () {
      expect(m05.type, MissionType.examine);
      expect(m05.options, isEmpty);
      expect(m05.codeLength, isNull);
      expect(AnswerChecker.isCorrect(m05, m05.answer), isTrue);
      expect(AnswerChecker.isCorrect(m05, 'LM-EP01-PALACE'), isFalse, reason: 'the old QR code is gone');
      expect(m05.answerLabel, isNot(contains(m05.answer)), reason: 'the answer key says to examine, not a code');
    });

    test('two hints, about the card on screen; nobody to ask', () {
      expect(m05.hints, hasLength(2));
      expect(m05.hints[0], contains('card near the palace gate'));
      expect(m05.hints[1], contains('symbol beside the crown'));
      for (final h in m05.hints) {
        for (final gone in ['guide', 'ask', 'grown-up', 'parent', 'sticker', 'QR', 'scan']) {
          expect(h.toLowerCase(), isNot(contains(gone.toLowerCase())), reason: '$h / $gone');
        }
      }
    });

    test('no QR code, sticker, camera or game guide is left in its data', () {
      final json = jsonEncode(m05.toJson());
      for (final old in ['QR', 'LM-EP01-PALACE', 'sticker', 'game guide', 'Scan it', 'camera']) {
        expect(json, isNot(contains(old)), reason: old);
      }
      expect(season1Learning['m05']!.objective, isNot(contains('QR')));
    });

    test('the order is the case\'s own: CLOCK → TRAIN → PARK → MUSEUM, the final locks\' order', () {
      expect(m05.evidence!.symbols, order);
      expect(ep01.finalMission.dialSymbols, order);
    });

    test('no number is ever said: not 7924, nor any digit, before or after the card is decoded', () {
      final d = discoveryOf(m05);
      final said = [
        ...m05.story, m05.question, m05.letterIntro, m05.letter, ...m05.hints, m05.successMessage,
        ...m05.transition, scene.found, scene.tapTask, scene.closerTask, scene.missLine, scene.place, scene.thing,
        scene.examine, scene.take, d.title, d.detail,
      ];
      for (final line in said) {
        expect(line, isNot(contains('7924')), reason: line);
        expect(digits.hasMatch(line), isFalse, reason: line);
      }
    });

    test('the hidden message is the letter, short: four pictures, four locks, remember the order', () {
      expect(m05.letter, 'Four pictures. Four locks.\nRemember the order.');
    });
  });

  group('the case is kept', () {
    test('Crown Symbol (e05) and the Royal Box clue (c05), as they were', () {
      final e = m05.evidence!;
      expect(e.id, 'e05');
      expect(e.name, 'Crown Symbol');
      expect(e.icon, 'crown');
      expect(e.inscription, 'Four pictures for four locks.\nRead them from left to right.');
      final c = m05.clue!;
      expect(c.id, 'c05');
      expect(c.title, 'The Royal Box');
      expect(c.value, '4 locks');
      expect(c.symbol, 'crown');
      expect(m05.nextMissionId, 'final');
      final d = discoveryOf(m05);
      expect(d.title, 'CROWN SYMBOL');
      expect(d.showEvidence, isTrue);
    });

    test('the final is unchanged: four picture locks, 7924, typed by the detective', () {
      final fin = ep01.finalMission;
      expect(fin.type, MissionType.finalCode);
      expect(fin.answer, '7924');
      expect(fin.codeLength, 4);
      expect(AnswerChecker.isCorrect(fin, '7924'), isTrue);
      expect(AnswerChecker.isCorrect(fin, '9274'), isFalse);
      // Each lock's number is the notebook clue of its picture.
      final numberBySymbol = {for (final c in ep01.allClues) c.symbol: c.value};
      expect(fin.dialSymbols.map((s) => numberBySymbol[s]).join(), '7924');
    });

    test('a save that solved the old QR mission still loads, M5 solved, the final open', () {
      final p = GameProgress.fromJson(
        jsonDecode(
              jsonEncode(
                const GameProgress(
                  detectiveName: 'MINYOUNG',
                  completedMissionIds: ['m01', 'm02', 'm03', 'm04', 'm05'],
                  attempts: {'m01': 1, 'm02': 1, 'm03': 1, 'm04': 1, 'm05': 1},
                ).toJson(),
              ),
            )
            as Map<String, dynamic>,
      );
      expect(p.isCompleted('m05'), isTrue);
      expect(p.isUnlocked(ep01, 'final'), isTrue);
      expect(p.collectedClues(ep01).map((c) => c.id), contains('c05'));
      expect(p.collectedEvidence(ep01).map((e) => e.id), contains('e05'));
      expect(XpBreakdown.of(m05, p).total, greaterThan(0));
    });

    test('no camera anywhere: no scanner package, no camera permission, no scanner code', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('mobile_scanner')));
      expect(pubspec, isNot(contains('qr_flutter')));
      expect(File('android/app/src/main/AndroidManifest.xml').readAsStringSync(), isNot(contains('CAMERA')));
      expect(File('ios/Runner/Info.plist').readAsStringSync(), isNot(contains('NSCameraUsageDescription')));
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final src = f.readAsStringSync();
        expect(src, isNot(contains('mobile_scanner')), reason: f.path);
        expect(src, isNot(contains('qr_flutter')), reason: f.path);
      }
    });
  });

  group('on screen', () {
    String step(WidgetTester t) => t.widget<Text>(find.byKey(const ValueKey('decode-step'))).data!;
    Finder examine() => find.byKey(const ValueKey('decode-examine'));
    Finder take() => find.byKey(const ValueKey('decode-take'));
    Rect pictureRect(WidgetTester t) => t.getRect(find.byKey(const ValueKey('decode-picture')));

    Future<void> back(WidgetTester t) async {
      await t.tap(find.byWidgetPredicate((w) => w is IconButton && (w.tooltip == 'Back' || w.tooltip == 'Back to map')));
      await wait(t, const Duration(milliseconds: 800));
    }

    /// Every number written in the panel and on the card's message.
    Iterable<String> writtenNumbers(WidgetTester t) => [
          for (final key in ['decode-panel', 'decode-message'])
            for (final w in t.widgetList<Text>(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(Text))))
              if (digits.hasMatch(w.data ?? w.textSpan?.toPlainText() ?? '')) w.data ?? w.textSpan!.toPlainText(),
        ];

    for (final size in const [Size(360, 640), Size(430, 932), Size(768, 1024)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: the card found, brought closer, its code examined, the pictures in order; taken', (t) async {
        final audio = MockAudioService();
        final play = MissionPlay(audio: audio);
        await play.openPuzzle(t, size, 'm05');
        final heard = audio.played.length;
        expect(find.text('TAP TO OPEN'), findsNothing, reason: 'no envelope');
        expect(find.text("Can't scan? Type the code"), findsNothing);
        expect(find.byType(TextField), findsNothing, reason: 'nothing to type');
        expect(step(t), 'MISSION 05 · INVESTIGATE');
        expect(findReadable(scene.found), findsOneWidget);
        expect(find.byKey(const ValueKey('decode-mark')), findsOneWidget);
        expect(t.widget<LookMark>(find.byKey(const ValueKey('decode-mark'))).looked, isFalse);
        expect(examine(), findsNothing, reason: 'nothing to examine before the card is found');
        final whole = pictureRect(t);
        await capture(t, 'case01_decode_start_$tag');

        // The paving: a line, never a wrong answer.
        await play.tapDecode(t, const Offset(700 / 1536, 930 / 1024));
        expect(find.text(scene.missLine), findsOneWidget);
        expect(play.ref.read(gameControllerProvider).wrongCount('m05'), 0);
        expect(step(t), 'MISSION 05 · INVESTIGATE');

        // The square symbol: the card comes closer.
        await play.tapDecode(t, const Offset(810 / 1536, 560 / 1024));
        expect(step(t), 'LOOK CLOSER');
        expect(find.byKey(const ValueKey('decode-mark')), findsNothing);
        expect(find.byKey(const ValueKey('decode-code')), findsOneWidget, reason: 'the code edged in gold');
        expect(find.byKey(const ValueKey('decode-cleared')), findsNothing, reason: 'the code still on the card');
        final closer = pictureRect(t);
        expect(closer.width, greaterThan(whole.width * 1.15), reason: 'closer');
        final code = t.getRect(find.byKey(const ValueKey('decode-code')));
        expect(Rect.fromLTWH(0, 0, size.width, size.height).contains(code.center), isTrue, reason: 'the code in sight');
        await capture(t, 'case01_decode_closer_$tag');

        // The scan: a line passing down, the button resting; about a second.
        await t.tap(examine());
        await t.pump(); // the scan's first frame
        await t.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const ValueKey('decode-scan-line')), findsOneWidget);
        expect(t.widget<GameButton>(examine()).onPressed, isNull);
        expect(find.text('EXAMINING THE CODE…'), findsOneWidget);
        expect(findReadable(scene.closerTask), findsOneWidget, reason: 'the line stays: the card does not move');
        expect(pictureRect(t), closer, reason: 'the card stays still under the scan');
        final at300 = t.getRect(find.byKey(const ValueKey('decode-scan-line'))).top;
        await t.pump(const Duration(milliseconds: 300));
        expect(t.getRect(find.byKey(const ValueKey('decode-scan-line'))).top, greaterThan(at300), reason: 'it moves down');
        await capture(t, 'case01_decode_scan_$tag');
        await wait(t, const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('decode-scan-line')), findsNothing, reason: 'done within about a second');
        expect(step(t), 'THE HIDDEN MESSAGE');
        expect(t.widget<GameButton>(take()).onPressed, isNull, reason: 'TAKE THE CARD wakes once the message is whole');
        await wait(t, const Duration(milliseconds: 1600));
        expect(t.widget<GameButton>(take()).onPressed, isNotNull);

        // The code gone from the card: the card's own restored paper, whole,
        // exactly where the code was; the message drawn there with no
        // paper, frame or shadow of its own; the crown as drawn.
        final cleared = find.byKey(const ValueKey('decode-cleared'));
        expect(cleared, findsOneWidget);
        final fade = t.widget<FadeTransition>(find.descendant(of: cleared, matching: find.byType(FadeTransition)));
        expect(fade.opacity.value, 1, reason: 'the ink all gone');
        final clearedImage = t.widget<Image>(find.descendant(of: cleared, matching: find.byType(Image)));
        expect((clearedImage.image as AssetImage).assetName, scene.cleared);
        expect(
          find.descendant(of: find.byKey(const ValueKey('decode-message')), matching: find.byType(DecoratedBox)),
          findsNothing,
          reason: 'no paper or frame behind the pictures',
        );
        final picture = pictureRect(t);
        Rect onScreen(Rect r) => Rect.fromLTRB(
              picture.left + r.left * picture.width,
              picture.top + r.top * picture.height,
              picture.left + r.right * picture.width,
              picture.top + r.bottom * picture.height,
            );
        final message = t.getRect(find.byKey(const ValueKey('decode-message')));
        final codeArea = onScreen(qr);
        expect(message.contains(codeArea.topLeft) && message.contains(codeArea.bottomRight), isTrue,
            reason: 'the message where the code was');
        expect(t.getRect(cleared), message, reason: 'the cleared paper exactly under the message');
        final crown = onScreen(const Rect.fromLTRB(295 / 1536, 380 / 1024, 620 / 1536, 690 / 1024));
        expect(message.overlaps(crown), isFalse, reason: 'the crown stays in sight');

        // The four pictures, read like a page: two lines of two, left to right.
        Rect at(String s) => t.getRect(find.byKey(ValueKey('decode-symbol-$s')));
        final (clock, train, park, museum) = (at('clock'), at('train'), at('park'), at('museum'));
        expect(clock.center.dy, moreOrLessEquals(train.center.dy, epsilon: clock.height * 0.25), reason: 'CLOCK, TRAIN: the first line (on the card, turned a little)');
        expect(park.center.dy, moreOrLessEquals(museum.center.dy, epsilon: park.height * 0.25), reason: 'SWAN, STONE: the second');
        expect(park.top, greaterThan(clock.bottom), reason: 'the second line under the first');
        expect(clock.center.dx, lessThan(train.center.dx), reason: 'CLOCK → TRAIN');
        expect(park.center.dx, lessThan(museum.center.dx), reason: 'SWAN → STONE');
        expect(park.center.dx, moreOrLessEquals(clock.center.dx, epsilon: clock.width * 0.25), reason: 'each line starts on the left');
        final pictures = [clock, train, park, museum];
        for (final (i, r) in pictures.indexed) {
          expect(r.width, greaterThanOrEqualTo(56), reason: 'a picture large enough to see its drawing');
          for (final other in pictures.skip(i + 1)) {
            expect(r.overlaps(other), isFalse, reason: 'the pictures apart');
          }
        }
        // Each the Royal Box's own picture, in full colour, with its name
        // whole under it.
        for (final (s, name) in const [('clock', 'CLOCK'), ('train', 'TRAIN'), ('park', 'SWAN'), ('museum', 'STONE')]) {
          final image = t.widget<Image>(find.descendant(of: find.byKey(ValueKey('decode-symbol-$s')), matching: find.byType(Image)));
          expect((image.image as AssetImage).assetName, RoyalBoxPicture.of(s)!.file, reason: s);
          expect(image.color, isNull, reason: 'never tinted');
          final label = find.descendant(of: find.byKey(ValueKey('decode-name-$s')), matching: find.text(name));
          expect(label, findsOneWidget, reason: name);
          expect(t.renderObject<RenderParagraph>(label).didExceedMaxLines, isFalse, reason: name);
        }
        expect(writtenNumbers(t), isEmpty, reason: 'pictures only: no number, no 7924');
        expect(find.textContaining('7924'), findsNothing);
        expect(findReadableContaining('Four pictures. Four locks.'), findsOneWidget);
        expect(findReadableContaining('Remember the order.'), findsOneWidget);
        expect(findReadableContaining('Detective'), findsNothing, reason: 'short: no name');
        expect(t.getRect(take()).bottom, lessThanOrEqualTo(size.height), reason: 'TAKE THE CARD in sight');
        expect(audio.played.length, heard, reason: 'no sound of its own: the card is seen, not heard');
        await capture(t, 'case01_decode_message_$tag');

        // Taken: the Crown Symbol, the Royal Box clue, the final open.
        await play.tapKey(t, 'decode-take', after: const Duration(milliseconds: 1500));
        final p = play.ref.read(gameControllerProvider);
        expect(p.isCompleted('m05'), isTrue);
        expect(p.attempts['m05'], 1);
        expect(p.wrongCount('m05'), 0);
        expect(p.isUnlocked(ep01, 'final'), isTrue);
        expect(p.collectedClues(ep01).map((c) => c.id), contains('c05'));
        expect(p.collectedEvidence(ep01).map((e) => e.id), contains('e05'));
        final moment = find.byKey(const ValueKey('discovery-moment'));
        expect(moment, findsOneWidget);
        expect(find.descendant(of: moment, matching: find.text('CROWN SYMBOL')), findsOneWidget);
        expect(play.path(), Routes.mission('m05'), reason: 'never left for a camera page');
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('360x640, text ×1.3: the card keeps its share; EXAMINE and TAKE in sight; solved', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'm05', textScale: 1.3);
      await play.tapDecode(t, scene.areas.first.center);
      expect(t.takeException(), isNull);
      expect(t.getRect(find.byKey(const ValueKey('decode-code'))).height, greaterThan(60), reason: 'the code readable');
      expect(t.getRect(examine()).bottom, lessThanOrEqualTo(640));
      await play.tapKey(t, 'decode-examine', after: const Duration(milliseconds: 2800));
      expect(t.takeException(), isNull);
      expect(t.getRect(take()).bottom, lessThanOrEqualTo(640), reason: 'TAKE THE CARD in sight');
      expect(t.getRect(find.byKey(const ValueKey('decode-message'))).height, greaterThan(60));
      expect(t.getRect(find.byKey(const ValueKey('decode-symbol-park'))).width, greaterThanOrEqualTo(48));
      expect(t.renderObject<RenderParagraph>(find.text('STONE')).didExceedMaxLines, isFalse);
      await capture(t, 'case01_decode_text13');
      await play.tapKey(t, 'decode-take', after: const Duration(milliseconds: 1500));
      expect(play.ref.read(gameControllerProvider).isCompleted('m05'), isTrue);
    });

    testWidgets('reduce motion: no scan to wait for, the message at once', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm05');
      await play.tapDecode(t, scene.areas.first.center, after: const Duration(milliseconds: 100));
      expect(step(t), 'LOOK CLOSER');
      await t.tap(examine());
      await t.pump();
      expect(find.byKey(const ValueKey('decode-scan-line')), findsNothing);
      expect(step(t), 'THE HIDDEN MESSAGE');
      await t.pump(const Duration(milliseconds: 50));
      for (final s in order) {
        expect(find.byKey(ValueKey('decode-symbol-$s')), findsOneWidget, reason: s);
      }
    });

    testWidgets('both hints, then no more', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm05');
      await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 600));
      await takeTipFromSheet(t);
      await reveal(t, findReadable(m05.hints[0]));
      expect(findReadable(m05.hints[0]), findsOneWidget);
      await tapText(t, 'Get More Hints', after: const Duration(milliseconds: 600));
      await takeTipFromSheet(t);
      await reveal(t, findReadable(m05.hints[1]));
      expect(findReadable(m05.hints[1]), findsOneWidget);
      expect(hintAction(), findsNothing, reason: 'at most two');
      expect(play.ref.read(gameControllerProvider).hintsFor('m05'), 2);
    });

    testWidgets('back: the card back in its place, then the place; a scan left half-way is examined again', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm05');
      // Back before anything: the place, with its own scene (not the card).
      await back(t);
      expect(find.text('INVESTIGATE'), findsOneWidget, reason: 'no letter step');
      expect(find.byKey(const ValueKey('story-picture')), findsNothing, reason: "the palace's own scene, as before");
      for (final line in m05.story) {
        expect(findReadable(line), findsOneWidget, reason: line);
      }
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
      expect(step(t), 'MISSION 05 · INVESTIGATE');

      // Closer, then back: the card back in its place.
      await play.tapDecode(t, scene.areas.first.center);
      expect(step(t), 'LOOK CLOSER');
      await back(t);
      expect(step(t), 'MISSION 05 · INVESTIGATE');
      expect(find.byKey(const ValueKey('decode-mark')), findsOneWidget);

      // Half-way through the scan, back: it stops; examined again, it is decoded.
      await play.tapDecode(t, scene.areas.first.center);
      await t.tap(examine());
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('decode-scan-line')), findsOneWidget);
      await back(t);
      await wait(t, const Duration(milliseconds: 1200));
      expect(step(t), 'MISSION 05 · INVESTIGATE', reason: 'not decoded by a scan left half-way');
      expect(find.byKey(const ValueKey('decode-scan-line')), findsNothing);
      await play.tapDecode(t, scene.areas.first.center);
      await play.tapKey(t, 'decode-examine', after: const Duration(milliseconds: 2800));
      expect(step(t), 'THE HIDDEN MESSAGE');

      // Decoded, then back: the place; INVESTIGATE again shows it decoded.
      await back(t);
      expect(find.text('INVESTIGATE'), findsOneWidget);
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
      expect(step(t), 'THE HIDDEN MESSAGE', reason: 'kept while the page is open');
      expect(play.ref.read(gameControllerProvider).isCompleted('m05'), isFalse, reason: 'not taken yet');

      // A restart: back at the card in its place (never saved), on the puzzle.
      await play.restart(t);
      play.ref.read(routerProvider).go(Routes.mission('m05'));
      await wait(t, const Duration(milliseconds: 1200));
      expect(step(t), 'MISSION 05 · INVESTIGATE');
      expect(play.ref.read(gameControllerProvider).isCompleted('m05'), isFalse);
    });

    testWidgets('EXAMINE and TAKE tapped twice act once; rewards paid once and kept after a restart', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm05');
      await play.tapDecode(t, scene.areas.first.center);
      await t.tap(examine());
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(examine(), warnIfMissed: false);
      await wait(t, const Duration(milliseconds: 2800));
      expect(step(t), 'THE HIDDEN MESSAGE');
      await t.tap(take());
      await t.tap(take(), warnIfMissed: false);
      await wait(t, const Duration(milliseconds: 1500));
      expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget, reason: 'one Discovery Moment');
      final p = play.ref.read(gameControllerProvider);
      expect(p.isCompleted('m05'), isTrue);
      expect(p.attempts['m05'], 1, reason: 'checked once');
      final wallet = play.ref.read(walletProvider);
      final xp = XpBreakdown.totalFor(ep01, p);
      await play.restart(t);
      final again = play.ref.read(gameControllerProvider);
      expect(again.isCompleted('m05'), isTrue);
      expect(XpBreakdown.totalFor(ep01, again), xp);
      expect(play.ref.read(walletProvider).balance, wallet.balance, reason: 'paid once, kept');
      expect(play.ref.read(walletProvider).entries, hasLength(wallet.entries.length));
      play.ref.read(routerProvider).go(Routes.mission('m05'));
      await wait(t, const Duration(milliseconds: 1200));
      expect(find.text('SOLVED'), findsOneWidget);
      expect(find.byKey(const ValueKey('decode-picture')), findsNothing);
    });

    testWidgets('screen readers: the card is a button that works; the order is read out', (t) async {
      final semantics = t.ensureSemantics();
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm05');
      expect(find.bySemanticsLabel(scene.thing), findsOneWidget);
      t.semantics.tap(find.semantics.byLabel(scene.thing));
      await wait(t, const Duration(milliseconds: 700));
      expect(step(t), 'LOOK CLOSER');
      await play.tapKey(t, 'decode-examine', after: const Duration(milliseconds: 2800));
      const spoken = 'Hidden message: Clock, then Train, then Swan, then Stone.';
      expect(find.bySemanticsLabel(spoken), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^TAKE THE CARD\\. ${RegExp.escape(spoken)}')), findsOneWidget);
      semantics.dispose();
    });
  });
}
