const { getItemMetadata } = require('./archive_util');
const { download } = require('./downloader');
const fs = require('fs');

async function checkThumbs() {
  const meta = await getItemMetadata('death-note-22-guidance');
  const thumbs = meta.files.filter(f => f.name.includes('.thumbs') && f.name.endsWith('.jpg'));
  console.log(`death-note-22-guidance has ${thumbs.length} thumbs`);
  const ep1Thumbs = thumbs.filter(t => t.name.includes('01 - Rebirth'));
  console.log('Ep 1 thumbs:', ep1Thumbs.map(t => t.name));
  for (let i = 0; i < Math.min(3, ep1Thumbs.length); i++) {
    const t = ep1Thumbs[i];
    const url = `https://archive.org/download/death-note-22-guidance/${encodeURIComponent(t.name)}`;
    await download(url, `scratch/dn_thumb_${i}.jpg`);
    console.log(`Downloaded ${t.name} -> scratch/dn_thumb_${i}.jpg (${fs.statSync(`scratch/dn_thumb_${i}.jpg`).size} bytes)`);
  }
}

checkThumbs().catch(console.error);

