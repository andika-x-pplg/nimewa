const { getItemMetadata } = require('./archive_util');
const { download } = require('./downloader');
const fs = require('fs');

async function inspectHorribleHxh() {
  const meta = await getItemMetadata('horrible-subs-hunter-x-hunter-135-480p');
  console.log('Metadata title:', meta.metadata.title);
  console.log('Metadata description:', meta.metadata.description);

  const thumbs = meta.files.filter(f => f.name.includes('.thumbs') && f.name.endsWith('.jpg'));
  console.log(`Found ${thumbs.length} thumbs`);
  for (const t of thumbs.slice(0, 10)) {
    console.log(`  ${t.name}`);
  }

  // Download a thumb for episode 1
  const ep1Thumbs = thumbs.filter(t => t.name.includes('01 [480p]'));
  console.log('Ep 1 thumbs:', ep1Thumbs.map(t => t.name));
  if (ep1Thumbs.length > 2) {
    const thumbUrl = `https://archive.org/download/horrible-subs-hunter-x-hunter-135-480p/${encodeURIComponent(ep1Thumbs[2].name)}`;
    console.log('Downloading thumb:', thumbUrl);
    await download(thumbUrl, 'scratch/hxh_horrible_thumb.jpg');
    console.log('Downloaded scratch/hxh_horrible_thumb.jpg size:', fs.statSync('scratch/hxh_horrible_thumb.jpg').size);
  }

  // Check total mp4 files and list some
  const mp4s = meta.files.filter(f => f.name.endsWith('.mp4') && !f.name.includes('.thumbs'));
  console.log(`Total MP4s: ${mp4s.length}`);
  console.log('First 5:', mp4s.slice(0, 5).map(f => f.name));
  console.log('Last 5:', mp4s.slice(-5).map(f => f.name));
}

inspectHorribleHxh();

