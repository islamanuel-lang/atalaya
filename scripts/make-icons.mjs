import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const root = path.resolve('..');
const icon = fs.readFileSync(path.join(root, 'brand', 'icon.svg'));
const mark = fs.readFileSync(path.join(root, 'brand', 'mark.svg'));
const og = fs.readFileSync(path.join(root, 'brand', 'og.svg'));

async function png(svg, size, destination) {
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  await sharp(svg, { density: 384 }).resize(size, size).png().toFile(destination);
  console.log(path.relative(root, destination));
}

await png(icon, 1024, path.join(root, 'ios/SemenCheck/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png'));
await png(icon, 1024, path.join(root, 'brand', 'icon-1024.png'));
await png(icon, 512, path.join(root, 'web/assets/icon-512.png'));
await png(icon, 192, path.join(root, 'web/assets/icon-192.png'));
await png(icon, 180, path.join(root, 'web/assets/apple-touch-icon.png'));
await png(icon, 64, path.join(root, 'web/assets/favicon.png'));

fs.mkdirSync(path.join(root, 'web/assets'), { recursive: true });
fs.copyFileSync(path.join(root, 'brand', 'mark.svg'), path.join(root, 'web/assets/mark.svg'));
fs.copyFileSync(path.join(root, 'brand', 'logo.svg'), path.join(root, 'web/assets/logo.svg'));

await sharp(og, { density: 200 }).resize(1200, 630).png().toFile(path.join(root, 'web/assets/og.png'));
console.log('og.png');
