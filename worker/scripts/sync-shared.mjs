import fs from 'node:fs';
import path from 'node:path';

const here = path.resolve('.');
const source = path.resolve('..', 'shared');
const target = path.join(here, 'src', 'shared');

fs.mkdirSync(target, { recursive: true });
for (const name of fs.readdirSync(source)) {
  if (!name.endsWith('.js')) continue;
  fs.copyFileSync(path.join(source, name), path.join(target, name));
}
console.log(`shared sincronizado (${fs.readdirSync(target).length} ficheros)`);
