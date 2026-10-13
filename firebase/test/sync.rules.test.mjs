// Phase 4.1 sync rules (firebase/firestore.rules), on the emulator:
// sync/meta, cases/*, season/state, wallet/* under users/{uid}/profiles/{pid}.
// Run: cd firebase && npm test   (demo project; nothing deployed)
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'mocha';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  setLogLevel,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const PID = '0123456789abcdef0123456789abcdef';
const base = (uid = 'alice') => `users/${uid}/profiles/${PID}`;
let env;

const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const seed = (write) => env.withSecurityRulesDisabled(async (ctx) => write(ctx.firestore()));

/** An account with a confirmed consent, its users doc and one profile. */
async function ready(uid = 'alice') {
  await seed(async (f) => {
    await setDoc(doc(f, `consents/${uid}`), { status: 'confirmed', schema: 1 });
    await setDoc(doc(f, `users/${uid}`), { schema: 1, locale: 'ko', region: 'KR', createdAt: Timestamp.now() });
    await setDoc(doc(f, base(uid)), { schema: 1, detectiveName: 'ANNA', createdAt: Timestamp.now() });
  });
}

const meta = (epoch, v) => ({ epoch, cloudVersion: v, updatedAt: serverTimestamp() });
const kase = (epoch, v, extra = {}) => ({
  epoch,
  runId: 'run-1',
  runSeq: 0,
  cloudVersion: v,
  progress: { completedMissionIds: ['m01'], detectiveName: 'ANNA' },
  updatedAt: serverTimestamp(),
  ...extra,
});
const ep02 = { progress: { completedMissionIds: ['ep02_m1'] } };
const season = (epoch, v, extra = {}) => ({ epoch, cloudVersion: v, solvedEpisodeIds: ['ep01'], updatedAt: serverTimestamp(), ...extra });
const event = (epoch, key, amount, source) => ({ epoch, key, amount, source, at: Timestamp.now() });
const summary = (epoch, v, balance, lastEventId) => ({ epoch, cloudVersion: v, balance, lastEventId, updatedAt: serverTimestamp() });

/** One coin event and its summary, in one batch (as the sender writes them). */
function coin(f, { epoch, key, amount, source, v, balance, uid = 'alice' }) {
  const b = writeBatch(f);
  const id = `${epoch}_${key}`;
  b.set(doc(f, `${base(uid)}/wallet/${id}`), event(epoch, key, amount, source));
  b.set(doc(f, `${base(uid)}/wallet/summary`), summary(epoch, v, balance, id));
  return b.commit();
}

/** alice at epoch 1: meta, a case, the season, and 20 start coins. */
async function synced() {
  await ready();
  const f = db('alice');
  await assertSucceeds(setDoc(doc(f, `${base()}/sync/meta`), meta(0, 1)));
  await assertSucceeds(setDoc(doc(f, `${base()}/cases/ep01`), kase(0, 1)));
  await assertSucceeds(setDoc(doc(f, `${base()}/season/state`), season(0, 1)));
  await assertSucceeds(coin(f, { epoch: 0, key: 'start', amount: 20, source: 'start', v: 1, balance: 20 }));
  return f;
}

