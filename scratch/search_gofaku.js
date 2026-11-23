const { searchArchive, getItemMetadata } = require('./archive_util');

async function searchGofaku() {
  console.log('=== SEARCHING GOFAKU ===');
  const docs = await searchArchive('gofaku', 50);
  for (const d of docs) {
    console.log(`${d.identifier} | ${d.title}`);
  }
}

searchGofaku();

