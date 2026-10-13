// Firestore security rules (firebase/firestore.rules), on the emulator.
// Run: cd firebase && npm test   (needs JDK 21+; no Firebase login, no
// real project: the project id is a demo-* one.)
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

const PROFILE = '0123456789abcdef0123456789abcdef';
const OTHER_PROFILE = 'fedcba9876543210fedcba9876543210';

let env;

const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const user = () => ({ schema: 1, createdAt: serverTimestamp(), locale: 'ko', region: 'KR' });
const profile = (name = 'MINYOUNG') => ({ schema: 1, detectiveName: name, createdAt: serverTimestamp() });

/** Writes with the rules off: what only a trusted backend can do. */
async function seed(write) {
  await env.withSecurityRulesDisabled(async (ctx) => write(ctx.firestore()));
}
const confirm = (uid, status = 'confirmed') => seed((f) => setDoc(doc(f, 'consents', uid), { status, schema: 1 }));
/** alice: consent confirmed, users doc and one profile made. */
async function aliceReady() {
  await confirm('alice');
  await assertSucceeds(setDoc(doc(db('alice'), 'users/alice'), user()));
  await assertSucceeds(setDoc(doc(db('alice'), `users/alice/profiles/${PROFILE}`), profile()));
}

before(async () => {
  setLogLevel('silent'); // denied writes are expected here
  env = await initializeTestEnvironment({
    projectId: 'demo-london-mystery',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => env.clearFirestore());
after(async () => env.cleanup());

describe('signed out', () => {
  it('reads and writes nothing', async () => {
    await confirm('alice');
    await assertFails(getDoc(doc(db(null), 'users/alice')));
    await assertFails(setDoc(doc(db(null), 'users/alice'), user()));
    await assertFails(getDoc(doc(db(null), 'consents/alice')));
    await assertFails(getDoc(doc(db(null), `users/alice/profiles/${PROFILE}`)));
  });
});

describe('consent: no confirmed record, no cloud writes', () => {
  it('no record: the users doc cannot be made', async () => {
    await assertFails(setDoc(doc(db('alice'), 'users/alice'), user()));
  });

  for (const status of ['unconfirmed', 'pending', 'Confirmed', 'CONFIRMED', true, 1]) {
    it(`status ${JSON.stringify(status)}: denied`, async () => {
      await confirm('alice', status);
      await assertFails(setDoc(doc(db('alice'), 'users/alice'), user()));
    });
  }

  it('a record without a status: denied', async () => {
    await seed((f) => setDoc(doc(f, 'consents/alice'), { schema: 1 }));
    await assertFails(setDoc(doc(db('alice'), 'users/alice'), user()));
  });

  it('consent withdrawn: profiles and the users doc can no longer be written', async () => {
    await aliceReady();
    await confirm('alice', 'unconfirmed');
    await assertFails(updateDoc(doc(db('alice'), 'users/alice'), { locale: 'en' }));
    await assertFails(updateDoc(doc(db('alice'), `users/alice/profiles/${PROFILE}`), { detectiveName: 'MIN' }));
    await assertFails(setDoc(doc(db('alice'), `users/alice/profiles/${OTHER_PROFILE}`), profile()));
    // Reading what is already there stays allowed.
    await assertSucceeds(getDoc(doc(db('alice'), `users/alice/profiles/${PROFILE}`)));
  });

  it("another account's confirmed consent does not count", async () => {
    await confirm('bob');
    await assertFails(setDoc(doc(db('alice'), 'users/alice'), user()));
  });
});

describe('consent record: read-only to its owner, cannot be forged', () => {
  it('the owner reads their own record; not anyone else’s; no listing', async () => {
    await confirm('alice');
    await confirm('bob');
    await assertSucceeds(getDoc(doc(db('alice'), 'consents/alice')));
    await assertFails(getDoc(doc(db('alice'), 'consents/bob')));
    await assertFails(getDocs(collection(db('alice'), 'consents')));
  });

  it('a client cannot create its own record as confirmed', async () => {
    await assertFails(setDoc(doc(db('alice'), 'consents/alice'), { status: 'confirmed', schema: 1 }));
    await assertFails(setDoc(doc(db('alice'), 'consents/alice'), { status: 'unconfirmed' }));
  });

  it('a client cannot change, overwrite or delete its record', async () => {
    await confirm('alice', 'unconfirmed');
    await assertFails(updateDoc(doc(db('alice'), 'consents/alice'), { status: 'confirmed' }));
    await assertFails(setDoc(doc(db('alice'), 'consents/alice'), { status: 'confirmed', schema: 1 }));
    await assertFails(deleteDoc(doc(db('alice'), 'consents/alice')));
  });

  it("a client cannot write another account's record", async () => {
    await assertFails(setDoc(doc(db('alice'), 'consents/bob'), { status: 'confirmed' }));
  });

  it('consent cannot be carried in the users doc', async () => {
    await assertFails(setDoc(doc(db('alice'), 'users/alice'), { ...user(), consent: { status: 'confirmed' } }));
    await confirm('alice');
    await assertFails(setDoc(doc(db('alice'), 'users/alice'), { ...user(), consent: { status: 'confirmed' } }));
    await assertSucceeds(setDoc(doc(db('alice'), 'users/alice'), user()));
    await assertFails(updateDoc(doc(db('alice'), 'users/alice'), { consent: { status: 'confirmed' } }));
  });
});

describe('users/{uid}: each account only its own', () => {
  it('with confirmed consent: the owner makes and reads the users doc (serverTimestamp)', async () => {
    await confirm('alice');
    await assertSucceeds(setDoc(doc(db('alice'), 'users/alice'), user()));
    const snap = await assertSucceeds(getDoc(doc(db('alice'), 'users/alice')));
    const createdAt = snap.data().createdAt;
    if (!(createdAt instanceof Timestamp)) throw new Error('createdAt is not a server timestamp');
  });

  it('createdAt must be the server time', async () => {
    await confirm('alice');
    await assertFails(setDoc(doc(db('alice'), 'users/alice'), { ...user(), createdAt: Timestamp.fromDate(new Date(2020, 0, 1)) }));
    await assertFails(setDoc(doc(db('alice'), 'users/alice'), { ...user(), createdAt: new Date() }));
    const { createdAt, ...rest } = user();
    await assertFails(setDoc(doc(db('alice'), 'users/alice'), rest));
  });

  it('only the allowed fields, with valid values', async () => {
    await confirm('alice');
    await assertFails(setDoc(doc(db('alice'), 'users/alice'), { ...user(), email: 'a@example.com' }));
    await assertFails(setDoc(doc(db('alice'), 'users/alice'), { ...user(), schema: 2 }));
    await assertFails(setDoc(doc(db('alice'), 'users/alice'), { ...user(), locale: 'korean' }));
    await assertFails(setDoc(doc(db('alice'), 'users/alice'), { ...user(), region: 'kr' }));
  });

  it('updates: locale and region only; createdAt and schema stay', async () => {
    await aliceReady();
    await assertSucceeds(updateDoc(doc(db('alice'), 'users/alice'), { locale: 'en', region: 'GB' }));
    await assertFails(updateDoc(doc(db('alice'), 'users/alice'), { createdAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db('alice'), 'users/alice'), { schema: 2 }));
    await assertFails(updateDoc(doc(db('alice'), 'users/alice'), { nickname: 'x' }));
  });

  it("another account cannot read, write or list alice's data, even with its own consent", async () => {
    await aliceReady();
    await confirm('bob');
    await assertFails(getDoc(doc(db('bob'), 'users/alice')));
    await assertFails(setDoc(doc(db('bob'), 'users/alice'), user()));
    await assertFails(updateDoc(doc(db('bob'), 'users/alice'), { locale: 'en' }));
    await assertFails(getDoc(doc(db('bob'), `users/alice/profiles/${PROFILE}`)));
    await assertFails(getDocs(collection(db('bob'), 'users/alice/profiles')));
    await assertFails(setDoc(doc(db('bob'), `users/alice/profiles/${OTHER_PROFILE}`), profile()));
    await assertFails(updateDoc(doc(db('bob'), `users/alice/profiles/${PROFILE}`), { detectiveName: 'BOB' }));
    await assertFails(getDocs(collection(db('bob'), 'users')));
  });

  it('nobody deletes a users doc', async () => {
    await aliceReady();
    await assertFails(deleteDoc(doc(db('alice'), 'users/alice')));
  });
});

describe('users/{uid}/profiles/{profileId}', () => {
  it('the owner makes, reads and lists profiles (serverTimestamp)', async () => {
    await aliceReady();
    const snap = await assertSucceeds(getDoc(doc(db('alice'), `users/alice/profiles/${PROFILE}`)));
    if (!(snap.data().createdAt instanceof Timestamp)) throw new Error('createdAt is not a server timestamp');
    const list = await assertSucceeds(getDocs(collection(db('alice'), 'users/alice/profiles')));
    if (list.size !== 1) throw new Error(`expected 1 profile, got ${list.size}`);
  });

  it('needs the users doc first', async () => {
    await confirm('alice');
    await assertFails(setDoc(doc(db('alice'), `users/alice/profiles/${PROFILE}`), profile()));
  });

  it('one batch: the users doc and its first profile together (Phase 3B)', async () => {
    await confirm('alice');
    const f = db('alice');
    const batch = writeBatch(f);
    batch.set(doc(f, 'users/alice'), user());
    batch.set(doc(f, `users/alice/profiles/${PROFILE}`), profile());
    await assertSucceeds(batch.commit());
  });

  it('one batch without consent, or a profile alone in a batch: denied', async () => {
    const f = db('alice');
    const both = writeBatch(f);
    both.set(doc(f, 'users/alice'), user());
    both.set(doc(f, `users/alice/profiles/${PROFILE}`), profile());
    await assertFails(both.commit());
    await confirm('alice');
    const alone = writeBatch(f);
    alone.set(doc(f, `users/alice/profiles/${PROFILE}`), profile());
    await assertFails(alone.commit());
  });

  it('profile id: the local id, 8 to 64 lowercase hex characters', async () => {
    await aliceReady();
    for (const id of ['0123abcd', 'f'.repeat(64), `${PROFILE}0`]) {
      await assertSucceeds(setDoc(doc(db('alice'), `users/alice/profiles/${id}`), profile()));
    }
    for (const id of ['abc', '0123abc', 'f'.repeat(65), PROFILE.toUpperCase(), 'g123456789abcdef0123456789abcdef', `${PROFILE}-x`]) {
      await assertFails(setDoc(doc(db('alice'), `users/alice/profiles/${id}`), profile()));
    }
  });

  it('detective name: the shared rule (letters, Hangul, digits, single spaces, . -, 1 to 12)', async () => {
    await aliceReady();
    const ok = ['ABCDEFGHIJKL', 'Min Young', 'minyoung', '김민영', '가'.repeat(12), 'DR. WATSON', 'MARY-JANE', 'A', 'AGENT 007'];
    const bad = [
      '', ' ', 'ABCDEFGHIJKLM', '가'.repeat(13), ' MIN', 'MIN ', 'MIN  YOUNG', 'MIN\tYOUNG', 'MIN!', 'MIN_YOUNG',
      '😀', 'ㅁㅣㄴ', 'Ａ', 42,
    ];
    let n = 0;
    const id = () => (++n).toString(16).padStart(32, '0');
    for (const name of ok) await assertSucceeds(setDoc(doc(db('alice'), `users/alice/profiles/${id()}`), profile(name)));
    for (const name of bad) await assertFails(setDoc(doc(db('alice'), `users/alice/profiles/${id()}`), profile(name)));
  });

  it('only the allowed fields; createdAt is the server time', async () => {
    await aliceReady();
    const p = `users/alice/profiles/${OTHER_PROFILE}`;
    await assertFails(setDoc(doc(db('alice'), p), { ...profile(), age: 9 }));
    await assertFails(setDoc(doc(db('alice'), p), { ...profile(), createdAt: Timestamp.fromDate(new Date(2020, 0, 1)) }));
  });

  it('updates: the detective name only', async () => {
    await aliceReady();
    const p = doc(db('alice'), `users/alice/profiles/${PROFILE}`);
    await assertSucceeds(updateDoc(p, { detectiveName: 'MIN' }));
    await assertFails(updateDoc(p, { detectiveName: '' }));
    await assertFails(updateDoc(p, { detectiveName: 'MIN  YOUNG' }));
    await assertFails(updateDoc(p, { detectiveName: ' MIN' }));
    await assertFails(updateDoc(p, { createdAt: serverTimestamp() }));
    await assertFails(updateDoc(p, { schema: 2 }));
  });

  it('nobody deletes a profile', async () => {
    await aliceReady();
    await assertFails(deleteDoc(doc(db('alice'), `users/alice/profiles/${PROFILE}`)));
  });

  it('game data under a profile is closed (Phase 4)', async () => {
    await aliceReady();
    for (const p of ['cases/ep01', 'season/current', 'wallet/coins']) {
      await assertFails(setDoc(doc(db('alice'), `users/alice/profiles/${PROFILE}/${p}`), { x: 1 }));
      await assertFails(getDoc(doc(db('alice'), `users/alice/profiles/${PROFILE}/${p}`)));
    }
  });
});

describe('everything else is closed', () => {
  it('other collections, other subcollections of users, the old parents path', async () => {
    await aliceReady();
    for (const p of ['parents/alice', 'profiles/x', 'admin/config', 'users/alice/settings/a']) {
      await assertFails(setDoc(doc(db('alice'), p), { x: 1 }));
      await assertFails(getDoc(doc(db('alice'), p)));
    }
  });
});
