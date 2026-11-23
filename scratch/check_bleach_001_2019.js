const { getItemMetadata } = require('./archive_util');
const { download } = require('./downloader');
const fs = require('fs');

async function checkBleach001() {
  const meta = await getItemMetadata('bleach001_20190808');
  console.log('Title:', meta.metadata ? meta.metadata.title : '');
  console.log('Description:', meta.metadata ? meta.metadata.description : '');

  const thumbs = meta.files ? meta.files.filter(f => f.name.includes('.thumbs') && f.name.includes('001') && f.name.endsWith('.jpg')) : [];
  console.log('Thumbs count for 001:', thumbs.length);
  for (const t of thumbs) {
    console.log(`  ${t.name}`);
  }

  if (thumbs.length > 0) {
    const chosen = thumbs[Math.floor(thumbs.length / 2)];
    const url = `https://archive.org/download/bleach001_20190808/${encodeURIComponent(chosen.name)}`;
    console.log('Downloading thumb:', url);
    await download(url, 'scratch/bleach_001_thumb.jpg');
    console.log('Downloaded size:', fs.statSync('scratch/bleach_001_thumb.jpg').size);
  }
}

checkBleach001();

