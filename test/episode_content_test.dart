import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';

import 'helpers.dart';

void main() {
  final e = episode01;

  test('repository serves episode 01 first, then the season', () async {
    const repo = MockEpisodeRepository();
    final ids = await repo.availableEpisodeIds();
    expect(ids.first, 'ep01');
    expect(ids, containsAllInOrder(['ep01', 'ep02', 'ep03', 'ep04', 'ep05']));
    expect((await repo.fetchEpisode('ep01')).title, 'The Missing Crown');
    expect(() => repo.fetchEpisode('nope'), throwsArgumentError);
  });

  test('has 5 missions covering all 5 puzzle types, plus a final code', () {
    expect(e.missions, hasLength(5));
    expect(e.missions.map((m) => m.type).toSet(), {
      MissionType.multipleChoice,
      MissionType.wordInput,
      MissionType.numberCode,
      MissionType.imageChoice,
      MissionType.qrScan,
    });
    expect(e.finalMission.type, MissionType.finalCode);
    expect(e.missions.first.location, "KING'S CROSS");
  });

  test('mission ids are unique and nextMissionId forms the play order', () {
    final ids = e.allMissions.map((m) => m.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (var i = 0; i < e.missions.length; i++) {
      final expectedNext = i + 1 < e.missions.length ? e.missions[i + 1].id : e.finalMission.id;
      expect(e.missions[i].nextMissionId, expectedNext, reason: e.missions[i].id);
    }
  });

  test('every mission is solvable, has 1-2 hints, evidence and a story transition', () {
    for (final m in e.allMissions) {
      expect(AnswerChecker.isCorrect(m, m.answer), isTrue, reason: m.id);
      expect(m.hints.length, inInclusiveRange(1, AppConstants.maxHints), reason: m.id);
      expect(m.evidence, isNotNull, reason: m.id);
      if (!m.isFinal) {
        expect(m.clue, isNotNull, reason: m.id);
        expect(m.transition, isNotEmpty, reason: m.id);
      }
      if (m.type == MissionType.multipleChoice || m.type == MissionType.imageChoice) {
        expect(m.options.map((o) => o.id), contains(m.answer), reason: m.id);
      }
      if (m.type == MissionType.imageChoice) {
        expect(m.options.every((o) => o.artwork != null), isTrue, reason: m.id);
      }
      if (m.codeLength != null) expect(m.answer.length, m.codeLength, reason: m.id);
      expect(m.mapX, inInclusiveRange(0, 1));
      expect(m.mapY, inInclusiveRange(0, 1));
    }
  });

  test('final code can only be built by combining evidence and clues', () {
    final order = e.missions.map((m) => m.evidence).whereType<Evidence>().firstWhere((ev) => ev.symbols.isNotEmpty);
    expect(order.symbols, e.finalMission.dialSymbols, reason: 'evidence shows the lock order');

    final numberBySymbol = {for (final c in e.allClues) c.symbol: c.value};
    final code = e.finalMission.dialSymbols.map((s) => numberBySymbol[s]!).join();
    expect(code, e.finalMission.answer);
    // Reading the clues in discovery order gives a different (wrong) code.
    expect(e.missions.take(4).map((m) => m.clue!.value).join(), isNot(e.finalMission.answer));
  });

  test('glossary covers tricky words and ignores case and punctuation', () {
    expect(e.meaningOf('Queen'), '여왕');
    expect(e.meaningOf('museum.'), '박물관');
    expect(e.meaningOf('thief\'s'), '도둑');
    expect(e.meaningOf('the'), isNull);
  });

  test('JSON round-trip is lossless', () {
    final again = Episode.fromJson(e.toJson());
    expect(again.toJson(), e.toJson());
  });
}
