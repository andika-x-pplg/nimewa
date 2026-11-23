const { searchArchive, getItemMetadata } = require('./archive_util');

async function searchBleachMore() {
  console.log('=== SEARCHING BLEACH EXTENSIVE ===');
  const queries = [
    'Bleach s01e01 mediatype:movies',
    'Bleach s01e02 mediatype:movies',
    'Bleach "001" sub mediatype:movies',
    'Bleach "01" sub mediatype:movies',
    'Bleach season 1 sub mediatype:movies',
    'Bleach ep 01 mediatype:movies',
    'Bleach episode 01 mediatype:movies',
    'Bleach episode 1 sub mediatype:movies'
  ];

  const seen = new Set();
  for (const q of queries) {
    const docs = await searchArchive(q, 15);
    for (const d of docs) {
      if (!seen.has(d.identifier)) {
        seen.add(d.identifier);
        console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
      }
    }
  }
}

searchBleachMore();

