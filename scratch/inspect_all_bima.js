const { getItemMetadata, searchArchive } = require('./archive_util');

async function inspectAllBimaFiles() {
  const docs = await searchArchive('uploader:bima.gaming21@gmail.com', 60);
  console.log(`Checking ${docs.length} items from Bima:`);
  for (const d of docs) {
    const meta = await getItemMetadata(d.identifier);
    if (meta && meta.files) {
      const vids = meta.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
      const sample = vids.slice(0, 3).map(v => v.name).join(', ');
      console.log(`[${d.identifier}] (${vids.length} vids): ${sample}`);
    }
  }
}

inspectAllBimaFiles();

