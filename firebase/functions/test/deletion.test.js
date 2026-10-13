'use strict';
// Account deletion on the Firestore and Auth emulators (demo project, no
// real data, nothing deployed): cd firebase/functions && npm test
const assert = require('node:assert/strict');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { CONSENT_POLICY, STALE_AFTER_MS, checkCaller, finishStaleDeletions, runDeletion } = require('../deletion');

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error('Run on the emulators (npm test), never against a real project.');
}
initializeApp({ projectId: 'demo-london-mystery' });
const db = getFirestore();
const auth = getAuth();

let clock = new Date('2026-10-13T12:00:00Z');
const now = () => clock;
const deps = (extra = {}) => ({ db, auth, now, consentPolicy: CONSENT_POLICY.retain, ...extra });
const hex = (n) => n.toString(16).padStart(32, '0');

/** An account with [profiles] detectives, game data under the first, and a consent record. */
async function account(uid, profiles = 2) {
  await auth.createUser({ uid, email: `${uid}@example.com`, password: 'detective42' });
  await db.doc(`users/${uid}`).set({ schema: 1, locale: 'ko', region: 'KR', createdAt: clock });
  const w = db.bulkWriter();
  for (let i = 0; i < profiles; i++) {
    w.set(db.doc(`users/${uid}/profiles/${hex(i + 1)}`), { schema: 1, detectiveName: `D${i}`, createdAt: clock });
  }
  w.set(db.doc(`users/${uid}/profiles/${hex(1)}/cases/ep01`), { solved: ['m01'] });
  w.set(db.doc(`users/${uid}/profiles/${hex(1)}/wallet/entries`), { coins: 30 });
  await w.close();
  await db.doc(`consents/${uid}`).set({ status: 'confirmed', schema: 1 });
}

async function exists(path) {
  return (await db.doc(path).get()).exists;
}

async function authUser(uid) {
  try {
    await auth.getUser(uid);
    return true;
  } catch (e) {
    if (e.code === 'auth/user-not-found') return false;
    throw e;
  }
}

async function countUnder(uid) {
  const all = await db.collectionGroup('profiles').get();
  return all.docs.filter((d) => d.ref.path.startsWith(`users/${uid}/`)).length;
}

beforeEach(async () => {
  clock = new Date('2026-10-13T12:00:00Z');
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-london-mystery/databases/(default)/documents`, { method: 'DELETE' });
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/demo-london-mystery/accounts`, { method: 'DELETE' });
});

describe('who may delete', () => {
  const nowS = 1_800_000_000;
  it('signed out: refused', () => {
    assert.throws(() => checkCaller(null, nowS), { code: 'unauthenticated' });
    assert.throws(() => checkCaller({}, nowS), { code: 'unauthenticated' });
  });
  it('signed in more than five minutes ago: asked to sign in again', () => {
    assert.throws(() => checkCaller({ uid: 'a', token: { auth_time: nowS - 301 } }, nowS), { message: 'requires-recent-login' });
    assert.throws(() => checkCaller({ uid: 'a', token: {} }, nowS), { message: 'requires-recent-login' });
  });
  it('signed in just now: only their own uid is ever used', () => {
    assert.equal(checkCaller({ uid: 'alice', token: { auth_time: nowS - 10 } }, nowS), 'alice');
  });
});

