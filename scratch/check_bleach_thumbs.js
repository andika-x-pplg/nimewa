const { getItemMetadata } = require('./archive_util');
const { download } = require('./downloader');

async function checkBleachThumbs() {
  const meta = await getItemMetadata('bleach-temporada-1');
  if (meta && meta.files) {
    const thumbs = meta.files.filter(f => f.name.includes('.thumbs') && f.name.includes('001') && f.name.endsWith('.jpg'));
    console.log('Bleach 001 thumbs:');
    for (const t of thumbs) {
      console.log(`  ${t.name}`);
    }
    if (thumbs.length > 1) {
      const targetThumb = thumbs[1].name;
      const url = `https://archive.org/download/bleach-temporada-1/${encodeURIComponent(targetThumb)}`;
      console.log('Downloading thumb:', url);
      await download(url, 'scratch/bleach_temp_thumb.jpg');
      console.log('Downloaded scratch/bleach_temp_thumb.jpg');
    }
  }
}

checkBleachThumbs();

