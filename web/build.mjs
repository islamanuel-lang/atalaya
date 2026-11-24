import 'dotenv/config';
import fs from 'node:fs';
import path from 'node:path';
import { marked } from 'marked';

const ROOT = path.resolve('..');
const HERE = path.resolve('.');
const CONTENT = path.join(ROOT, 'content');

const API_BASE = process.env.API_BASE || 'http://localhost:8787';
const SITE_URL = (process.env.SITE_URL || 'http://localhost:5173').replace(/\/$/, '');
const TESTFLIGHT = process.env.TESTFLIGHT_URL || 'https://testflight.apple.com/join/REEMPLAZA';
const APK = process.env.APK_URL || '/semencheck.apk';
const TELEGRAM = process.env.TELEGRAM_URL || 'https://t.me/semencheck';

marked.setOptions({ gfm: true, breaks: false });

function frontmatter(source) {
  if (!source.startsWith('---')) return { data: {}, body: source };
  const end = source.indexOf('\n---', 3);
  if (end === -1) return { data: {}, body: source };
  const raw = source.slice(3, end).trim().split('\n');
  const data = {};
  for (const line of raw) {
    const i = line.indexOf(':');
    if (i > 0) data[line.slice(0, i).trim()] = line.slice(i + 1).trim();
  }
  return { data, body: source.slice(end + 4).trim() };
}

