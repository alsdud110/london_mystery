// DEV-only admin path for Phase 4.3B-2 (the real DEV project, never PROD).
//
// Uses the Firebase CLI's own sign-in (`firebase login`), no service-account
// key. Every call is pinned to london-mystery-dev: the project id is a
// constant, a project argument is refused, and the project is checked on the
// server before anything else. Test accounts are made with a run id in their
// email (lm-e2e-<run>-<role>@londonmystery.test); seeding, reading and cleanup
// only ever touch the uids recorded for that run.
//
//   node scripts/dev_admin.mjs inspect            read-only checks before a deploy
//   node scripts/dev_admin.mjs seed <run>         make test accounts + consent
//   node scripts/dev_admin.mjs cleanup <run>      delete that run's data and accounts
//   node scripts/dev_admin.mjs leftovers <run>    what of that run is still there
//
// The run record (uids, emails, passwords, paths, times) is written to
// build/dev-e2e/<run>.json (git-ignored, mode 600). Tokens are never printed.
import { createRequire } from 'node:module';
import { randomBytes } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const PROJECT = 'london-mystery-dev';
if (!/^london-mystery-dev$/.test(PROJECT)) throw new Error('DEV only');

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '..', '..');
const runDir = path.join(repo, 'build', 'dev-e2e');
const require = createRequire(import.meta.url);

let cached;
async function token() {
  if (cached && cached.expires > Date.now() + 60_000) return cached.value;
  const auth = require('firebase-tools/lib/auth');
  const account = auth.getGlobalDefaultAccount();
  if (!account?.tokens?.refresh_token) throw new Error('firebase login needed');
  const t = await auth.getAccessToken(account.tokens.refresh_token, []);
  cached = { value: t.access_token, expires: Date.now() + 30 * 60_000 };
  return cached.value;
}

async function call(method, url, body) {
  if (!url.includes(`projects/${PROJECT}`)) throw new Error(`refused: not ${PROJECT}: ${url}`);
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${await token()}`,
      'x-goog-user-project': PROJECT,
      ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  const json = text ? JSON.parse(text) : {};
  return { status: res.status, json };
}

const FS = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;
const IDT = `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT}`;

/// The project really is london-mystery-dev (asked of the server).
export async function checkProject() {
  const r = await call('GET', `https://firebase.googleapis.com/v1beta1/projects/${PROJECT}`);
  if (r.status !== 200 || r.json.projectId !== PROJECT) throw new Error(`project check failed (${r.status})`);
  return r.json.projectId;
}

// ---- values ----
function enc(v) {
  if (v === null) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(enc) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, enc(x)])) } };
}
function dec(v) {
  if ('nullValue' in v) return null;
  if ('booleanValue' in v) return v.booleanValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('stringValue' in v) return v.stringValue;
  if ('timestampValue' in v) return v.timestampValue;
  if ('arrayValue' in v) return (v.arrayValue.values ?? []).map(dec);
  if ('mapValue' in v) return Object.fromEntries(Object.entries(v.mapValue.fields ?? {}).map(([k, x]) => [k, dec(x)]));
  return undefined;
}

// ---- run records ----
export function runFile(run) {
  if (!/^[a-z0-9]{6,20}$/.test(run)) throw new Error('run id: 6-20 lowercase letters/digits');
  return path.join(runDir, `${run}.json`);
}
export function readRun(run) {
  return JSON.parse(fs.readFileSync(runFile(run), 'utf8'));
}
function writeRun(run, record) {
  fs.mkdirSync(runDir, { recursive: true });
  fs.writeFileSync(runFile(run), JSON.stringify(record, null, 2), { mode: 0o600 });
}
const emailOf = (run, role) => `lm-e2e-${run}-${role}@londonmystery.test`;

/// A path a run may read or clean: under one of its uids only.
export function ownedPath(record, p) {
  const uids = record.accounts.map((a) => a.uid);
  const [col, id] = p.split('/');
  return ['users', 'consents', 'deletions'].includes(col) && uids.includes(id) && !p.includes('..');
}

// ---- reads ----
export async function getDoc(p) {
  const r = await call('GET', `${FS}/${p}`);
  if (r.status === 404) return null;
  if (r.status !== 200) throw new Error(`read ${p}: ${r.status}`);
  return Object.fromEntries(Object.entries(r.json.fields ?? {}).map(([k, v]) => [k, dec(v)]));
}

