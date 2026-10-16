import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/sync/cloud/cloud_store.dart';
import 'package:london_mystery/features/sync/sync_scheduler.dart';

import 'cloud_stores.dart';

// Shared by the scheduler and restore tests (Phase 4.3B-1, 4.4).

/// Waits until no run is under way or planned (or only planned, with
/// [keepPlanned]: a back-off).
Future<void> settle(SyncScheduler s, {bool keepPlanned = false, Duration timeout = const Duration(seconds: 10)}) async {
  final end = DateTime.now().add(timeout);
  // Let a request made just now be planned first.
  await Future<void>.delayed(const Duration(milliseconds: 60));
  while (s.running != null || (!keepPlanned && s.planned)) {
    if (DateTime.now().isAfter(end)) fail('the sync did not settle');
    await (s.running ?? Future<void>.delayed(const Duration(milliseconds: 20)));
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// Counts the calls to a store and how many run at once.
class WatchStore implements CloudStore {
  WatchStore(this.inner);

  final CloudStore inner;
  int calls = 0;
  int active = 0;
  int maxActive = 0;
  Duration delay = Duration.zero;
  final writes = <String>[];

  /// Told of each write a transaction body makes (inside the body).
  void Function(String path)? onSet;

  /// Reads outside a transaction fail as with no connection (transactions
  /// still go through).
  bool failGets = false;

  int transactions = 0;

  Future<T> _track<T>(Future<T> Function() call) async {
    calls++;
    active++;
    if (active > maxActive) maxActive = active;
    try {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      return await call();
    } finally {
      active--;
    }
  }

  @override
  Future<Map<String, Object?>?> get(String path) => _track(() {
        if (failGets) throw const CloudStoreException(CloudFailure.unavailable, 'injected');
        return inner.get(path);
      });

  @override
  Future<Map<String, Map<String, Object?>>> list(String path) => _track(() {
        if (failGets) throw const CloudStoreException(CloudFailure.unavailable, 'injected');
        return inner.list(path);
      });

  @override
  Future<T> runTransaction<T>(Future<T> Function(CloudTx tx) body) {
    transactions++;
    return _track(
        () => inner.runTransaction((tx) => body(WatchTx(tx, this))),
      );
  }
}

class WatchTx implements CloudTx {
  WatchTx(this.inner, this.watch);

  final CloudTx inner;
  final WatchStore watch;

  @override
  Future<Map<String, Object?>?> get(String path) => inner.get(path);

  @override
  void set(String path, Map<String, Object?> data) {
    watch.writes.add(path);
    watch.onSet?.call(path);
    inner.set(path, data);
  }
}

/// The emulator store as whoever is signed in now (like the app's plugin).
class AsUserStore implements CloudStore {
  AsUserStore(this.uid);

  final String? Function() uid;

  CloudStore get _store {
    final u = uid();
    if (u == null) throw const CloudStoreException(CloudFailure.permissionDenied, 'signed out');
    return EmulatorCloudStore(u);
  }

  @override
  Future<Map<String, Object?>?> get(String path) => _store.get(path);

  @override
  Future<Map<String, Map<String, Object?>>> list(String path) => _store.list(path);

  @override
  Future<T> runTransaction<T>(Future<T> Function(CloudTx tx) body) => _store.runTransaction(body);
}
