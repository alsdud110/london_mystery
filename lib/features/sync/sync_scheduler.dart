import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/cloud/cloud_bootstrap.dart';
import '../../data/models/profile.dart';
import '../../data/sync/outbox.dart';
import '../../data/sync/cloud/cloud_codec.dart';
import '../../data/sync/cloud/cloud_store.dart';
import '../../data/sync/cloud/sync_restorer.dart';
import '../../data/sync/cloud/sync_retry_policy.dart';
import '../../data/sync/cloud/sync_sender.dart';
import '../account/account_controller.dart';
import '../account/cloud_profile_store.dart';
import 'sync_gate.dart';
import 'sync_session.dart';

/// Why a sync was asked for.
enum SyncTrigger {
  /// A profile session started (app start, a profile switch).
  session,

  /// A user signed in (or their consent was confirmed).
  signIn,

  /// The app came back to the foreground.
  resume,

  /// The game saved a change.
  save,

  /// A back-off ended.
  retry,
}

/// Why a run did not get to send (besides the Sync Gate's [SyncBlock]).
enum SyncHold {
  /// The profile has no valid detective name yet (its cloud profile needs one).
  profileNotReady,

  /// The cloud could not be reached or refused (backed off).
  unreachable,

  /// Something unexpected (logged by kind only; backed off).
  error,
}

/// What the scheduler did last.
@immutable
class SyncActivity {
  const SyncActivity({this.running = false, this.block, this.hold, this.report, this.pulled});

  final bool running;
  final SyncBlock? block;
  final SyncHold? hold;
  final SyncReport? report;

  /// What the run brought down from the server before sending (null: no
  /// pull this run).
  final RestoreApplied? pulled;
}

/// The account's own records on the server, read before anything else.
enum AccountRecords {
  /// Consent confirmed, no deletion started.
  clear,

  /// A deletion has started (`deletions/{uid}`).
  deleting,

  /// The consent record is not `confirmed`.
  consentNotConfirmed,
}

