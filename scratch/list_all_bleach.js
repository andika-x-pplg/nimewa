const { searchArchive } = require('./archive_util');

async function listAllBleach() {
  const docs = await searchArchive('title:(Bleach) AND mediatype:(movies)', 100);
  console.log(`Found ${docs.length} Bleach movies items:`);
  for (const d of docs) {
    console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 70)} | ${d.downloads||0} dl`);
  }
}

listAllBleach();

