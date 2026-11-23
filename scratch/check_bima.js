const { searchArchive, getItemMetadata } = require('./archive_util');

async function checkAllBimaUploads() {
  console.log('=== CHECKING ALL BIMA UPLOADS ===');
  const docs = await searchArchive('uploader:bima.gaming21@gmail.com', 500);
  console.log(`Total uploads by Bima: ${docs.length}`);
  for (const d of docs) {
    console.log(`  ${d.identifier} | ${d.title}`);
  }
}

checkAllBimaUploads();