async function collectionIds(docPath) {
  const url = docPath ? `${FS}/${docPath}:listCollectionIds` : `${FS}:listCollectionIds`;
  const r = await call('POST', url, { pageSize: 100 });
  if (r.status !== 200) throw new Error(`collections of ${docPath || 'root'}: ${r.status}`);
  return r.json.collectionIds ?? [];
}

async function docIds(collectionPath) {
  const ids = [];
  let pageToken;
  do {
    const q = new URLSearchParams({ pageSize: '300', showMissing: 'true' });
    if (pageToken) q.set('pageToken', pageToken);
    const r = await call('GET', `${FS}/${collectionPath}?${q}`);
    if (r.status !== 200) throw new Error(`list ${collectionPath}: ${r.status}`);
    for (const d of r.json.documents ?? []) ids.push(d.name.split('/').pop());
    pageToken = r.json.nextPageToken;
  } while (pageToken);
  return ids;
}

/// Every document path under docPath (itself included if it exists).
async function tree(docPath) {
  const out = [];
  if (await getDoc(docPath)) out.push(docPath);
  for (const c of await collectionIds(docPath)) {
    for (const id of await docIds(`${docPath}/${c}`)) out.push(...(await tree(`${docPath}/${c}/${id}`)));
  }
  return [...new Set(out)];
}

// ---- commands ----
export async function inspect() {
  await checkProject();
  const release = await call('GET', `https://firebaserules.googleapis.com/v1/projects/${PROJECT}/releases/cloud.firestore`);
  let deployed = null;
  if (release.status === 200) {
    const rs = await call('GET', `https://firebaserules.googleapis.com/v1/${release.json.rulesetName}`);
    deployed = rs.json.source?.files?.map((f) => f.content).join('\n') ?? '';
  }
  const users = await call('POST', `${IDT}/accounts:query`, { returnUserInfo: false });
  const roots = await collectionIds('');
  const counts = {};
  for (const c of roots) counts[c] = (await docIds(c)).length;
  return {
    project: PROJECT,
    rulesRelease: release.status === 200 ? { ruleset: release.json.rulesetName, updated: release.json.updateTime } : `none (${release.status})`,
    deployedRules: deployed,
    authUsers: users.status === 200 ? Number(users.json.recordsCount ?? 0) : `unknown (${users.status})`,
    firestoreRootCollections: counts,
  };
}

export async function seed(run, roles = ['a', 'b'], purpose = 'Phase 4.3B-2 two-device DEV sync E2E (test accounts only)') {
  await checkProject();
  if (fs.existsSync(runFile(run))) throw new Error(`run ${run} exists`);
  const record = { run, project: PROJECT, purpose, createdAt: new Date().toISOString(), accounts: [] };
  writeRun(run, record); // recorded before anything is made
  for (const role of roles) {
    const email = emailOf(run, role);
    const password = randomBytes(12).toString('base64url');
    const r = await call('POST', `${IDT}/accounts`, { email, password, emailVerified: false });
    if (r.status !== 200 || !r.json.localId) throw new Error(`create ${email}: ${r.status} ${r.json.error?.message ?? ''}`);
    const uid = r.json.localId;
    record.accounts.push({ role, uid, email, password, createdAt: new Date().toISOString(), paths: [`users/${uid}/**`, `consents/${uid}`] });
    writeRun(run, record);
    // The consent record, as a trusted backend would write it; only for this
    // new test uid, and only if none exists (never changes a record).
    const c = await call('PATCH', `${FS}/consents/${uid}?currentDocument.exists=false`, {
      fields: { status: enc('confirmed'), schema: enc(1), testRun: enc(run), seededAt: enc(new Date()) },
    });
    if (c.status !== 200) throw new Error(`consent ${uid}: ${c.status}`);
    record.accounts.at(-1).consentSeededAt = new Date().toISOString();
    writeRun(run, record);
  }
  return record;
}

