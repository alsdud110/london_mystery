// Phase 4.3B-2: the two-device sync test on the REAL DEV project, two
// dedicated Android emulators (London_Mystery_DEV on 5560 = A,
// London_Mystery_DEV_B on 5562 = B). Never PROD.
//
//   node scripts/dev_two_device_e2e.mjs [--keep] [--test <integration test>] [--ios <simulator udid>]
//
// --test: the device test (default: the 4.3B-2 sync test; Phase 4.4 uses
// integration_test/sync_dev_restore_test.dart). --ios: after A and B passed,
// role C runs on that iOS simulator — only the dedicated, booted
// London_Mystery_DEV_iOS (no network switch there).
//
// 1. Records a run, makes its test accounts and their consent (dev_admin.mjs).
// 2. Serves the devices on 127.0.0.1:8787 (10.0.2.2:8787 from an emulator):
//    the run's test accounts, barriers between the devices, admin reads of
//    the run's own documents, the devices' network switch (adb), results.
// 3. Runs integration_test/sync_dev_two_device_test.dart on A, then on B.
// 4. All passed: stops the sync, deletes the run's documents and accounts,
//    checks nothing is left. Anything failed: stops both and keeps the data
//    for a look (nothing deleted), unless cleanup is asked for separately.
import { spawn, execFileSync } from 'node:child_process';
import http from 'node:http';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { PROJECT, checkProject, seed, readRun, getDoc, ownedPath, cleanup, leftovers, runFile } from './dev_admin.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '..', '..');
const adb = path.join(process.env.HOME, 'Library/Android/sdk/platform-tools/adb');
const devices = { A: 'emulator-5560', B: 'emulator-5562' };
const PORT = 8787;
const arg = (name) => {
  const i = process.argv.indexOf(name);
  return i < 0 ? null : process.argv[i + 1];
};
const testFile = arg('--test') ?? 'integration_test/sync_dev_two_device_test.dart';
if (!/^integration_test\/sync_dev_[a-z_]+_test\.dart$/.test(testFile) || !fs.existsSync(path.join(path.dirname(fileURLToPath(import.meta.url)), '..', '..', testFile))) {
  throw new Error(`refused: --test ${testFile} is not a DEV sync device test`);
}
const iosDevice = arg('--ios');
// The iOS target is wiped (the test clears the DEV app's saves): only the
// dedicated, booted simulator of this project, checked by name with simctl
// before anything (accounts, builds) is made. A device or any other
// simulator is refused.
const iosSimulator = 'London_Mystery_DEV_iOS';
if (iosDevice !== null) {
  if (!/^[0-9A-F-]{36}$/.test(iosDevice)) throw new Error('refused: --ios takes a simulator UDID');
  const sims = JSON.parse(execFileSync('xcrun', ['simctl', 'list', 'devices', '-j'], { timeout: 60_000 }).toString());
  const sim = Object.values(sims.devices).flat().find((d) => d.udid === iosDevice);
  if (!sim) throw new Error(`refused: ${iosDevice} is not a simulator on this Mac`);
  if (sim.name !== iosSimulator) throw new Error(`refused: ${iosDevice} is "${sim.name}", not the dedicated ${iosSimulator}`);
  if (sim.state !== 'Booted') throw new Error(`refused: ${iosSimulator} is ${sim.state}, not booted`);
}

// Only the two dedicated emulators of this project, checked by AVD name
// before anything (accounts, network, app data) is touched.
const avds = { A: 'London_Mystery_DEV', B: 'London_Mystery_DEV_B' };
for (const [role, serial] of Object.entries(devices)) {
  let name = '';
  try {
    name = execFileSync(adb, ['-s', serial, 'emu', 'avd', 'name'], { timeout: 60_000 }).toString().split(/\r?\n/)[0].trim();
  } catch (e) {
    throw new Error(`${serial}: not reachable (${e.message})`);
  }
  if (name !== avds[role]) throw new Error(`refused: ${serial} is "${name}", not the dedicated ${avds[role]}`);
}