before(async () => {
  setLogLevel('silent');
  env = await initializeTestEnvironment({
    projectId: 'demo-london-mystery',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => env.clearFirestore());
after(async () => env.cleanup());

describe('sync/meta: the reset generation', () => {
  it('created at version 1; a reset raises the epoch by a version of exactly +1', async () => {
    await ready();
    const f = db('alice');
    const m = doc(f, `${base()}/sync/meta`);
    await assertFails(setDoc(m, meta(0, 2)), 'first version must be 1');
    await assertFails(setDoc(m, meta(5, 1)), 'the cloud starts at epoch 0');
    await assertSucceeds(setDoc(m, meta(0, 1)));
    await assertSucceeds(setDoc(m, meta(1, 2)));
    await assertFails(setDoc(m, meta(2, 4)), 'version skipped');
    await assertFails(setDoc(m, meta(2, 2)), 'version not raised');
    await assertFails(setDoc(m, meta(1, 3)), 'epoch not raised');
    await assertFails(setDoc(m, meta(0, 3)), 'epoch lowered');
    await assertFails(setDoc(m, meta(3, 3)), 'epoch jumps by more than one');
    await assertSucceeds(setDoc(m, meta(2, 3)), 'one more reset');
    await assertSucceeds(getDoc(m));
    await assertFails(deleteDoc(m));
  });

  it('a device that reset several times offline steps up one at a time', async () => {
    await ready();
    const m = doc(db('alice'), `${base()}/sync/meta`);
    await assertSucceeds(setDoc(m, meta(0, 1)));
    for (let e = 1; e <= 3; e++) await assertSucceeds(setDoc(m, meta(e, e + 1)));
    await assertFails(setDoc(m, meta(999999, 5)));
  });

  it('exact fields and types only; only the "meta" document', async () => {
    await ready();
    const f = db('alice');
    await assertFails(setDoc(doc(f, `${base()}/sync/meta`), { ...meta(0, 1), extra: true }));
    await assertFails(setDoc(doc(f, `${base()}/sync/meta`), { ...meta(0, 1), epoch: '1' }));
    await assertFails(setDoc(doc(f, `${base()}/sync/meta`), { ...meta(0, 1), epoch: -1 }));
    await assertFails(setDoc(doc(f, `${base()}/sync/meta`), { ...meta(0, 1), updatedAt: Timestamp.fromDate(new Date(2020, 0, 1)) }));
    await assertFails(setDoc(doc(f, `${base()}/sync/other`), meta(0, 1)));
  });
});

describe('cases: cloudVersion and epoch', () => {
  it('needs the server epoch first, then version 1 at that epoch', async () => {
    await ready();
    const f = db('alice');
    await assertFails(setDoc(doc(f, `${base()}/cases/ep01`), kase(0, 1)), 'no sync/meta yet');
    await assertSucceeds(setDoc(doc(f, `${base()}/sync/meta`), meta(0, 1)));
    await assertFails(setDoc(doc(f, `${base()}/cases/ep01`), kase(1, 1)), 'epoch != server');
    await assertFails(setDoc(doc(f, `${base()}/cases/ep01`), kase(0, 2)), 'first version must be 1');
    await assertSucceeds(setDoc(doc(f, `${base()}/cases/ep01`), kase(0, 1)));
  });

  it('each write is exactly +1: skipping, repeating or lowering the version is refused', async () => {
    const f = await synced();
    const c = doc(f, `${base()}/cases/ep01`);
    await assertSucceeds(setDoc(c, kase(0, 2)));
    await assertFails(setDoc(c, kase(0, 4)), 'skipped');
    await assertFails(setDoc(c, kase(0, 2)), 'same version again (a stale writer)');
    await assertFails(setDoc(c, kase(0, 1)), 'lowered');
    await assertSucceeds(setDoc(c, kase(0, 3)));
  });

  it('a reset and the first write of the new epoch can go in one batch; the old epoch is then refused', async () => {
    const f = await synced();
    const b = writeBatch(f);
    b.set(doc(f, `${base()}/sync/meta`), meta(1, 2));
    b.set(doc(f, `${base()}/cases/ep01`), kase(1, 2, { runSeq: 0 }));
    await assertSucceeds(b.commit());
    // A device that never saw the reset uploads its old-epoch progress: refused.
    await assertFails(setDoc(doc(f, `${base()}/cases/ep01`), kase(0, 3)), 'old epoch after reset');
    await assertFails(setDoc(doc(f, `${base()}/cases/ep02`), kase(0, 1, ep02)), 'old epoch, new case');
    await assertSucceeds(setDoc(doc(f, `${base()}/cases/ep02`), kase(1, 1, ep02)));
  });

  it('the same epoch never goes back to an earlier run (Play again stays)', async () => {
    const f = await synced();
    const c = doc(f, `${base()}/cases/ep01`);
    await assertSucceeds(setDoc(c, kase(0, 2, { runSeq: 2, runId: 'run-3' })));
    await assertFails(setDoc(c, kase(0, 3, { runSeq: 1, runId: 'run-2' })));
    await assertSucceeds(setDoc(c, kase(0, 3, { runSeq: 2, runId: 'run-3' })));
  });

  it('exact fields and types; Operator (playtest) progress and bad ids refused; never deleted', async () => {
    const f = await synced();
    const c = doc(f, `${base()}/cases/ep01`);
    await assertFails(setDoc(c, { ...kase(0, 2), coins: 999 }), 'extra field');
    await assertFails(setDoc(c, kase(0, 2, { runSeq: '1' })), 'runSeq type');
    await assertFails(setDoc(c, kase(0, 2, { progress: ['m01'] })), 'progress type');
    await assertFails(setDoc(c, kase(0, 2, { runId: 42 })), 'runId type');
    await assertFails(setDoc(c, kase(0, 2, { progress: { playtest: true } })), 'operator record');
    await assertFails(setDoc(c, kase(0, 2, { updatedAt: Timestamp.fromDate(new Date(2020, 0, 1)) })), 'client time');
    await assertSucceeds(setDoc(c, kase(0, 2, { runId: null })), 'a legacy run without id');
    await assertFails(setDoc(doc(f, `${base()}/cases/EP01`), kase(0, 1)), 'case id format');
    await assertFails(setDoc(doc(f, `${base()}/cases/ep01-x!`), kase(0, 1)), 'case id format');
    await assertFails(deleteDoc(c));
  });
});

describe('season/state', () => {
  it('version 1 then exactly +1, at the server epoch; only "state"; exact fields', async () => {
    const f = await synced();
    const s = doc(f, `${base()}/season/state`);
    await assertSucceeds(setDoc(s, season(0, 2, { solvedEpisodeIds: ['ep01', 'ep02'] })));
    await assertFails(setDoc(s, season(0, 4)), 'skipped');
    await assertFails(setDoc(s, season(0, 2)), 'repeated');
    await assertFails(setDoc(s, season(1, 3)), 'epoch != server');
    await assertFails(setDoc(s, season(0, 3, { solvedEpisodeIds: 'ep01' })), 'list type');
    await assertFails(setDoc(s, { ...season(0, 3), activeEpisodeId: 'ep02' }), 'extra field');
    await assertFails(setDoc(doc(f, `${base()}/season/current`), season(0, 1)), 'other id');
    await assertFails(deleteDoc(s));
  });
});

describe('wallet: create-only events and a running balance that never goes below zero', () => {
  it('every coin of the game, counted once', async () => {
    const f = await synced(); // start 20
    await assertSucceeds(coin(f, { epoch: 0, key: 'mission:m01', amount: 30, source: 'mission', v: 2, balance: 50 }));
    await assertSucceeds(coin(f, { epoch: 0, key: 'mission:final', amount: 60, source: 'mission', v: 3, balance: 110 }));
    await assertSucceeds(coin(f, { epoch: 0, key: 'tip:m01:1', amount: 0, source: 'tip', v: 4, balance: 110 }));
    await assertSucceeds(coin(f, { epoch: 0, key: 'tip:m01:2', amount: -20, source: 'tip', v: 5, balance: 90 }));
    await assertSucceeds(coin(f, { epoch: 0, key: 'mission:ep02_m1', amount: 30, source: 'backfill', v: 6, balance: 120 }));
    const s = (await getDoc(doc(f, `${base()}/wallet/summary`))).data();
    if (s.balance !== 120 || s.cloudVersion !== 6) throw new Error(`summary ${JSON.stringify(s)}`);
  });

  it('the same event again (a second grant) is refused, even with a matching summary', async () => {
    const f = await synced();
    await assertSucceeds(coin(f, { epoch: 0, key: 'mission:m01', amount: 30, source: 'mission', v: 2, balance: 50 }));
    await assertFails(coin(f, { epoch: 0, key: 'mission:m01', amount: 30, source: 'mission', v: 3, balance: 80 }));
    await assertFails(coin(f, { epoch: 0, key: 'mission:m01', amount: 60, source: 'mission', v: 3, balance: 110 }));
  });

  it('events are never changed or removed', async () => {
    const f = await synced();
    const e = doc(f, `${base()}/wallet/0_start`);
    await assertFails(updateDoc(e, { amount: 60 }));
    await assertFails(setDoc(e, event(0, 'start', 20, 'start')));
    await assertFails(deleteDoc(e));
    await assertFails(deleteDoc(doc(f, `${base()}/wallet/summary`)));
  });

  it('below zero is refused: a second paid tip with 0 coins', async () => {
    const f = await synced(); // 20
    await assertSucceeds(coin(f, { epoch: 0, key: 'tip:m01:2', amount: -20, source: 'tip', v: 2, balance: 0 }));
    await assertFails(coin(f, { epoch: 0, key: 'tip:m02:2', amount: -20, source: 'tip', v: 3, balance: -20 }));
    // R3: a free tip (0) is fine.
    await assertSucceeds(coin(f, { epoch: 0, key: 'tip:m02:2', amount: 0, source: 'tip', v: 3, balance: 0 }));
  });

  it('a summary that does not add up, or moves without a new event, is refused', async () => {
    const f = await synced();
    await assertFails(coin(f, { epoch: 0, key: 'mission:m01', amount: 30, source: 'mission', v: 2, balance: 999 }));
    await assertFails(setDoc(doc(f, `${base()}/wallet/summary`), summary(0, 2, 999, '0_start')), 'replays an old event');
    await assertFails(setDoc(doc(f, `${base()}/wallet/summary`), summary(0, 2, 40, '0_nothing')), 'no such event');
    await assertFails(coin(f, { epoch: 0, key: 'mission:m01', amount: 30, source: 'mission', v: 3, balance: 50 }), 'version skipped');
  });

  it('an event without its summary is refused', async () => {
    const f = await synced();
    await assertFails(setDoc(doc(f, `${base()}/wallet/0_mission:m01`), event(0, 'mission:m01', 30, 'mission')));
  });

  it('only the economy: no refunds, no made-up amounts or sources, ids carry the epoch', async () => {
    const f = await synced();
    const tries = [
      { key: 'refund:tip:m01:2', amount: 20, source: 'syncRefund' },
      { key: 'mission:m01', amount: 100, source: 'mission' },
      { key: 'mission:m01', amount: 30, source: 'gift' },
      { key: 'start', amount: 30, source: 'start' },
      { key: 'tip:m01:1', amount: -20, source: 'tip' },
      { key: 'tip:m01:3', amount: 0, source: 'tip' },
      { key: 'tip:m01:2', amount: -40, source: 'tip' },
      { key: 'mission:m 01', amount: 30, source: 'mission' },
    ];
    for (const t of tries) {
      await assertFails(coin(f, { epoch: 0, v: 2, balance: 20 + t.amount, ...t }), JSON.stringify(t));
    }
    // An id that does not carry the event's epoch and key.
    const b = writeBatch(f);
    b.set(doc(f, `${base()}/wallet/mission:m01`), event(0, 'mission:m01', 30, 'mission'));
    b.set(doc(f, `${base()}/wallet/summary`), summary(0, 2, 50, 'mission:m01'));
    await assertFails(b.commit(), 'id without epoch');
    const c = writeBatch(f);
    c.set(doc(f, `${base()}/wallet/1_mission:m01`), event(0, 'mission:m01', 30, 'mission'));
    c.set(doc(f, `${base()}/wallet/summary`), summary(0, 2, 50, '1_mission:m01'));
    await assertFails(c.commit(), 'id epoch != event epoch');
    // Extra fields or wrong types.
    const d = writeBatch(f);
    d.set(doc(f, `${base()}/wallet/0_mission:m01`), { ...event(0, 'mission:m01', 30, 'mission'), playtest: false });
    d.set(doc(f, `${base()}/wallet/summary`), summary(0, 2, 50, '0_mission:m01'));
    await assertFails(d.commit(), 'extra field');
    const e = writeBatch(f);
    e.set(doc(f, `${base()}/wallet/0_mission:m01`), { ...event(0, 'mission:m01', 30, 'mission'), amount: '30' });
    e.set(doc(f, `${base()}/wallet/summary`), summary(0, 2, 50, '0_mission:m01'));
    await assertFails(e.commit(), 'amount type');
  });

  it('after a reset: the new epoch starts again from its own events; old-epoch events are refused', async () => {
    const f = await synced(); // epoch 1, balance 20
    await assertSucceeds(coin(f, { epoch: 0, key: 'mission:m01', amount: 30, source: 'mission', v: 2, balance: 50 }));
    await assertSucceeds(setDoc(doc(f, `${base()}/sync/meta`), meta(1, 2)));
    // The same keys again in the new epoch: different ids, allowed; the balance starts over.
    await assertSucceeds(coin(f, { epoch: 1, key: 'start', amount: 20, source: 'start', v: 3, balance: 20 }));
    await assertSucceeds(coin(f, { epoch: 1, key: 'mission:m01', amount: 30, source: 'mission', v: 4, balance: 50 }));
    // A late old-epoch event (a device that missed the reset): refused.
    await assertFails(coin(f, { epoch: 0, key: 'mission:m02', amount: 30, source: 'mission', v: 5, balance: 80 }));
    await assertFails(coin(f, { epoch: 1, key: 'mission:m02', amount: 30, source: 'mission', v: 5, balance: 110 }), 'old balance carried');
  });
});

describe('only the shipped season: real missions, real cases, the game\'s own progress shape', () => {
  it('a made-up mission cannot pay coins; a real one pays only its own amount', async () => {
    const f = await synced();
    for (const t of [
      { key: 'mission:madeup1', amount: 60, source: 'mission' },
      { key: 'mission:madeup2', amount: 30, source: 'backfill' },
      { key: 'mission:m01', amount: 60, source: 'mission' },
      { key: 'mission:final', amount: 30, source: 'mission' },
      { key: 'tip:madeup1:2', amount: -20, source: 'tip' },
      { key: 'tip:madeup1:1', amount: 0, source: 'tip' },
    ]) {
      await assertFails(coin(f, { epoch: 0, v: 2, balance: 20 + t.amount, ...t }), JSON.stringify(t));
    }
    await assertSucceeds(coin(f, { epoch: 0, key: 'mission:ep12_final', amount: 60, source: 'mission', v: 2, balance: 80 }));
  });

  it('cases: only shipped case ids; completed missions of that case only', async () => {
    const f = await synced();
    await assertFails(setDoc(doc(f, `${base()}/cases/ep13`), kase(0, 1, { progress: {} })));
    await assertFails(setDoc(doc(f, `${base()}/cases/ep02`), kase(0, 1, { progress: { completedMissionIds: ['m01'] } })), 'another case\'s mission');
    await assertFails(setDoc(doc(f, `${base()}/cases/ep02`), kase(0, 1, { progress: { completedMissionIds: ['made_up'] } })));
    await assertFails(setDoc(doc(f, `${base()}/cases/ep02`), kase(0, 1, { progress: { attempts: { m01: 3 } } })), 'map key of another case');
    await assertSucceeds(setDoc(doc(f, `${base()}/cases/ep02`), kase(0, 1, { progress: { completedMissionIds: ['ep02_m1'], attempts: { ep02_m1: 2 } } })));
  });

  it('progress: unknown fields and wrong shapes are refused', async () => {
    const f = await synced();
    const c = doc(f, `${base()}/cases/ep01`);
    const bad = [
      { coins: 999 },
      { introSeen: 'yes' },
      { completedMissionIds: 'm01' },
      { attempts: ['m01'] },
      { behavior: { rechecked: [], hacked: true } },
      { behavior: 'x' },
      { badgeIds: 'firstClue' },
      { playMillis: -5 },
      { detectiveName: 'X'.repeat(25) },
      { startedAt: 12345 },
      { playtest: true },
    ];
    for (const b of bad) {
      await assertFails(setDoc(c, kase(0, 2, { progress: { completedMissionIds: ['m01'], ...b } })), JSON.stringify(b));
    }
    await assertSucceeds(setDoc(c, kase(0, 2, { progress: {
      detectiveName: 'ANNA', introSeen: true, completedMissionIds: ['m01', 'm02'], attempts: { m01: 1 },
      wrongAnswers: { m02: 1 }, hintsUsed: { m01: 2 }, missionStartedAt: { m03: '2026-10-14T00:00:00.000' },
      missionStartPlayMillis: { m03: 1000 }, solveSeconds: { m01: 40 }, badgeIds: ['firstClue'],
      lookedUpWords: ['crown'], lookupsRecorded: false, xpRules: { m01: 4 },
      behavior: { rechecked: [], evidenceViewed: ['e01'], words: ['crown'] },
      startedAt: '2026-10-14T00:00:00.000', completedAt: null, playMillis: 60000, runId: 'run-1', runSeq: 1, rev: 3,
    } })));
  });

  it('the largest real progress still fits the rules\' expression budget', async () => {
    const f = await synced();
    const ms = ['m01', 'm02', 'm03', 'm04', 'm05', 'final'];
    const per = (v) => Object.fromEntries(ms.map((m) => [m, v]));
    const words = Array.from({ length: 300 }, (_, i) => `w${i}`);
    await assertSucceeds(setDoc(doc(f, `${base()}/cases/ep01`), kase(0, 2, { progress: {
      detectiveName: 'ABCDEFGHIJKL', introSeen: true, completedMissionIds: ms, attempts: per(9), wrongAnswers: per(9),
      hintsUsed: per(2), missionStartedAt: per('2026-10-14T00:00:00.000'), missionStartPlayMillis: per(1000),
      solveSeconds: per(600), badgeIds: Array.from({ length: 32 }, (_, i) => `b${i}`), lookedUpWords: words,
      lookupsRecorded: true, xpRules: per(4),
      behavior: { rechecked: ms, evidenceViewed: Array.from({ length: 64 }, (_, i) => `e${i}`), words },
      startedAt: '2026-10-14T00:00:00.000', completedAt: '2026-10-14T01:00:00.000', playMillis: 3600000,
      runId: 'r'.repeat(64), runSeq: 99, rev: 999,
    } })));
  });

  it('season: shipped case ids only', async () => {
    const f = await synced();
    await assertFails(setDoc(doc(f, `${base()}/season/state`), season(0, 2, { solvedEpisodeIds: ['ep01', 'ep99'] })));
    await assertSucceeds(setDoc(doc(f, `${base()}/season/state`), season(0, 2, { solvedEpisodeIds: ['ep01', 'ep12'] })));
  });
});

describe('each account only its own', () => {
  it("another account (consented) and signed-out users cannot read or write alice's sync data", async () => {
    await synced();
    await ready('bob');
    const bob = db('bob');
    for (const p of ['sync/meta', 'cases/ep01', 'season/state', 'wallet/summary', 'wallet/0_start']) {
      await assertFails(getDoc(doc(bob, `${base()}/${p}`)), p);
      await assertFails(getDoc(doc(db(null), `${base()}/${p}`)), p);
    }
    await assertFails(getDocs(collection(bob, `${base()}/cases`)));
    await assertFails(getDocs(collection(bob, `${base()}/wallet`)));
    await assertFails(setDoc(doc(bob, `${base()}/cases/ep01`), kase(0, 2)));
    await assertFails(setDoc(doc(bob, `${base()}/sync/meta`), meta(1, 2)));
    await assertFails(coin(bob, { epoch: 0, key: 'mission:m01', amount: 30, source: 'mission', v: 2, balance: 50, uid: 'alice' }));
    // alice reads her own (D4: owner reads stay open).
    const alice = db('alice');
    await assertSucceeds(getDocs(collection(alice, `${base()}/cases`)));
    await assertSucceeds(getDocs(collection(alice, `${base()}/wallet`)));
  });

  it('a profile that does not exist takes no sync data', async () => {
    await ready();
    const other = 'fedcba9876543210fedcba9876543210';
    await assertFails(setDoc(doc(db('alice'), `users/alice/profiles/${other}/sync/meta`), meta(0, 1)));
  });
});

describe('consent', () => {
  it('no confirmed consent: no sync writes (reads of her own data stay open)', async () => {
    await synced();
    await seed((f) => setDoc(doc(f, 'consents/alice'), { status: 'unconfirmed', schema: 1 }));
    const f = db('alice');
    await assertFails(setDoc(doc(f, `${base()}/cases/ep01`), kase(0, 2)));
    await assertFails(setDoc(doc(f, `${base()}/sync/meta`), meta(1, 2)));
    await assertFails(setDoc(doc(f, `${base()}/season/state`), season(0, 2)));
    await assertFails(coin(f, { epoch: 0, key: 'mission:m01', amount: 30, source: 'mission', v: 2, balance: 50 }));
    await assertSucceeds(getDoc(doc(f, `${base()}/cases/ep01`)));
  });

  it('a client cannot confirm its own consent to get past this', async () => {
    await ready();
    await seed((f) => setDoc(doc(f, 'consents/alice'), { status: 'unconfirmed', schema: 1 }));
    await assertFails(setDoc(doc(db('alice'), 'consents/alice'), { status: 'confirmed', schema: 1 }));
    await assertFails(setDoc(doc(db('alice'), `${base()}/sync/meta`), meta(0, 1)));
  });
});

describe('deletion in progress', () => {
  it('nothing is written while deletions/{uid} exists; its owner can see it; nobody else; clients never write it', async () => {
    const f = await synced();
    await seed((s) => setDoc(doc(s, 'deletions/alice'), { status: 'started', step: 'begin' }));
    await assertFails(setDoc(doc(f, `${base()}/cases/ep01`), kase(0, 2)));
    await assertFails(setDoc(doc(f, `${base()}/sync/meta`), meta(1, 2)));
    await assertFails(setDoc(doc(f, `${base()}/season/state`), season(0, 2)));
    await assertFails(coin(f, { epoch: 0, key: 'mission:m01', amount: 30, source: 'mission', v: 2, balance: 50 }));
    await assertFails(updateDoc(doc(f, 'users/alice'), { locale: 'en' }), 'the account doc too');
    await assertFails(setDoc(doc(f, `users/alice/profiles/fedcba9876543210fedcba9876543210`), { schema: 1, detectiveName: 'B', createdAt: serverTimestamp() }));
    await assertSucceeds(getDoc(doc(f, 'deletions/alice')));
    await ready('bob');
    await assertFails(getDoc(doc(db('bob'), 'deletions/alice')));
    await assertFails(setDoc(doc(db('bob'), 'deletions/bob'), { status: 'started' }));
    await assertFails(deleteDoc(doc(f, 'deletions/alice')), 'the owner cannot lift it');
  });
});
