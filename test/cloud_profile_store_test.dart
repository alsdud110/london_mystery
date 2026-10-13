import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/models/detective_name.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/features/account/cloud_profile_store.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/account/consent.dart';
import 'package:london_mystery/features/account/fake_cloud_profile_store.dart';
import 'package:london_mystery/features/account/firestore_consent_repository.dart';

/// Consent as a trusted record would say it, per account.
class _Consents implements ConsentRepository {
  _Consents(this.confirmed);

  final Set<String> confirmed;

  @override
  Future<ConsentStatus> statusOf(String uid) async =>
      confirmed.contains(uid) ? ConsentStatus.confirmed : ConsentStatus.unconfirmed;
}

/// Phase 3A-3: the account's cloud documents (users/{uid}, its profiles) and
/// the read-only consent record. The Firestore rules themselves are tested on
/// the emulator (firebase/test/firestore.rules.test.mjs).
void main() {
  const alice = 'alice-uid';
  const bob = 'bob-uid';
  const p1 = '0123456789abcdef0123456789abcdef';
  const p2 = 'fedcba9876543210fedcba9876543210';

  group('FirestoreConsentRepository: only a record saying "confirmed" confirms', () {
    test('the record decides', () {
      expect(FirestoreConsentRepository.statusFrom({'status': 'confirmed'}), ConsentStatus.confirmed);
      for (final record in <Map<String, Object?>?>[
        null,
        {},
        {'status': 'unconfirmed'},
        {'status': 'Confirmed'},
        {'status': true},
        {'consent': 'confirmed'},
      ]) {
        expect(FirestoreConsentRepository.statusFrom(record), ConsentStatus.unconfirmed, reason: '$record');
      }
    });

    test('reads consents/{uid} of the account asked for', () async {
      final asked = <String>[];
      final repo = FirestoreConsentRepository.withReader((uid) async {
        asked.add(uid);
        return uid == alice ? {'status': 'confirmed'} : null;
      });
      expect(await repo.statusOf(alice), ConsentStatus.confirmed);
      expect(await repo.statusOf(bob), ConsentStatus.unconfirmed);
      expect(asked, [alice, bob]);
    });

    test('a refused or failed read is unconfirmed (fails closed)', () async {
      for (final error in [
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        StateError('no app'),
      ]) {
        final repo = FirestoreConsentRepository.withReader((_) async => throw error);
        expect(await repo.statusOf(alice), ConsentStatus.unconfirmed, reason: '$error');
      }
    });

    test('no uid, no read', () async {
      var reads = 0;
      final repo = FirestoreConsentRepository.withReader((_) async {
        reads++;
        return {'status': 'confirmed'};
      });
      expect(await repo.statusOf(''), ConsentStatus.unconfirmed);
      expect(reads, 0);
    });
  });

  group('CloudProfileStore (fake, answering as the rules do)', () {
    late Set<String> confirmed;
    late String? signedIn;
    late FakeCloudProfileStore store;

    setUp(() {
      confirmed = {};
      signedIn = alice;
      store = FakeCloudProfileStore(consents: _Consents(confirmed), signedInUid: () => signedIn);
    });

    test('without confirmed consent: nothing is written, the users document included', () async {
      expect(await store.ensureAccount(alice), CloudWriteResult.consentRequired);
      expect(await store.createProfile(alice, profileId: p1, detectiveName: 'MINYOUNG'), CloudWriteResult.consentRequired);
      expect(store.writes, 0);
      expect(store.accounts, isEmpty);
    });

    test('with confirmed consent: the account, then its profiles', () async {
      confirmed.add(alice);
      expect(await store.createProfile(alice, profileId: p1, detectiveName: 'MINYOUNG'), CloudWriteResult.noAccountDocument);
      expect(await store.ensureAccount(alice), CloudWriteResult.done);
      expect(await store.ensureAccount(alice), CloudWriteResult.done, reason: 'already there: nothing more');
      expect(await store.createProfile(alice, profileId: p1, detectiveName: 'MINYOUNG'), CloudWriteResult.done);
      expect(await store.renameProfile(alice, profileId: p1, detectiveName: 'MIN'), CloudWriteResult.done);
      final profiles = await store.profilesOf(alice);
      expect(profiles.single.detectiveName, 'MIN');
      expect(profiles.single.createdAt, isNotNull);
      expect(store.writes, 3);
    });

    test('consent withdrawn: writes stop, reading stays', () async {
      confirmed.add(alice);
      await store.ensureAccount(alice);
      await store.createProfile(alice, profileId: p1, detectiveName: 'MINYOUNG');
      confirmed.remove(alice);
      expect(await store.renameProfile(alice, profileId: p1, detectiveName: 'MIN'), CloudWriteResult.consentRequired);
      expect(await store.createProfile(alice, profileId: p2, detectiveName: 'TWO'), CloudWriteResult.consentRequired);
      expect((await store.profilesOf(alice)).single.detectiveName, 'MINYOUNG');
    });

    test("each account reaches only its own: bob, even with consent, cannot touch alice's", () async {
      confirmed.addAll({alice, bob});
      await store.ensureAccount(alice);
      await store.createProfile(alice, profileId: p1, detectiveName: 'MINYOUNG');
      signedIn = bob;
      expect(await store.profilesOf(alice), isEmpty);
      expect(await store.ensureAccount(alice), CloudWriteResult.denied);
      expect(await store.createProfile(alice, profileId: p2, detectiveName: 'BOB'), CloudWriteResult.denied);
      expect(await store.renameProfile(alice, profileId: p1, detectiveName: 'BOB'), CloudWriteResult.denied);
      signedIn = null;
      expect(await store.ensureAccount(alice), CloudWriteResult.denied, reason: 'signed out');
      signedIn = alice;
      expect((await store.profilesOf(alice)).single.detectiveName, 'MINYOUNG');
    });

    test('invalid ids, names, locales are not sent', () async {
      confirmed.add(alice);
      await store.ensureAccount(alice);
      for (final id in ['abc', '0123abc', 'f' * 65, p1.toUpperCase()]) {
        expect(await store.createProfile(alice, profileId: id, detectiveName: 'A'), CloudWriteResult.invalid, reason: id);
      }
      expect(await store.createProfile(alice, profileId: p1, detectiveName: ''), CloudWriteResult.invalid);
      expect(await store.createProfile(alice, profileId: p1, detectiveName: 'ABCDEFGHIJKLM'), CloudWriteResult.invalid);
      expect(await store.ensureAccount(bob, locale: 'korean'), CloudWriteResult.invalid);
      expect(await store.ensureAccount(bob, region: 'kr'), CloudWriteResult.invalid);
      expect(store.writes, 1);
    });

    test('offline: nothing written, the next try works', () async {
      confirmed.add(alice);
      store.failNext = CloudWriteResult.unavailable;
      expect(await store.ensureAccount(alice), CloudWriteResult.unavailable);
      expect(store.accounts, isEmpty);
      expect(await store.ensureAccount(alice), CloudWriteResult.done);
    });

    test('the interface cannot write consent or delete anything', () {
      // A compile-time fact, kept visible: no such methods exist.
      final names = ['ensureAccount', 'createProfile', 'renameProfile', 'profilesOf'];
      final source = File('lib/features/account/cloud_profile_store.dart').readAsStringSync();
      final declared = RegExp(r'Future<[^>]+>+ (\w+)\(').allMatches(source).map((m) => m.group(1)).toList();
      expect(declared, names);
    });
  });

  group('one id rule and one name rule, on the device and in the rules', () {
    test('profile ids: the local rule, 8 to 64 lowercase hex', () {
      for (final id in ['0123abcd', 'f' * 64, p1, '${p1}0']) {
        expect(CloudPaths.validProfileId(id), isTrue, reason: id);
        expect(DetectiveProfile.isValidId(id), isTrue, reason: id);
      }
      for (final id in ['abc', '0123abc', 'f' * 65, p1.toUpperCase(), 'g${p1.substring(1)}', '$p1-x']) {
        expect(CloudPaths.validProfileId(id), isFalse, reason: id);
      }
    });

    test('names: the same lists as the rules test', () {
      const ok = ['ABCDEFGHIJKL', 'Min Young', 'minyoung', '김민영', 'DR. WATSON', 'MARY-JANE', 'A', 'AGENT 007'];
      final bad = ['', ' ', 'ABCDEFGHIJKLM', '가' * 13, ' MIN', 'MIN ', 'MIN  YOUNG', 'MIN\tYOUNG', 'MIN!', 'MIN_YOUNG',
          '😀', 'ㅁㅣㄴ', 'Ａ'];
      for (final n in [...ok, '가' * 12]) {
        expect(DetectiveName.isValid(n), isTrue, reason: n);
      }
      for (final n in bad) {
        expect(DetectiveName.isValid(n), isFalse, reason: n);
      }
    });

    test('normalize trims and joins spaces; a saved name is never rewritten by it', () {
      expect(DetectiveName.normalize('  Min   Young '), 'Min Young');
      expect(DetectiveName.isValid(DetectiveName.normalize('  Min   Young ')), isTrue);
      expect(GameController.cleanName('  min  young '), 'MIN YOUNG');
    });

    test('the rules file carries the very same patterns', () {
      final rules = File('firebase/firestore.rules').readAsStringSync();
      expect(rules, contains("n.matches('${DetectiveName.pattern}')"));
      expect(rules, contains("id.matches('${DetectiveProfile.idPattern}')"));
      expect(rules, contains('n.size() <= ${DetectiveName.maxLength}'));
    });
  });

  test('the app and the rules use the same paths', () {
    final rules = File('firebase/firestore.rules').readAsStringSync();
    expect(rules, contains('match /${CloudPaths.users}/{uid}'));
    expect(rules, contains('match /${CloudPaths.profiles}/{profileId}'));
    expect(rules, contains('match /${CloudPaths.consents}/{uid}'));
    expect(rules, isNot(contains('match /parents')), reason: 'the old path is gone');
    expect(CloudPaths.user(alice), 'users/$alice');
    expect(CloudPaths.profile(alice, p1), 'users/$alice/profiles/$p1');
    expect(CloudPaths.consent(alice), 'consents/$alice');
  });
}
