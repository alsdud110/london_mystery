'use strict';
// Cloud Functions for London Mystery — NOT DEPLOYED.
// Deploying needs the Blaze plan and a separate approval; the root
// firebase.json deliberately has no "functions" entry, so `firebase deploy`
// from the repository cannot ship these by accident.
// See docs/PHASE3B_ACCOUNT_UI_PLAN.md §9.
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { HttpsError, onCall } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { CONSENT_POLICY, DeletionError, checkCaller, finishStaleDeletions, runDeletion } = require('./deletion');

initializeApp();
const region = 'asia-northeast3';

// Until the legal retention decision: the consent record is kept.
const consentPolicy = CONSENT_POLICY.retain;
const deps = () => ({ db: getFirestore(), auth: getAuth(), now: () => new Date(), consentPolicy });

/** Deletes the caller's own account (recently signed in). */
exports.deleteAccount = onCall({ region, enforceAppCheck: false }, async (request) => {
  try {
    const uid = checkCaller(request.auth, Math.floor(Date.now() / 1000));
    const done = await runDeletion(uid, deps());
    return { status: done.status, consentRetained: done.consentRetained === true };
  } catch (e) {
    if (e instanceof DeletionError) throw new HttpsError(e.code, e.message);
    console.error('deleteAccount failed', e.code || e.name); // the error code only: no uid, email or token
    throw new HttpsError('unavailable', 'try-again');
  }
});

/** Finishes deletions left half-done (hourly). */
exports.finishStaleDeletions = onSchedule({ region, schedule: 'every 60 minutes' }, async () => {
  await finishStaleDeletions(deps());
});
