import sharp from 'sharp';
import fs from 'node:fs';

const src =
  process.argv[2] ??
  'C:/Users/João/.cursor/projects/c-Users-Jo-o-Desktop-Cristalins/assets/logo-c314ac92-a9a5-4ed6-be5a-b850794f799e.png';
const out = process.argv[3] ?? 'app/assets/images/brand/logo.png';

const thr = 28; // near-black → alpha 0

const { data, info } = await sharp(src).ensureAlpha().raw().toBuffer({ resolveWithObject: true });

for (let i = 0; i < data.length; i += 4) {
  const r = data[i];
  const g = data[i + 1];
  const b = data[i + 2];
  if (r <= thr && g <= thr && b <= thr) {
    data[i + 3] = 0;
  }
}

const tmp = `${out}.tmp`;
await sharp(data, { raw: { width: info.width, height: info.height, channels: 4 } })
  .png()
  .toFile(tmp);
fs.renameSync(tmp, out);

const m = await sharp(out).metadata();
console.log(`ok ${m.width}x${m.height} alpha=${m.hasAlpha} bytes=${m.size}`);