describe('deleting an account', () => {
  it('removes the account data recursively and the sign-in; others untouched; consent kept (policy)', async () => {
    await account('alice', 3);
    await account('bob', 1);
    const done = await runDeletion('alice', deps());
    assert.equal(done.status, 'completed');
    assert.equal(done.consentRetained, true);
    assert.equal(await exists('users/alice'), false);
    assert.equal(await countUnder('alice'), 0);
    assert.equal(await exists(`users/alice/profiles/${hex(1)}/cases/ep01`), false, 'game data under a profile');
    assert.equal(await exists(`users/alice/profiles/${hex(1)}/wallet/entries`), false);
    assert.equal(await authUser('alice'), false);
    assert.equal(await exists('consents/alice'), true, 'kept until the legal retention policy says otherwise');
    // Bob is untouched.
    assert.equal(await exists('users/bob'), true);
    assert.equal(await countUnder('bob'), 1);
    assert.equal(await exists(`users/bob/profiles/${hex(1)}/cases/ep01`), true);
    assert.equal(await authUser('bob'), true);
    // The tracker: pseudonymous (uid as its id), no email or name.
    const t = (await db.doc('deletions/alice').get()).data();
    assert.deepEqual(Object.keys(t).sort(), ['attempts', 'completedAt', 'consentPolicy', 'consentRetained', 'lastAttemptAt', 'startedAt', 'status', 'step']);
    assert.equal(JSON.stringify(t).includes('@'), false);
  });

  it('consent policy "delete": the consent record goes too', async () => {
    await account('alice');
    await runDeletion('alice', deps({ consentPolicy: CONSENT_POLICY.delete }));
    assert.equal(await exists('consents/alice'), false);
  });

  it('more than a batch (600 profiles): all gone', async () => {
    await account('alice', 600);
    await runDeletion('alice', deps());
    assert.equal(await countUnder('alice'), 0);
  });

  it('no consent policy, or a bad uid: refused before anything is touched', async () => {
    await account('alice');
    await assert.rejects(runDeletion('alice', deps({ consentPolicy: undefined })), { code: 'failed-precondition' });
    await assert.rejects(runDeletion('../x', deps()), { code: 'invalid-argument' });
    await assert.rejects(runDeletion('', deps()), { code: 'invalid-argument' });
    assert.equal(await exists('users/alice'), true);
    assert.equal(await exists('deletions/alice'), false);
  });

  it('already completed: a repeat call changes nothing and succeeds', async () => {
    await account('alice');
    await runDeletion('alice', deps());
    const again = await runDeletion('alice', deps());
    assert.equal(again.status, 'completed');
    assert.equal(again.attempts, 1);
  });
});

describe('a failure part way: calling again finishes it', () => {
  for (const step of ['started', 'data-deleted', 'consent-handled']) {
    it(`fails after "${step}": still 'started'; the retry completes`, async () => {
      await account('alice');
      const fail = async (s) => {
        if (s === step) throw new Error(`crash after ${s}`);
      };
      await assert.rejects(runDeletion('alice', deps({ fail })), /crash/);
      const mid = (await db.doc('deletions/alice').get()).data();
      assert.equal(mid.status, 'started');
      assert.equal(await authUser('alice'), true, 'the sign-in is last: still there, so the user can retry');
      const done = await runDeletion('alice', deps());
      assert.equal(done.status, 'completed');
      assert.equal(done.attempts, 2);
      assert.equal(await exists('users/alice'), false);
      assert.equal(await authUser('alice'), false);
    });
  }

  it('the sign-in is gone but "completed" was not written: the sweep finishes it', async () => {
    await account('alice');
    const fail = async (s) => {
      if (s === 'auth-deleted') throw new Error('crash after the sign-in was deleted');
    };
    await assert.rejects(runDeletion('alice', deps({ fail })), /crash/);
    assert.equal(await authUser('alice'), false, 'the user cannot call again');
    assert.equal((await db.doc('deletions/alice').get()).get('status'), 'started');

    // Too soon: the sweep leaves it (the user may still be retrying).
    assert.deepEqual(await finishStaleDeletions(deps()), []);
    // After 15 minutes: finished.
    clock = new Date(clock.getTime() + STALE_AFTER_MS + 1000);
    assert.deepEqual(await finishStaleDeletions(deps()), ['alice']);
    assert.equal((await db.doc('deletions/alice').get()).get('status'), 'completed');
  });

  it("a retry keeps the policy the deletion started with, even if the default changed", async () => {
    await account('alice');
    const fail = async (s) => {
      if (s === 'started') throw new Error('crash');
    };
    await assert.rejects(runDeletion('alice', deps({ fail, consentPolicy: CONSENT_POLICY.retain })), /crash/);
    const done = await runDeletion('alice', deps({ consentPolicy: CONSENT_POLICY.delete })); // new default
    assert.equal(done.consentPolicy, CONSENT_POLICY.retain);
    assert.equal(done.consentRetained, true);
    assert.equal(await exists('consents/alice'), true);
  });

  it('the sweep keeps its policy per record and ignores completed ones', async () => {
    await account('alice');
    await account('bob');
    await runDeletion('bob', deps()); // completed
    const fail = async (s) => {
      if (s === 'started') throw new Error('crash');
    };
    await assert.rejects(runDeletion('alice', deps({ fail, consentPolicy: CONSENT_POLICY.delete })), /crash/);
    clock = new Date(clock.getTime() + STALE_AFTER_MS + 1000);
    assert.deepEqual(await finishStaleDeletions(deps()), ['alice']);
    assert.equal(await exists('consents/alice'), false, "alice's recorded policy (delete) is used");
    assert.equal(await exists('consents/bob'), true);
  });
});
