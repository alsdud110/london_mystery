import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/theme/app_text.dart';
import 'package:world_mystery/data/mock/season2/episode01_mock.dart';
import 'package:world_mystery/data/models/discovery.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/features/game/scoring.dart';
import 'package:world_mystery/features/mission/widgets/answer_feedback.dart';

/// The Discovery Moment's title: a name (Season 1's "THE ROSETTA STONE")
/// keeps the display face; a sentence (Paris's success lines) is set in the
/// reading face, never as a line of small capitals.
void main() {
  final m1 = Episode.fromJson(season2Episode01Json).missions.first;

  Future<void> open(WidgetTester t, Mission m, String title) async {
    await t.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showDiscoveryMoment(
                    context,
                    mission: m,
                    discovery: Discovery(type: DiscoveryType.deduction, timing: DiscoveryTiming.fromPuzzle, title: title, detail: ''),
                    xp: const XpBreakdown(base: 50),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  String? faceOf(WidgetTester t, String title) {
    final text = t.widget<Text>(find.text(title));
    return text.style?.fontFamily ?? (text.textSpan as TextSpan?)?.style?.fontFamily;
  }

  testWidgets('a Paris success line is read in the reading face', (t) async {
    await open(t, m1, m1.successMessage);
    expect(m1.successMessage, 'The old clock is one hour behind!');
    expect(faceOf(t, m1.successMessage), AppText.body);
  });

  testWidgets('a name keeps the display face', (t) async {
    await open(t, m1, 'THE ROSETTA STONE');
    expect(faceOf(t, 'THE ROSETTA STONE'), AppText.display);
  });
}
