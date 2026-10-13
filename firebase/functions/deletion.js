'use strict';
// Account deletion, server side (docs/PHASE3B_ACCOUNT_UI_PLAN.md §9).
//
// One account's deletion, in this order, each step safe to repeat:
//   1. deletions/{uid}  status 'started' (attempts counted)  — the tracker
//   2. users/{uid} and everything under it (recursive)       — the account's data
//   3. consents/{uid}: kept or deleted by the consent policy  — legal decision
//   4. the Auth user                                          — last of all
//   5. deletions/{uid}  status 'completed'
// A failure at any step leaves 'started': calling again (the user, or the
// scheduled sweep for stale records) does only what is left. The Auth user
// goes last, so the account's data never outlives a deleted sign-in unseen:
// the tracker says so, and the sweep finishes it.
//
// The tracker holds pseudonymous data: the uid (its document id, a lasting
// identifier) with times and steps; no email or name. Its access is
// server-only and its retention is to be decided (docs §9.2).

const RECENT_LOGIN_SECONDS = 5 * 60;
const STALE_AFTER_MS = 15 * 60 * 1000;

/** Consent record policy, until the legal retention decision is made. */
const CONSENT_POLICY = Object.freeze({ retain: 'retain', delete: 'delete' });

class DeletionError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

/**
 * Who may delete: a signed-in caller, deleting themselves, who signed in
 * within the last five minutes (the app asks for the password first).
 * [auth] is the callable request's auth ({ uid, token }).
 */
function checkCaller(auth, nowSeconds) {
  if (!auth || !auth.uid) throw new DeletionError('unauthenticated', 'Sign in first.');
  const authTime = Number(auth.token && auth.token.auth_time);
  if (!Number.isFinite(authTime) || nowSeconds - authTime > RECENT_LOGIN_SECONDS) {
    throw new DeletionError('failed-precondition', 'requires-recent-login');
  }
  return auth.uid;
}

/**
 * Runs (or resumes) the deletion of [uid].
 * deps: { db (admin Firestore), auth (admin Auth), now(): Date,
 *         consentPolicy: 'retain'|'delete', fail?(step) for tests }
 * Returns the finished tracker fields.
 */
async function runDeletion(uid, deps) {
  if (typeof uid !== 'string' || uid.length === 0 || uid.includes('/')) {
    throw new DeletionError('invalid-argument', 'bad uid');
  }
  const { db, auth, now, consentPolicy } = deps;
  if (!Object.values(CONSENT_POLICY).includes(consentPolicy)) {
    throw new DeletionError('failed-precondition', 'no consent policy');
  }
  const fail = deps.fail || (() => {});
  const tracker = db.doc(`deletions/${uid}`);
  const { FieldValue } = require('firebase-admin/firestore');

  // 1. Tracker (merge: a retry keeps startedAt, counts the attempt). A
  // deletion keeps the consent policy it started with, whoever retries it.
  const before = await tracker.get();
  if (before.exists && before.get('status') === 'completed') return before.data();
  const policy = (before.exists && before.get('consentPolicy')) || consentPolicy;
  await tracker.set(
    {
      status: 'started',
      startedAt: before.exists ? before.get('startedAt') : now(),
      lastAttemptAt: now(),
      attempts: FieldValue.increment(1),
      consentPolicy: policy,
    },
    { merge: true },
  );
  await fail('started');

  // 2. The account's data, recursively (profiles and, later, game data).
  await db.recursiveDelete(db.doc(`users/${uid}`));
  await tracker.set({ step: 'data-deleted' }, { merge: true });
  await fail('data-deleted');

  // 3. The consent record, by policy.
  if (policy === CONSENT_POLICY.delete) await db.doc(`consents/${uid}`).delete();
  await tracker.set({ step: 'consent-handled', consentRetained: policy === CONSENT_POLICY.retain }, { merge: true });
  await fail('consent-handled');

  // 4. The sign-in, last. Already gone (an earlier attempt): fine.
  try {
    await auth.deleteUser(uid);
  } catch (e) {
    if (!e || e.code !== 'auth/user-not-found') throw e;
  }
  await fail('auth-deleted');

  // 5. Done.
  const done = { status: 'completed', step: 'auth-deleted', completedAt: now() };
  await tracker.set(done, { merge: true });
  return (await tracker.get()).data();
}

/**
 * The sweep: finishes deletions left 'started' for longer than 15 minutes
 * (a crash, or the Auth user already gone so the caller cannot retry).
 * Returns the uids it finished; one failure does not stop the others.
 */
async function finishStaleDeletions(deps) {
  const cutoff = deps.now().getTime() - STALE_AFTER_MS;
  // One equality filter only: served by Firestore's automatic single-field
  // index, so the sweep needs no composite index to be deployed. The age is
  // checked here (few records are ever 'started').
  const started = await deps.db.collection('deletions').where('status', '==', 'started').get();
  const stale = started.docs.filter((d) => {
    const t = d.get('lastAttemptAt');
    return t && t.toDate().getTime() < cutoff;
  });
  const finished = [];
  for (const d of stale) {
    try {
      await runDeletion(d.id, deps); // the record's own consent policy is used
      finished.push(d.id);
    } catch (e) {
      console.error('deletion sweep: still failing', d.id.slice(0, 4), e.code || e.name);
    }
  }
  return finished;
}

module.exports = {
  CONSENT_POLICY,
  DeletionError,
  RECENT_LOGIN_SECONDS,
  STALE_AFTER_MS,
  checkCaller,
  finishStaleDeletions,
  runDeletion,
};
