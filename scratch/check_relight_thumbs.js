const { getItemMetadata } = require('./archive_util');
const { download } = require('./downloader');
const fs = require('fs');

async function checkRelightThumbs() {
  const meta = await getItemMetadata('death-note-relight-1');
  const thumbs = meta.files ? meta.files.filter(f => f.name.includes('.thumbs') && f.name.endsWith('.jpg')) : [];
  console.log(`death-note-relight-1 has ${thumbs.length} thumbs`);
  for (const t of thumbs.slice(0, 10)) {
    console.log(`  ${t.name}`);
  }

  const ep1Thumbs = thumbs.filter(t => t.name.includes('Episode 1 Rebirth'));
  console.log('Ep 1 thumbs:', ep1Thumbs.map(t => t.name));
  if (ep1Thumbs.length > 0) {
    const chosen = ep1Thumbs[Math.floor(ep1Thumbs.length / 2)];
    const url = `https://archive.org/download/death-note-relight-1/${encodeURIComponent(chosen.name)}`;
    console.log('Downloading thumb:', url);
    await download(url, 'scratch/dn_relight_thumb.jpg');
    console.log('Downloaded size:', fs.statSync('scratch/dn_relight_thumb.jpg').size);
  }
}

checkRelightThumbs();

