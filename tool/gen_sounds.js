// Generates the app's sound effects as small 16-bit mono WAV files.
// Run: node tool/gen_sounds.js
const fs = require('fs');
const path = require('path');
const RATE = 22050;

function tone(freq, dur, { vol = 0.4, type = 'sine', attack = 0.01, release = 0.12 } = {}) {
  const n = Math.floor(RATE * dur);
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / RATE;
    const ph = 2 * Math.PI * freq * t;
    let s = type === 'triangle' ? (2 / Math.PI) * Math.asin(Math.sin(ph)) : Math.sin(ph);
    s += 0.25 * Math.sin(ph * 2); // soft overtone -> bell-ish
    const env = Math.min(1, t / attack) * Math.min(1, (dur - t) / release);
    out[i] = s * vol * Math.max(0, env) * Math.exp(-t * 3);
  }
  return out;
}

function mix(parts) {
  // parts: [{ at: seconds, buf }]
  const len = Math.max(...parts.map(p => Math.floor(p.at * RATE) + p.buf.length));
  const out = new Float32Array(len);
  for (const p of parts) {
    const off = Math.floor(p.at * RATE);
    for (let i = 0; i < p.buf.length; i++) out[off + i] += p.buf[i];
  }
  return out;
}

function writeWav(file, samples) {
  const data = Buffer.alloc(samples.length * 2);
  for (let i = 0; i < samples.length; i++) {
    const v = Math.max(-1, Math.min(1, samples[i]));
    data.writeInt16LE(Math.round(v * 32767), i * 2);
  }
  const h = Buffer.alloc(44);
  h.write('RIFF', 0); h.writeUInt32LE(36 + data.length, 4); h.write('WAVE', 8);
  h.write('fmt ', 12); h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22);
  h.writeUInt32LE(RATE, 24); h.writeUInt32LE(RATE * 2, 28); h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34);
  h.write('data', 36); h.writeUInt32LE(data.length, 40);
  fs.writeFileSync(file, Buffer.concat([h, data]));
}

const dir = path.join(__dirname, '..', 'assets', 'sounds');
fs.mkdirSync(dir, { recursive: true });
const C5 = 523.25, E5 = 659.25, G5 = 783.99, C6 = 1046.5, A4 = 440, F4 = 349.23, D5 = 587.33;

writeWav(path.join(dir, 'tap.wav'), tone(880, 0.06, { vol: 0.25, release: 0.04 }));
writeWav(path.join(dir, 'success.wav'), mix([
  { at: 0, buf: tone(C5, 0.25) }, { at: 0.1, buf: tone(E5, 0.25) },
  { at: 0.2, buf: tone(G5, 0.3) }, { at: 0.3, buf: tone(C6, 0.6) },
]));
writeWav(path.join(dir, 'wrong.wav'), mix([
  { at: 0, buf: tone(A4, 0.18, { type: 'triangle', vol: 0.3 }) },
  { at: 0.16, buf: tone(F4, 0.3, { type: 'triangle', vol: 0.3 }) },
]));
writeWav(path.join(dir, 'clue.wav'), mix([
  { at: 0, buf: tone(G5, 0.15, { vol: 0.3 }) }, { at: 0.07, buf: tone(C6, 0.15, { vol: 0.3 }) },
  { at: 0.14, buf: tone(1318.5, 0.4, { vol: 0.25 }) },
]));
writeWav(path.join(dir, 'unlock.wav'), mix([
  { at: 0, buf: tone(D5, 0.12, { vol: 0.3 }) }, { at: 0.08, buf: tone(G5, 0.35, { vol: 0.3 }) },
]));
writeWav(path.join(dir, 'final.wav'), mix([
  { at: 0, buf: tone(C5, 0.2) }, { at: 0.15, buf: tone(C5, 0.2) }, { at: 0.3, buf: tone(C5, 0.2) },
  { at: 0.45, buf: tone(E5, 0.35) }, { at: 0.7, buf: tone(G5, 0.3) }, { at: 0.9, buf: tone(C6, 0.9) },
  { at: 0.9, buf: tone(E5, 0.9, { vol: 0.2 }) }, { at: 0.9, buf: tone(G5, 0.9, { vol: 0.2 }) },
]));
console.log('sounds written to', dir);
