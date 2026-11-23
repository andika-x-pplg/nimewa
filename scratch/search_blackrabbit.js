const { searchArchive } = require('./archive_util');

async function searchBlackrabbit() {
  console.log('=== SEARCHING BLACKRABBIT ===');
  const docs = await searchArchive('Blackrabbit', 50);
  console.log(`Found ${docs.length} items:`);
  for (const d of docs) {
    console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
  }
}

searchBlackrabbit();

