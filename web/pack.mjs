import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve('.');
const dist = path.join(root, 'dist');

fs.rmSync(dist, { recursive: true, force: true });
fs.mkdirSync(dist, { recursive: true });

const files = ['404.html', 'styles.css', 'app.js', 'sitemap.xml', 'robots.txt', '_headers', '_redirects', 'index.html'];
const dirs = ['check', 'articulos', 'estado', 'privacidad', 'quien-esta-detras', 'aviso-legal', 'assets'];

for (const file of files) {
  const from = path.join(root, file);
  if (fs.existsSync(from)) fs.copyFileSync(from, path.join(dist, file));
}
for (const dir of dirs) {
  const from = path.join(root, dir);
  if (fs.existsSync(from)) fs.cpSync(from, path.join(dist, dir), { recursive: true });
}

console.log('dist listo para arrastrar a Cloudflare Pages');
