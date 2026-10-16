import 'package:flutter/foundation.dart';

/// Where a coin entry came from.
///
/// Stored by [name]: never rename or remove one. A future reward (a monthly
/// subscription grant, a rewarded ad) is a new source with its own entry
/// keys, written through the same [Wallet] (see docs/ECONOMY_EXTENSIONS.md).
enum CoinSource {
  /// The coins every new wallet starts with.
  start,

  /// A mission solved.
  mission,

  /// A mission solved before coins existed, paid when the wallet was made.
  backfill,

  /// A Detective Tip unlocked (paid, free, or given as help).
  tip;

  static CoinSource? byName(Object? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

/// One change to the detective's coins. Its [key] says what it was for and
/// can be written only once (`mission:<id>`, `tip:<missionId>:<n>`, `start`),
/// so a reward is never paid twice and a tip is never charged twice.
@immutable
class CoinEntry {
  const CoinEntry({required this.key, required this.amount, required this.source, this.at});

  final String key;

  /// Coins added (positive) or spent (negative). A free tip is 0.
  final int amount;
  final CoinSource source;
  final DateTime? at;

  Map<String, dynamic> toJson() => {
        'key': key,
        'amount': amount,
        'source': source.name,
        if (at != null) 'at': at!.toIso8601String(),
      };

  /// Null for an entry that cannot be read (it is then left out).
  static CoinEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final key = json['key'];
    final amount = json['amount'];
    final source = CoinSource.byName(json['source']);
    if (key is! String || amount is! num || source == null) return null;
    final at = json['at'];
    return CoinEntry(
      key: key,
      amount: amount.toInt(),
      source: source,
      at: at is String ? DateTime.tryParse(at) : null,
    );
  }
}

/// The detective's coins: a record of every change. The balance is always
/// the sum of the record, so the two can never disagree.
///
/// Coins are not XP: XP is what each case's solving earned (and is shown as
/// it was earned); coins are what the detective can spend.
@immutable
class Wallet {
  const Wallet([this.entries = const []]);

  final List<CoinEntry> entries;

  static const empty = Wallet();

  static String missionKey(String missionId) => 'mission:$missionId';
  static String tipKey(String missionId, int tip) => 'tip:$missionId:$tip';
  static const startKey = 'start';

  int get balance => entries.fold(0, (sum, e) => sum + e.amount);

  bool has(String key) => entries.any((e) => e.key == key);

  /// Whether tip [tip] (1 or 2) of [missionId] is the detective's: it is
  /// then read again for free, in this run or any later one.
  bool ownsTip(String missionId, int tip) => has(tipKey(missionId, tip));

  /// [entry] added, unless an entry with its key is already there.
  Wallet adding(CoinEntry entry) => has(entry.key) ? this : Wallet([...entries, entry]);

  Map<String, dynamic> toJson() => {'entries': [for (final e in entries) e.toJson()]};

  /// Tolerant decoding: unreadable entries are dropped, a repeated key keeps
  /// its first entry.
  factory Wallet.fromJson(Map<String, dynamic> json) {
    var wallet = Wallet.empty;
    final raw = json['entries'];
    if (raw is List) {
      for (final e in raw) {
        if (CoinEntry.fromJson(e) case final entry?) wallet = wallet.adding(entry);
      }
    }
    return wallet;
  }
}