/// Sets a test account's consent (e.g. 'revoked' then 'confirmed' again).
export async function setConsent(record, uid, status) {
  if (!ownedPath(record, `consents/${uid}`)) throw new Error('not a test uid of this run');
  const r = await call('PATCH', `${FS}/consents/${uid}?currentDocument.exists=true`, {
    fields: { status: enc(status), schema: enc(1), testRun: enc(record.run), seededAt: enc(new Date()) },
  });
  if (r.status !== 200) throw new Error(`consent ${uid}: ${r.status}`);
}

/// The documents and accounts of the run that still exist.
export async function leftovers(run) {
  await checkProject();
  const record = readRun(run);
  const docs = [];
  for (const a of record.accounts) {
    docs.push(...(await tree(`users/${a.uid}`)));
    for (const p of [`consents/${a.uid}`, `deletions/${a.uid}`]) if (await getDoc(p)) docs.push(p);
  }
  const ids = record.accounts.map((a) => a.uid);
  const look = ids.length ? await call('POST', `${IDT}/accounts:lookup`, { localId: ids }) : { status: 200, json: {} };
  // An unanswered lookup is not "no accounts".
  if (look.status !== 200) throw new Error(`account lookup: ${look.status}`);
  return { docs, accounts: (look.json.users ?? []).map((u) => ({ uid: u.localId, email: u.email })) };
}

export async function cleanup(run) {
  await checkProject();
  const record = readRun(run);
  const left = await leftovers(run);
  // Only this run's paths and accounts (checked again one by one).
  for (const p of left.docs) {
    if (!ownedPath(record, p)) throw new Error(`refused: ${p}`);
  }
  for (const a of left.accounts) {
    const mine = record.accounts.find((x) => x.uid === a.uid);
    if (!mine || a.email !== mine.email || !a.email.startsWith(`lm-e2e-${run}-`)) throw new Error(`refused account ${a.uid}`);
  }
  const deleted = [];
  for (const p of left.docs.sort((x, y) => y.split('/').length - x.split('/').length)) {
    const r = await call('DELETE', `${FS}/${p}`);
    if (r.status !== 200) throw new Error(`delete ${p}: ${r.status}`);
    deleted.push(p);
  }
  for (const a of left.accounts) {
    const r = await call('POST', `${IDT}/accounts:delete`, { localId: a.uid });
    if (r.status !== 200) throw new Error(`delete account ${a.uid}: ${r.status}`);
  }
  const after = await leftovers(run);
  if (after.docs.length || after.accounts.length) {
    throw new Error(`cleanup incomplete: ${after.docs.length} documents, ${after.accounts.length} accounts left`);
  }
  record.cleanedAt = new Date().toISOString();
  record.cleanedDocs = deleted.length;
  record.cleanedAccounts = left.accounts.map((a) => a.uid);
  writeRun(run, record);
  return { deletedDocs: deleted, deletedAccounts: record.cleanedAccounts, after };
}

/// The DEV Auth users, read only: id, email, when made and last signed in,
/// providers. Nothing secret (no password hashes or tokens are asked for).
export async function users() {
  await checkProject();
  const r = await call('POST', `${IDT}/accounts:query`, { returnUserInfo: true, limit: 100 });
  if (r.status !== 200) throw new Error(`users: ${r.status}`);
  return (r.json.userInfo ?? []).map((u) => ({
    uid: u.localId,
    email: u.email ?? null,
    createdAt: u.createdAt ? new Date(Number(u.createdAt)).toISOString() : null,
    lastLoginAt: u.lastLoginAt ? new Date(Number(u.lastLoginAt)).toISOString() : null,
    providers: (u.providerUserInfo ?? []).map((p) => p.providerId),
  }));
}

// ---- CLI ----
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [cmd, run] = process.argv.slice(2);
  if (process.argv.some((a) => a.startsWith('--project'))) throw new Error('no project argument: DEV only');
  const show = (x) => console.log(JSON.stringify(x, (k, v) => (k === 'password' ? '***' : v), 2));
  const out =
    cmd === 'inspect' ? await inspect()
    : cmd === 'users' ? await users()
    : cmd === 'seed' ? await seed(run)
    : cmd === 'cleanup' ? await cleanup(run)
    : cmd === 'leftovers' ? await leftovers(run)
    : (() => { throw new Error('inspect | users | seed <run> | cleanup <run> | leftovers <run>'); })();
  show(out);
}
