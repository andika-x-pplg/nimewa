const { getItemMetadata, searchArchive } = require('./archive_util');

async function inspectOldanimeku() {
  const meta = await getItemMetadata('oldanimeku-hx-h-01-480p');
  if (meta && meta.metadata) {
    console.log('Uploader:', meta.metadata.uploader);
    console.log('Description:', meta.metadata.description);
    const vids = meta.files.filter(f => f.name.endsWith('.mp4'));
    console.log(`Video count: ${vids.length}`);
    for (const v of vids) {
      console.log(`  ${v.name} (${v.size} bytes)`);
    }

    if (meta.metadata.uploader) {
      console.log(`\n=== UPLOADS BY ${meta.metadata.uploader} ===`);
      const docs = await searchArchive(`uploader:${meta.metadata.uploader}`, 50);
      for (const d of docs) {
        console.log(`  ${d.identifier} | ${d.title}`);
      }
    }
  }
}

inspectOldanimeku();

