import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/outbox.dart';
import 'package:london_mystery/data/sync/save_journal.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

const pid = 'cccccccccccccccccccccccccccccccc';

Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

OutboxEvent event(String id, OutboxKind kind, String subject, {OutboxState state = OutboxState.pending, int rev = 0}) =>
    OutboxEvent(
      id: id,
      profileId: pid,
      kind: kind,
      subject: subject,
      epoch: 0,
      rev: rev,
      state: state,
      createdAt: DateTime(2026, 10, 13),
    );

void main() {
  group('save journal: several keys saved all or none', () {
    final a = AppConstants.profileKey(pid, AppConstants.progressStorageKey);
    final b = AppConstants.profileKey(pid, AppConstants.walletStorageKey);
    final c = AppConstants.outboxKey(pid);

    test('a commit writes every key and leaves no journal', () async {
      final prefs = await prefsWith({});
      SaveJournal(prefs, pid).commit({a: 'A', b: 'B', c: null});
      expect(prefs.getString(a), 'A');
      expect(prefs.getString(b), 'B');
      expect(prefs.getString(AppConstants.journalKey(pid)), isNull);
    });

    test('stopped after the journal and the first key: the next start finishes it', () async {
      final prefs = await prefsWith({
        AppConstants.journalKey(pid): jsonEncode({
          'v': 1,
          'writes': {a: 'A2', b: 'B2', c: null},
        }),
        a: 'A2', // written
        b: 'B1', // not yet
        c: 'stale', // not yet removed
      });
      expect(SaveJournal(prefs, pid).recover(), isTrue);
      expect(prefs.getString(a), 'A2');
      expect(prefs.getString(b), 'B2');
      expect(prefs.containsKey(c), isFalse);
      expect(prefs.containsKey(AppConstants.journalKey(pid)), isFalse);
      expect(SaveJournal(prefs, pid).recover(), isFalse, reason: 'nothing left to finish');
    });

    test('an unreadable journal is dropped; nothing of it was written', () async {
      final prefs = await prefsWith({AppConstants.journalKey(pid): '{half', a: 'A1'});
      expect(SaveJournal(prefs, pid).recover(), isTrue);
      expect(prefs.getString(a), 'A1');
      expect(prefs.containsKey(AppConstants.journalKey(pid)), isFalse);
    });

    test('a journal cannot touch keys of another profile or of the device', () async {
      final prefs = await prefsWith({
        AppConstants.journalKey(pid): jsonEncode({
          'writes': {AppConstants.progressStorageKey: null, AppConstants.profilesStorageKey: 'x', a: 'A'},
        }),
        AppConstants.progressStorageKey: 'original',
      });
      SaveJournal(prefs, pid).recover();
      expect(prefs.getString(AppConstants.progressStorageKey), 'original');
      expect(prefs.getString(AppConstants.profilesStorageKey), isNull);
      expect(prefs.getString(a), 'A');
    });

    test('the repository finishes an unfinished save when it opens', () async {
      final solved = jsonEncode(const GameProgress(detectiveName: 'KIM', completedMissionIds: ['m01']).toJson());
      final paid = jsonEncode(const Wallet([
        CoinEntry(key: 'start', amount: 20, source: CoinSource.start),
        CoinEntry(key: 'mission:m01', amount: 30, source: CoinSource.mission),
      ]).toJson());
      final prefs = await prefsWith({
        AppConstants.journalKey(pid): jsonEncode({
          'writes': {a: solved, b: paid},
        }),
        b: paid, // the coins landed, the solve did not
      });
      final repo = SharedPrefsProgressRepository(prefs, profileId: pid);
      expect(repo.load().isCompleted('m01'), isTrue, reason: 'paid and solved, never one without the other');
      expect(repo.loadWallet()!.balance, 50);
    });
  });

  group('outbox', () {
    test('a newer change of the same case replaces the one still waiting; coin entries queue once', () {
      var box = Outbox.empty
          .enqueue(event('1', OutboxKind.caseRun, 'ep01', rev: 1))
          .enqueue(event('2', OutboxKind.walletEntry, 'mission:m01'))
          .enqueue(event('3', OutboxKind.caseRun, 'ep01', rev: 2))
          .enqueue(event('4', OutboxKind.walletEntry, 'mission:m01'))
          .enqueue(event('5', OutboxKind.caseRun, 'ep02', rev: 1));
      expect(box.events.map((e) => e.id), ['2', '3', '5']);
      box = box.enqueue(event('6', OutboxKind.season, 'season')).enqueue(event('7', OutboxKind.season, 'season'));
      expect(box.events.map((e) => e.id), ['2', '3', '5', '7']);
    });

    test('nothing leaves without an acknowledgement; acks are idempotent', () {
      var box = Outbox.empty
          .enqueue(event('1', OutboxKind.caseRun, 'ep01'))
          .enqueue(event('2', OutboxKind.walletEntry, 'start'));
      box = box.claim(['1', '2']);
      expect(box.pending, isEmpty);
      expect(box.events.every((e) => e.state == OutboxState.inFlight && e.attempts == 1), isTrue);
      // A newer change while '1' is on its way waits next to it.
      box = box.enqueue(event('3', OutboxKind.caseRun, 'ep01', rev: 1));
      expect(box.events.map((e) => e.id), ['1', '2', '3']);
      box = box.ack(['1']);
      expect(box.events.map((e) => e.id), ['2', '3']);
      expect(box.ack(['1']).events.map((e) => e.id), ['2', '3'], reason: 'a repeated ack changes nothing');
      expect(box.ack(['unknown']).events, hasLength(2));
      box = box.release(['2']);
      expect(box.pending.map((e) => e.id), ['2', '3']);
    });

    test('handed to a sender before the app stopped: waiting again at the next start', () async {
      final box = Outbox.empty.enqueue(event('1', OutboxKind.walletEntry, 'start')).claim(['1']);
      final prefs = await prefsWith({AppConstants.outboxKey(pid): box.encode()});
      final repo = SharedPrefsProgressRepository(prefs, profileId: pid);
      expect(repo.outbox.pending.map((e) => e.id), ['1']);
      expect(repo.outbox.events.single.attempts, 1, reason: 'the attempt is remembered');
    });

    test('an unreadable outbox or event is dropped, not a crash', () {
      expect(Outbox.decode('{bad').isEmpty, isTrue);
      final box = Outbox.decode(jsonEncode({
        'events': [
          {'id': 'x'},
          event('1', OutboxKind.season, 'season').toJson(),
          event('1', OutboxKind.season, 'season').toJson(),
        ],
      }));
      expect(box.events.map((e) => e.id), ['1']);
    });
  });

  group('the game queues its changes with the saves', () {
    test('a solve queues the case run and its coins, in the same save as the solve', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      final repo = c.read(progressRepositoryProvider) as SharedPrefsProgressRepository;
      final game = c.read(gameControllerProvider.notifier);
      game.registerDetective('ANNA');
      game.startInvestigation();
      final m01 = episode01.missions.first;
      expect(game.submitAnswer(m01, 'b').coins, 30);

      final box = repo.outbox;
      final cases = box.events.where((e) => e.kind == OutboxKind.caseRun).toList();
      expect(cases, hasLength(1), reason: 'one waiting state per case');
      final run = c.read(gameControllerProvider);
      expect((cases.single.runId, cases.single.runSeq, cases.single.rev), (run.runId, run.runSeq, run.rev));
      expect(
        box.events.where((e) => e.kind == OutboxKind.walletEntry).map((e) => e.subject),
        ['start', 'mission:m01'],
      );
      expect(box.events.firstWhere((e) => e.subject == 'mission:m01').payload!['amount'], 30);
      expect(c.read(sharedPreferencesProvider).containsKey(AppConstants.journalKey(repo.profileId)), isFalse);
    });

    test('a save that changes nothing writes nothing and queues nothing', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      final prefs = c.read(sharedPreferencesProvider);
      final game = c.read(gameControllerProvider.notifier);
      game.registerDetective('ANNA');
      c.read(seasonProvider.notifier).open('ep01'); // the season's first save
      final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      game.pausePlayClock();
      game.resumePlayClock();
      c.read(seasonProvider.notifier).open('ep01');
      game.registerDetective('ANNA');
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
    });

    test('revealing a paid tip: the coins and the open tip are saved together', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      final game = c.read(gameControllerProvider.notifier);
      game.registerDetective('ANNA');
      game.startInvestigation();
      final m01 = episode01.missions.first;
      expect(game.revealTip(m01, 1), TipUnlock.free);
      expect(game.revealTip(m01, 2), TipUnlock.paid);
      final repo = c.read(progressRepositoryProvider);
      expect(repo.load().hintsFor('m01'), 2);
      expect(repo.loadWallet()!.balance, 0);
      expect(game.revealTip(m01, 2), TipUnlock.alreadyYours, reason: 'never charged twice');
      expect(repo.loadWallet()!.balance, 0);
    });

    test('a reset moves the profile to the next epoch; later changes carry it', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      final repo = c.read(progressRepositoryProvider) as SharedPrefsProgressRepository;
      c.read(gameControllerProvider.notifier).registerDetective('ANNA');
      expect(repo.epoch, 0);
      await c.read(gameControllerProvider.notifier).resetAll();
      expect(repo.epoch, 1);
      expect(repo.outbox.events.map((e) => (e.subject, e.epoch)), [('start', 1)]);
      await c.read(gameControllerProvider.notifier).resetAll();
      expect(repo.epoch, 2);
    });
  });
}
