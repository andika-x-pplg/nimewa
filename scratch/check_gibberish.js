const { getItemMetadata, searchArchive } = require('./archive_util');

async function checkGibberishUploader() {
  const meta = await getItemMetadata('mgamaangasnasigasheeshhh');
  if (meta && meta.metadata) {
    console.log('Uploader of TR S1:', meta.metadata.uploader);
    if (meta.metadata.uploader) {
      const docs = await searchArchive(`uploader:${meta.metadata.uploader}`, 100);
      console.log(`Found ${docs.length} uploads:`);
      for (const d of docs) {
        console.log(`  ${d.identifier} | ${d.title}`);
      }
    }
  }
}

checkGibberishUploader();

