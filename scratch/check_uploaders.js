const { getItemMetadata, searchArchive } = require('./archive_util');

async function checkUploaders() {
  const gMeta = await getItemMetadata('gofaku.com-dn-04-720p');
  console.log('gofaku uploader:', gMeta.metadata ? gMeta.metadata.uploader : 'unknown');

  // Let's search items by uploader:albertusivan44@gmail.com or other items
  if (gMeta.metadata && gMeta.metadata.uploader) {
    const uploader = gMeta.metadata.uploader;
    const docs = await searchArchive(`uploader:("${uploader}")`, 50);
    console.log(`\nItems by ${uploader} (${docs.length}):`);
    for (const d of docs) {
      console.log(`- ${d.identifier} | ${d.title}`);
    }
  }

  const ivanDocs = await searchArchive('uploader:("albertusivan44@gmail.com")', 50);
  console.log(`\nItems by albertusivan44@gmail.com (${ivanDocs.length}):`);
  for (const d of ivanDocs) {
    console.log(`- ${d.identifier} | ${d.title}`);
  }
}

checkUploaders();

