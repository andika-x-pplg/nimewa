const { getItemMetadata } = require('./archive_util');
const { download } = require('./downloader');

async function testAnimePaheBleach() {
  const meta = await getItemMetadata('anime-pahe-bleach-001-bd-1080p-judas');
  if (meta && meta.files) {
    console.log('Files in anime-pahe-bleach-001-bd-1080p-judas:');
    for (const f of meta.files) {
      console.log(`  ${f.name} (${f.size} bytes)`);
    }
    const thumbs = meta.files.filter(f => f.name.includes('.thumbs') || f.name.endsWith('.jpg'));
    console.log('Thumbs:', thumbs.map(t => t.name));
    if (thumbs.length > 1) {
      const targetThumb = thumbs[1].name;
      const url = `https://archive.org/download/anime-pahe-bleach-001-bd-1080p-judas/${encodeURIComponent(targetThumb)}`;
      console.log('Downloading thumb:', url);
      await download(url, 'scratch/pahe_bleach_01.jpg');
      console.log('Downloaded scratch/pahe_bleach_01.jpg');
    }
  }
}

testAnimePaheBleach();