/// Plans and runs the cloud sync of the profile being played (Phase
/// 4.3B-1). Device-wide, like the account: it follows the profile sessions.
///
/// - Asked for after a sign-in, when the app comes back, and after a save
///   (a little later, so a burst of saves makes one run). Never in the
///   background: going to the background cancels what was planned; a run
///   that was cut off is safe (its claimed changes are released at the next
///   start, see `Outbox.recovered`).
/// - One run at a time on the whole device: asked for again while running,
///   it runs once more afterwards (a few times in a row at most).
/// - Each run is bound to the session, account and profile it started for
///   ([SyncRun] plus the session's generation): after a sign-out, another
///   account, a profile switch (even back to the same profile), a consent
///   withdrawal or a deletion, it stops and nothing of it reaches the game.
/// - Before sending: the account's deletion record and consent record are
///   read from the server, and the profile's cloud documents made if they
///   are missing. Failed sends follow the sender's back-off; the next try is
///   planned from it.
/// - What a run merged is shown at once (see [SyncSession.applied]).
/// - Phase 4.4: after a session starts, a sign-in or a resume, the run first
///   brings down what the server holds of the profile (every case, the
///   season, the coins: checked, then merged in one save, see
///   [SyncRestorer]), then sends.
class SyncScheduler extends ChangeNotifier {
  SyncScheduler({
    required this.cloud,
    required this.account,
    required this.createStore,
    this.saveDelay = const Duration(seconds: 2),
    this.shortDelay = const Duration(milliseconds: 300),
    this.consentRecheck = const Duration(minutes: 1),
    this.maxRunsInARow = 4,
    this.policy = SyncRetryPolicy.standard,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    account.addListener(_onAccount);
  }

  final CloudBootstrap cloud;
  final AccountController account;
  /// Makes the store on the first run (Firebase is ready by then).
  final CloudStore Function() createStore;
  final Duration saveDelay;
  final Duration shortDelay;

  /// How often an unconfirmed consent is read again on its own (a resume or
  /// a sign-in always reads it again).
  final Duration consentRecheck;

  /// Runs started one after the other without a new request from outside.
  final int maxRunsInARow;
  final SyncRetryPolicy policy;
  final DateTime Function() _now;

  CloudStore? _store;
  SyncSession? _session;
  int _generation = 0;
  bool _foreground = true;
  bool _disposed = false;
  Timer? _timer;
  DateTime? _due;
  Future<void>? _running;
  bool _again = false;
  int _chain = 0;
  DateTime? _consentReadAt;
  int _holdFailures = 0;
  AppLifecycleListener? _lifecycle;

  /// The next run brings the server's records down first.
  bool _pullWanted = false;

  /// Pulls in a row that found the records changing under them (backed off).
  int _pullChanges = 0;

  /// Accounts whose deletion has started (from the server's record).
  final _deleting = <String>{};

  /// Profiles prepared for this app start (`SyncSender.prepareAtStart`).
  final _prepared = <String>{};

  /// Cloud profiles known to exist (`uid/profileId`).
  final _ensured = <String>{};

  /// Sender runs started (for tests and the logs).
  int runs = 0;

  SyncActivity _activity = const SyncActivity();
  SyncActivity get activity => _activity;

  /// The run under way (tests wait for it), or null.
  Future<void>? get running => _running;

  /// Whether a run is planned.
  bool get planned => _timer != null;

  /// The store of the runs (made on first use; Firebase must be ready).
  CloudStore get store => _store ??= createStore();

  /// Tests: wraps the store the runs use (e.g. to cut the connection in the
  /// app's integration test).
  @visibleForTesting
  void debugWrapStore(CloudStore Function(CloudStore store) wrap) => _store = wrap(_store ?? createStore());

  void _set(SyncActivity a) {
    _activity = a;
    if (!_disposed) notifyListeners();
  }

  /// Follows the app going to the background and coming back.
  void watchLifecycle() => _lifecycle ??= AppLifecycleListener(onStateChange: onLifecycle);

  @visibleForTesting
  void onLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        _consentReadAt = null; // read it again: it may have changed meanwhile
        request(SyncTrigger.resume);
      case AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached:
        _foreground = false;
        _cancelPlan();
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// The profile session being played now (see `ProfileSessionHost`). A run
  /// of the session before is no longer valid from here on.
  void attach(SyncSession? session) {
    _generation++;
    _session = session;
    request(SyncTrigger.session);
  }

  /// A save queued a change (see `syncSaveSignalProvider`).
  void saved() => request(SyncTrigger.save);

  void _onAccount() {
    if (account.value.cloudFeaturesAllowed) request(SyncTrigger.signIn);
  }

  /// Plans a run: soon, or after [saveDelay] for a save (an earlier plan
  /// stays). While a run is under way, one more follows it.
  void request(SyncTrigger why) {
    if (_disposed || !_foreground) return;
    if (why == SyncTrigger.session || why == SyncTrigger.signIn || why == SyncTrigger.resume) _pullWanted = true;
    if (_running != null) {
      _again = true;
      return;
    }
    if (why != SyncTrigger.retry) _chain = 0;
    _plan(_now().add(why == SyncTrigger.save ? saveDelay : shortDelay));
  }

  void _plan(DateTime at) {
    if (_disposed || !_foreground) return;
    final due = _due;
    if (_timer != null && due != null && !at.isBefore(due)) return;
    _timer?.cancel();
    _due = at;
    final wait = at.difference(_now());
    _timer = Timer(wait.isNegative ? Duration.zero : wait, _fire);
  }

  void _cancelPlan() {
    _timer?.cancel();
    _timer = null;
    _due = null;
  }

  void _fire() {
    _timer = null;
    _due = null;
    if (_running != null) {
      _again = true;
      return;
    }
    final run = _running = _guarded();
    run.whenComplete(() {
      if (identical(_running, run)) _running = null;
      if (!_again || _disposed) return;
      _again = false;
      // Saves made by the run itself (a merged result to send back) ask for
      // more: a few in a row, then a pause.
      _chain++;
      _plan(_now().add(_chain < maxRunsInARow ? shortDelay : policy.baseDelay));
    });
  }

  /// Runs [body] between runs, never during one (the restore of a profile
  /// from the account, Phase 4.4): waits for a run under way, and a run asked
  /// for meanwhile follows it.
  Future<T> exclusive<T>(Future<T> Function() body) async {
    for (var r = _running; r != null; r = _running) {
      await r;
    }
    final done = Completer<void>();
    final mine = _running = done.future;
    try {
      return await body();
    } finally {
      if (identical(_running, mine)) _running = null;
      done.complete();
      if (_again && !_disposed) {
        _again = false;
        _plan(_now().add(shortDelay));
      }
    }
  }

  /// Runs now, bringing the server's records down first, and returns once
  /// that run is over (Phase 4.5: a choice between two case files is made on
  /// what the server holds now). A run under way is waited for first. It is
  /// an ordinary run: its gate, its checks and its back-off.
  Future<void> runNow() async {
    if (_disposed) return;
    _pullWanted = true;
    for (var r = _running; r != null; r = _running) {
      await r;
    }
    if (_disposed) return;
    _cancelPlan();
    _fire();
    await _running;
  }

  /// The account's deletion and consent records, from the server. Throws
  /// [CloudStoreException] when they cannot be read.
  static Future<AccountRecords> readAccountRecords(CloudStore store, String uid) async {
    final paths = SyncPaths(uid, '');
    if (await store.get(paths.deletion) != null) return AccountRecords.deleting;
    if ((await store.get(paths.consent))?['status'] != 'confirmed') return AccountRecords.consentNotConfirmed;
    return AccountRecords.clear;
  }

  /// Notes the account's records read by a restore (Phase 4.4) as a run does.
  Future<void> noteAccountRecords(String uid, AccountRecords records) async {
    switch (records) {
      case AccountRecords.deleting:
        _deleting.add(uid);
      case AccountRecords.consentNotConfirmed:
        _deleting.remove(uid);
        _consentReadAt = _now();
        await account.refreshConsent();
      case AccountRecords.clear:
        _deleting.remove(uid);
    }
  }

  Future<void> _guarded() async {
    try {
      await _runOnce();
    } catch (e) {
      debugPrint('Sync: run failed (${e.runtimeType})');
      _hold(SyncHold.error);
    }
  }

  SyncGateResult _gate(SyncSession s) => SyncGate.check(
        cloud: cloud.value,
        account: account.value,
        profile: s.profile,
        deletionInProgress: _deleting.contains(account.value.uid),
      );

  Future<void> _runOnce() async {
    final s = _session;
    if (s == null) return _set(const SyncActivity(block: SyncBlock.guestProfile));
    final generation = _generation;
    var gate = _gate(s);
    if (gate.block == SyncBlock.consentNotConfirmed && account.value.uid != null && _consentDue()) {
      _consentReadAt = _now();
      await account.refreshConsent();
      if (generation != _generation) return;
      gate = _gate(s);
    }
    if (gate.block == SyncBlock.deletionInProgress) {
      // Closed until the server's deletion record is gone.
      final uid = account.value.uid!;
      try {
        final store = _store ??= createStore();
        if (await store.get(SyncPaths(uid, s.profileId).deletion) == null) _deleting.remove(uid);
      } on CloudStoreException catch (e) {
        debugPrint('Sync: deletion record not read (${e.failure.name})');
      }
      if (generation != _generation) return;
      gate = _gate(s);
    }
    if (!gate.open) return _set(SyncActivity(block: gate.block));
    final profile = s.profile;
    final run = SyncRun.start(gate, profile)!;
    bool valid() =>
        !_disposed &&
        generation == _generation &&
        identical(_session, s) &&
        run.stillValid(
          cloud: cloud.value,
          account: account.value,
          activeProfile: s.profile,
          deletionInProgress: _deleting.contains(run.uid),
        );

    _set(const SyncActivity(running: true));
    final store = _store ??= createStore();
    final paths = SyncPaths(run.uid, run.profileId);

    // The account's own records, from the server: a deletion that started,
    // or a consent withdrawn since sign-in, stops it here. Not read (no
    // connection, an error): nothing is read or sent this run; tried again
    // after a back-off.
    try {
      final records = await readAccountRecords(store, run.uid);
      await noteAccountRecords(run.uid, records);
      switch (records) {
        case AccountRecords.deleting:
          return _set(const SyncActivity(block: SyncBlock.deletionInProgress));
        case AccountRecords.consentNotConfirmed:
          return _set(const SyncActivity(block: SyncBlock.consentNotConfirmed));
        case AccountRecords.clear:
          break;
      }
    } on CloudStoreException catch (e) {
      debugPrint('Sync: records not read (${e.failure.name})');
      return _hold(SyncHold.unreachable);
    }
    if (!valid()) return _set(const SyncActivity());

    switch (await _ensureProfile(store, paths, profile, valid)) {
      case SyncHold.profileNotReady:
        return _set(const SyncActivity(hold: SyncHold.profileNotReady));
      case final SyncHold hold:
        return _hold(hold);
      case null:
        break;
    }
    if (!valid()) return _set(const SyncActivity());

    // Stalled changes get their one chance at this start (before the pull
    // records the server's versions).
    if (_prepared.add(s.profileId)) SyncSender.prepareAtStart(s.repo);

    // What the server holds first (another device's play, a reset there).
    RestoreApplied? pulled;
    if (_pullWanted) {
      _pullWanted = false;
      final CloudDownload down;
      try {
        down = await SyncRestorer.download(store, paths, s.codec);
      } on CloudStoreException catch (e) {
        debugPrint('Sync: records not brought down (${e.failure.name})');
        _pullWanted = true;
        return _hold(SyncHold.unreachable);
      }
      if (!valid()) return _set(const SyncActivity());
      switch (down) {
        case DownloadOk(:final state):
          _pullChanges = 0;
          // One synchronous step: applied, then shown, before the game can
          // save over it.
          pulled = SyncRestorer.apply(s.repo, state, episodeIds: s.episodeIds, isStillValid: valid);
          if (pulled.adoptedEpoch != null) {
            s.applied('epoch');
          } else {
            pulled.restored.forEach(s.applied);
          }
        case DownloadInvalid(:final rejected):
          // Not restored (nothing applied); kept as conflicts. The sender
          // meets the same records and holds what they concern.
          s.repo.transaction(() {
            for (final r in rejected) {
              s.repo.keepConflict(r.conflictRecord());
            }
          });
        case DownloadChanged():
          _pullWanted = true; // read again: a run is planned below
      }
    }

    runs++;
    final report = await SyncSender(
      store: store,
      repo: s.repo,
      codec: s.codec,
      paths: paths,
      episodeIds: s.episodeIds,
      isStillValid: valid,
      policy: policy,
      onApplied: (subject) {
        if (valid()) s.applied(subject);
      },
      now: _now,
    ).run();
    switch (report.stop) {
      case SyncStop.deletionInProgress:
        _deleting.add(run.uid);
      case SyncStop.consentNotConfirmed:
        _consentReadAt = _now();
        await account.refreshConsent();
      default:
        break;
    }
    _holdFailures = 0;
    if (valid()) {
      s.reconcile();
      _planRetry(s);
      // The records changed while they were read (e.g. a New Adventure
      // elsewhere): read again soon, backed off if it keeps happening.
      if (_pullWanted) _plan(_now().add(policy.delayAfter(++_pullChanges)));
    }
    _set(SyncActivity(report: report, pulled: pulled));
  }

  bool _consentDue() {
    final at = _consentReadAt;
    return at == null || !_now().isBefore(at.add(consentRecheck));
  }

  /// The account and profile documents the sync documents live under (the
  /// rules need the profile's). Made once if missing; null when they exist.
  Future<SyncHold?> _ensureProfile(CloudStore store, SyncPaths paths, DetectiveProfile profile, bool Function() valid) async {
    final key = '${paths.uid}/${paths.profileId}';
    if (_ensured.contains(key)) return null;
    final name = profile.detectiveName;
    if (name == null || !CloudPaths.validName(name) || !CloudPaths.validProfileId(paths.profileId)) {
      return SyncHold.profileNotReady;
    }
    try {
      await store.runTransaction((tx) async {
        final user = await tx.get(paths.user);
        final existing = await tx.get(paths.profile);
        if (user == null) {
          tx.set(paths.user, {
            'schema': CloudPaths.schema,
            'createdAt': CloudServerTime.instance,
            'locale': 'ko',
            'region': 'KR',
          });
        }
        if (existing == null) {
          tx.set(paths.profile, {
            'schema': CloudPaths.schema,
            'detectiveName': name,
            'createdAt': CloudServerTime.instance,
          });
        }
        return null;
      });
    } on CloudStoreException catch (e) {
      debugPrint('Sync: cloud profile not made (${e.failure.name})');
      return SyncHold.unreachable;
    }
    _ensured.add(key);
    return null;
  }

  /// Nothing was sent (unreachable, an error): tried again after a back-off.
  void _hold(SyncHold hold) {
    _holdFailures++;
    _set(SyncActivity(hold: hold));
    _plan(_now().add(policy.delayAfter(_holdFailures)));
  }

  /// The next try of what is waiting and backed off (none for conflicts or
  /// stalled changes: they wait for a start or a decision).
  void _planRetry(SyncSession s) {
    final now = _now();
    final meta = s.repo.cloudSync;
    DateTime? next;
    for (final e in s.repo.outbox.pending) {
      if (e.playtest || e.profileId != s.profileId) continue;
      final subject = switch (e.kind) {
        OutboxKind.caseRun => 'case:${e.subject}',
        OutboxKind.season => 'season',
        OutboxKind.walletEntry => 'wallet',
      };
      final sub = meta.of(subject);
      if (sub.stalled) continue;
      final at = sub.nextAttemptAt ?? now;
      if (next == null || at.isBefore(next)) next = at;
    }
    final metaNext = meta.of('meta').nextAttemptAt;
    if (next != null && metaNext != null && metaNext.isAfter(next)) next = metaNext;
    if (next == null) return;
    // Due already (nothing was tried, e.g. a stop): a fresh request decides.
    if (!next.isAfter(now)) return;
    _chain = 0;
    _plan(next);
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelPlan();
    _lifecycle?.dispose();
    account.removeListener(_onAccount);
    super.dispose();
  }
}
