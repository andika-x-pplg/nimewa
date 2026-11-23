const { getItemMetadata, searchArchive } = require('./archive_util');

async function inspectKnYh01() {
  console.log('=== METADATA OF otakudesu.io-kn-y.-yh-01-720p ===');
  const meta = await getItemMetadata('otakudesu.io-kn-y.-yh-01-720p');
  if (meta && meta.metadata) {
    console.log('Uploader:', meta.metadata.uploader);
    console.log('Creator:', meta.metadata.creator);
    console.log('Publicdate:', meta.metadata.publicdate);
    console.log('Description:', meta.metadata.description);
    console.log('Files:');
    for (const f of meta.files) {
      console.log(`  ${f.name} (${f.size} bytes)`);
    }

    if (meta.metadata.uploader) {
      console.log(`\n=== OTHER UPLOADS BY ${meta.metadata.uploader} ===`);
      const docs = await searchArchive(`uploader:${meta.metadata.uploader}`, 50);
      for (const d of docs) {
        console.log(`  ${d.identifier} | ${d.title}`);
      }
    }
  }
}

inspectKnYh01();

