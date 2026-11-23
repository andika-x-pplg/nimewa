const { getItemMetadata } = require('./archive_util');
const { download } = require('./downloader');
const fs = require('fs');

async function inspectBleachComplete() {
  const meta = await getItemMetadata('bleach-complete');
  console.log('Title:', meta.metadata.title);
  console.log('Description:', (meta.metadata.description||'').slice(0, 300));
  
  const thumbs = meta.files.filter(f => f.name.includes('.thumbs') && f.name.includes('S01E01') && f.name.endsWith('.jpg'));
  console.log('S01E01 thumbs:', thumbs.map(t => t.name));
  for (let i = 0; i < thumbs.length; i++) {
    const t = thumbs[i];
    const url = `https://archive.org/download/bleach-complete/${encodeURIComponent(t.name)}`;
    await download(url, `scratch/bleach_comp_thumb_${i}.jpg`);
    console.log(`Downloaded ${t.name} -> scratch/bleach_comp_thumb_${i}.jpg (${fs.statSync(`scratch/bleach_comp_thumb_${i}.jpg`).size} bytes)`);
  }
}

inspectBleachComplete().catch(console.error);