function layout({ title, description, body, canonical, kind = 'page' }) {
  const nav = `
    <header class="bar">
      <a class="brand" href="/"><img src="/assets/mark.svg" alt="" width="22" height="22"><span>semencheck</span></a>
      <nav class="nav">
        <a href="/check">Comprobar</a>
        <a class="opt" href="/articulos/">Artículos</a>
        <a class="opt" href="/estado">Estado</a>
        <a class="opt" href="/defensa">Defensa</a>
        <a class="opt" href="/quien-esta-detras">Quiénes somos</a>
        <a class="opt" href="${TELEGRAM}" target="_blank" rel="noopener">Canal</a>
        <a class="cta" href="/check">Comprobar gratis</a>
      </nav>
    </header>`;
  const footer = `
    <footer class="foot">
      <div>
        <strong>SemenCheck</strong> · proyecto independiente de seguridad para iPhone.<br>
        <span class="mute">No es una wallet, no custodia fondos, no firma nada.</span>
      </div>
      <div class="links">
        <a href="/defensa">Defensa en línea</a>
        <a href="/quien-esta-detras">Quiénes somos</a>
        <a href="/privacidad">Privacidad</a>
        <a href="/aviso-legal">Aviso legal</a>
        <a href="${TELEGRAM}" target="_blank" rel="noopener">Telegram</a>
        <a href="mailto:hola@semencheck.es">hola@semencheck.es</a>
      </div>
    </footer>`;
  return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title>
<meta name="description" content="${esc(description || '')}">
${canonical ? `<link rel="canonical" href="${SITE_URL}${canonical}">` : ''}
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(description || '')}">
<meta property="og:image" content="${SITE_URL}/assets/og.png">
<meta property="og:type" content="${kind === 'article' ? 'article' : 'website'}">
<meta name="theme-color" content="#0A0E12">
<link rel="icon" href="/assets/favicon.png" sizes="64x64">
<link rel="apple-touch-icon" href="/assets/apple-touch-icon.png">
<link rel="preload" href="/assets/fonts/space-grotesk.ttf" as="font" type="font/ttf" crossorigin>
<link rel="stylesheet" href="/styles.css">
</head>
<body>
${nav}
<main class="wrap">${body}</main>
${footer}
<script src="/app.js" defer></script>
</body>
</html>`;
}

function esc(value) {
  return String(value || '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
}

function writeRoute(route, html) {
  const clean = route.replace(/^\//, '').replace(/\/$/, '');
  const dir = clean ? path.join(HERE, clean) : HERE;
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'index.html'), html);
  return dir;
}

function renderPage(file) {
  const { data, body } = frontmatter(fs.readFileSync(file, 'utf8'));
  const slug = data.slug || path.basename(file, '.md');
  const html = marked.parse(body);
  const out = layout({
    title: `${data.title} · SemenCheck`,
    description: data.description,
    body: `<article class="prose"><p class="eyebrow">${esc((data.tag || 'SemenCheck').toUpperCase())}</p>${html}</article>`,
    canonical: `/${slug}`,
    kind: data.kind === 'article' ? 'article' : 'page'
  });
  writeRoute(`/${slug}`, out);
  return { slug, data };
}

fs.mkdirSync(path.join(HERE, 'articulos'), { recursive: true });

const articles = [];
for (const name of fs.readdirSync(path.join(CONTENT, 'articles'))) {
  if (!name.endsWith('.md')) continue;
  const src = path.join(CONTENT, 'articles', name);
  const { data, body } = frontmatter(fs.readFileSync(src, 'utf8'));
  const slug = data.slug || path.basename(name, '.md');
  const excerpt = marked.parse(body).replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 160);
  articles.push({
    slug,
    title: data.title,
    date: data.date,
    tag: data.tag,
    description: data.description || excerpt
  });
  const out = layout({
    title: `${data.title} · SemenCheck`,
    description: data.description || excerpt,
    body: `<article class="prose">
      <p class="eyebrow">${esc((data.tag || '').toUpperCase())} · ${esc(data.date || '')}</p>
      ${marked.parse(body)}
      <div class="callout">
        <p>Comprueba tu propia exposición en menos de un minuto.</p>
        <a class="btn" href="/check">Comprobar gratis</a>
      </div>
    </article>`,
    canonical: `/articulos/${slug}`,
    kind: 'article'
  });
  fs.writeFileSync(path.join(HERE, 'articulos', `${slug}.html`), out);
  writeRoute(`/articulos/${slug}`, out);
}

for (const name of fs.readdirSync(path.join(CONTENT, 'legal'))) {
  if (!name.endsWith('.md')) continue;
  renderPage(path.join(CONTENT, 'legal', name));
}

articles.sort((a, b) => (b.date || '').localeCompare(a.date || ''));
const list = articles.map((a) => `
  <li>
    <a href="/articulos/${a.slug}">
      <span class="eyebrow">${esc((a.tag || '').toUpperCase())} · ${esc(a.date || '')}</span>
      <strong>${esc(a.title)}</strong>
      <span class="mute">${esc(a.description)}</span>
    </a>
  </li>`).join('');

fs.writeFileSync(path.join(HERE, 'articulos', 'index.html'), layout({
  title: 'Artículos · SemenCheck',
  description: 'Guías y avisos sobre semillas filtradas, drenadores y el fallo de sandbox de iOS.',
  body: `<p class="eyebrow">BIBLIOTECA</p><h1>Artículos</h1><ul class="list">${list}</ul>`,
  canonical: '/articulos/'
}));

// index y check llevan marcadores
const cards = articles.slice(0, 3).map((a) => `
  <a class="card" href="/articulos/${a.slug}">
    <span class="eyebrow">${esc((a.tag || '').toUpperCase())}</span>
    <strong>${esc(a.title)}</strong>
    <span class="mute">${esc(a.description)}</span>
  </a>`).join('');

function substitute(source) {
  return source
    .replaceAll('__API_BASE__', API_BASE)
    .replaceAll('__TESTFLIGHT__', TESTFLIGHT)
    .replaceAll('__APK__', APK)
    .replaceAll('__SITE__', SITE_URL)
    .replaceAll('__TELEGRAM__', TELEGRAM)
    .replace('<!--ARTICLES-->', cards);
}

for (const name of ['index', 'check']) {
  const src = path.join(HERE, 'src', `${name}.html`);
  if (fs.existsSync(src)) {
    const rendered = substitute(fs.readFileSync(src, 'utf8'));
    if (name === 'index') fs.writeFileSync(path.join(HERE, 'index.html'), rendered);
    else writeRoute(`/${name}`, rendered);
  }
}

const scriptSrc = path.join(HERE, 'src', 'app.js');
if (fs.existsSync(scriptSrc)) {
  fs.writeFileSync(path.join(HERE, 'app.js'), substitute(fs.readFileSync(scriptSrc, 'utf8')));
}

// Wordlist para validar en cliente
const wordlist = path.join(ROOT, 'ios', 'SemenCheck', 'Resources', 'bip39-english.txt');
if (fs.existsSync(wordlist)) fs.copyFileSync(wordlist, path.join(HERE, 'assets', 'bip39.txt'));

// Sitemap y robots
const urls = ['/', '/check', '/articulos/', '/estado', '/defensa', '/quien-esta-detras', '/privacidad', '/aviso-legal',
  ...articles.map((a) => `/articulos/${a.slug}`)];
fs.writeFileSync(path.join(HERE, 'sitemap.xml'),
  `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls.map((u) => `  <url><loc>${SITE_URL}${u}</loc></url>`).join('\n')}\n</urlset>\n`);
fs.writeFileSync(path.join(HERE, 'robots.txt'), `User-agent: *\nAllow: /\nSitemap: ${SITE_URL}/sitemap.xml\n`);

console.log(`Web generada: ${articles.length} artículos y ${fs.readdirSync(path.join(CONTENT, 'legal')).length} legales`);
