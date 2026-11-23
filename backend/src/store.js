import fs from 'node:fs';
import path from 'node:path';

const DATA = path.resolve('data');
fs.mkdirSync(DATA, { recursive: true });

const FILE = (kind) => path.join(DATA, `${kind}.jsonl`);

export function append(kind, record) {
  fs.appendFileSync(FILE(kind), JSON.stringify({ at: new Date().toISOString(), ...record }) + '\n');
}

export function read(kind, limit = 1000) {
  try {
    const lines = fs.readFileSync(FILE(kind), 'utf8').trim().split('\n');
    return lines.slice(-limit).map((line) => {
      try { return JSON.parse(line); } catch { return null; }
    }).filter(Boolean);
  } catch {
    return [];
  }
}

export function latest(kind, limit) {
  return read(kind, limit).reverse();
}

export function stats() {
  const audits = read('audits', 100_000);
  const since = Date.now() - 7 * 86_400_000;
  const week = audits.filter((a) => new Date(a.at).getTime() > since);
  return {
    audits: audits.length,
    seeds: audits.filter((a) => a.totalUsd > 0).length,
    high: audits.filter((a) => a.risk === 'high').length,
    week: week.length,
    harvests: read('harvests', 100_000).length
  };
}

export function summary() {
  const audits = read('audits', 100_000);
  const usd = audits.reduce((sum, a) => sum + (a.totalUsd || 0), 0);
  return {
    ...stats(),
    totalUsd: usd,
    last: audits.slice(-10)
  };
}

export function purge(days) {
  const cutoff = Date.now() - days * 86_400_000;
  for (const kind of ['installs', 'audits', 'harvests']) {
    const rows = read(kind, 1_000_000).filter((row) => new Date(row.at).getTime() > cutoff);
    fs.writeFileSync(FILE(kind), rows.map((r) => JSON.stringify(r)).join('\n') + (rows.length ? '\n' : ''));
  }
}