// A stable host and devices before anything is made in DEV (Phase 4.5-5): the
// Mac's load under 25, and each device answering adb three times in a row
// within 15 s. Otherwise the run stops here with no accounts made.
const load = os.loadavg()[0];
if (load >= 25) throw new Error(`refused: host load ${load.toFixed(1)} (needs < 25); nothing made in DEV`);
for (const [role, serial] of Object.entries(devices)) {
  for (let i = 0; i < 3; i++) {
    try {
      const out = execFileSync(adb, ['-s', serial, 'shell', 'echo ok'], { timeout: 15_000 }).toString().trim();
      if (out !== 'ok') throw new Error(out);
    } catch (e) {
      throw new Error(`refused: ${serial} (${role}) does not answer adb steadily (${e.code ?? e.message}); nothing made in DEV`);
    }
  }
}

// Both networks on before anything is made in DEV: a device that cannot
// do even this stops the run with no accounts made.
for (const d of Object.keys(devices)) setNetwork(d, true);

await checkProject();
const run = `r${Date.now().toString(36)}`;
const record = await seed(run, ['a', 'b'], `${path.basename(testFile)} on the real DEV project (test accounts only)`);
const results = [];
const signals = new Map();
const waiters = new Map();
console.log(`run ${run}: accounts ${record.accounts.map((a) => `${a.role}=${a.uid}`).join(', ')} (record ${runFile(run)})`);

function signal(name, value = true) {
  signals.set(name, value);
  for (const w of waiters.get(name) ?? []) w(value);
  waiters.delete(name);
}

