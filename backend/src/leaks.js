import fs from 'node:fs';
import path from 'node:path';

const FILE = path.resolve('data/leaks.txt');
let hashes = new Set();

export function loadLeaks() {
  try {
    hashes = new Set(
      fs.readFileSync(FILE, 'utf8')
        .split(/\r?\n/)
        .map((line) => line.trim().toLowerCase())
        .filter((line) => /^[0-9a-f]{64}$/.test(line))
    );
  } catch {
    hashes = new Set();
  }
  return hashes.size;
}

export function checkLeaks(phrase, hash) {
  const found = [];
  const h = hash || null;
  if (h && hashes.has(h)) {
    found.push('Filtración en base interna de semillas');
  }
  return found;
}

export function size() {
  return hashes.size;
}
