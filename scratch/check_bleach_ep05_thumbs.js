const { getItemMetadata } = require('./archive_util');
const { download } = require('./downloader');
const fs = require('fs');

async function checkBleachThumbs() {
  const meta = await getItemMetadata('bleach-episode-05');
  const thumbs = meta.files ? meta.files.filter(f => f.name.includes('.thumbs') && f.name.includes('Episode 01') && f.name.endsWith('.jpg')) : [];
  console.log('Thumbs count for Ep 01:', thumbs.length);
  for (const t of thumbs) {
    console.log(`  ${t.name}`);
  }

  if (thumbs.length > 0) {
    const chosen = thumbs[Math.floor(thumbs.length / 2)];
    const url = `https://archive.org/download/bleach-episode-05/${encodeURIComponent(chosen.name)}`;
    console.log('Downloading thumb:', url);
    await download(url, 'scratch/bleach_ep05_thumb.jpg');
    console.log('Downloaded size:', fs.statSync('scratch/bleach_ep05_thumb.jpg').size);
  }
}

checkBleachThumbs();