function setNetwork(device, on) {
  const serial = devices[device];
  if (!serial) throw new Error('device');
  const s = on ? 'enable' : 'disable';
  execFileSync(adb, ['-s', serial, 'shell', `svc wifi ${s}; svc data ${s}`], { timeout: 30_000 });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${PORT}`);
  const send = (status, body) => {
    res.writeHead(status, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(body));
  };
  try {
    const q = Object.fromEntries(url.searchParams);
    if (url.pathname === '/ping') return send(200, { ok: true });
    if (url.pathname === '/config') {
      return send(200, { run, project: PROJECT, accounts: readRun(run).accounts.map(({ role, uid, email, password }) => ({ role, uid, email, password })) });
    }
    if (url.pathname === '/signal' && req.method === 'POST') {
      const body = await new Promise((ok) => {
        let b = '';
        req.on('data', (c) => (b += c));
        req.on('end', () => ok(b));
      });
      signal(q.name, body ? JSON.parse(body) : true);
      if (q.name === 'abort') stopAll(`abort from a device: ${body}`);
      return send(200, { ok: true });
    }
    if (url.pathname === '/wait') {
      const timeout = Math.min(Number(q.timeout ?? 120000), 600000);
      if (signals.has('abort')) return send(409, { abort: signals.get('abort') });
      if (signals.has(q.name)) return send(200, { value: signals.get(q.name) });
      const value = await new Promise((ok) => {
        const t = setTimeout(() => ok(undefined), timeout);
        const done = (v) => { clearTimeout(t); ok(v); };
        waiters.set(q.name, [...(waiters.get(q.name) ?? []), done]);
        waiters.set('abort', [...(waiters.get('abort') ?? []), done]);
      });
      if (signals.has('abort')) return send(409, { abort: signals.get('abort') });
      return value === undefined ? send(408, { timeout: true }) : send(200, { value });
    }
    if (url.pathname === '/doc') {
      if (!ownedPath(readRun(run), q.path)) return send(403, { refused: q.path });
      return send(200, { doc: await getDoc(q.path) });
    }
    if (url.pathname === '/net' && req.method === 'POST') {
      // Off now; back on by itself after `seconds` (the device cannot ask
      // while it has no network).
      if (!devices[q.device]) return send(400, { device: q.device });
      // The answer goes out first; the network goes off a moment later (the
      // device would otherwise lose the answer itself).
      send(200, { off: q.device });
      setTimeout(() => { try { setNetwork(q.device, false); } catch (e) { console.error(e); } }, 1500);
      setTimeout(() => { try { setNetwork(q.device, true); signal(`net-${q.device}-back`); } catch (e) { console.error(e); } }, 1500 + Number(q.seconds ?? 45) * 1000);
      return;
    }
    if (url.pathname === '/result' && req.method === 'POST') {
      let b = '';
      req.on('data', (c) => (b += c));
      await new Promise((ok) => req.on('end', ok));
      const r = JSON.parse(b);
      results.push({ at: new Date().toISOString(), ...r });
      console.log(`[${r.device}] ${r.ok ? 'PASS' : 'FAIL'} ${r.scenario}: ${r.observed}`);
      return send(200, { ok: true });
    }
    send(404, {});
  } catch (e) {
    send(500, { error: String(e.message ?? e) });
  }
});
await new Promise((ok) => server.listen(PORT, '127.0.0.1', ok));

const procs = {};
let stopped = null;
function stopAll(why) {
  if (stopped) return;
  stopped = why;
  console.error(`STOP: ${why}`);
  for (const p of Object.values(procs)) p.kill('SIGTERM');
}

function runDevice(role) {
  const log = fs.createWriteStream(path.join(repo, 'build', 'dev-e2e', `${run}-${role}.log`));
  const ios = role === 'C';
  const p = spawn('flutter', [
    'test', testFile, '--flavor', 'dev',
    '--dart-define=LM_CLOUD_SYNC=dev', `--dart-define=LM_E2E_ROLE=${role}`,
    `--dart-define=LM_E2E_HOST=${ios ? '127.0.0.1' : '10.0.2.2'}:${PORT}`,
    '-d', ios ? iosDevice : devices[role],
  ], { cwd: repo, env: { ...process.env, PATH: `${path.dirname(adb)}:${process.env.PATH}` } });
  p.stdout.pipe(log);
  p.stderr.pipe(log);
  procs[role] = p;
  return new Promise((ok) => p.on('exit', (code) => ok(code)));
}

// (Both networks were turned on before seeding.)
const a = runDevice('A');
// B builds once A's app is up (one build at a time).
const ready = await new Promise((ok) => {
  if (signals.has('A-ready')) return ok(true);
  waiters.set('A-ready', [() => ok(true)]);
  a.then(() => ok(false));
});
const b = ready ? runDevice('B') : Promise.resolve(-1);
const [codeA, codeB] = await Promise.all([a, b]);
if (codeA !== 0 || codeB !== 0) stopAll(`exit A=${codeA} B=${codeB}`);
// The iOS simulator after both (reads the signals they left).
const codeC = iosDevice && !stopped ? await runDevice('C') : null;
if (codeC !== null && codeC !== 0) stopAll(`exit C=${codeC}`);
// Networks back on; a device that does not answer is reported, and the
// record and cleanup below still happen.
const netProblems = [];
for (const d of Object.keys(devices)) {
  try {
    setNetwork(d, true);
  } catch (e) {
    netProblems.push(`${devices[d]}: ${e.code ?? e.message}`);
  }
}
if (netProblems.length) console.error(`network not restored on: ${netProblems.join(', ')} (turn it on by hand)`);
server.close();

const final = readRun(run);
final.results = results;
final.exit = { A: codeA, B: codeB, ...(codeC === null ? {} : { C: codeC }) };
final.stopped = stopped;
fs.writeFileSync(runFile(run), JSON.stringify(final, null, 2), { mode: 0o600 });

let leftOver = false;
if (!stopped && !process.argv.includes('--keep')) {
  const c = await cleanup(run);
  leftOver = c.after.docs.length > 0 || c.after.accounts.length > 0;
  console.log(`cleanup: ${c.deletedDocs.length} documents, ${c.deletedAccounts.length} accounts deleted; left: ${c.after.docs.length} documents, ${c.after.accounts.length} accounts`);
} else {
  const l = await leftovers(run);
  console.log(`kept for a look: ${l.docs.length} documents, ${l.accounts.length} accounts (node scripts/dev_admin.mjs cleanup ${run})`);
}
console.log(`results: ${results.filter((r) => r.ok).length} passed, ${results.filter((r) => !r.ok).length} failed; exit A=${codeA} B=${codeB}${codeC === null ? '' : ` C=${codeC}`}`);
if (leftOver) console.error('cleanup left test data behind: see leftovers');
process.exit(stopped || leftOver ? 1 : 0);
