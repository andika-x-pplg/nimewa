const { searchArchive } = require('./archive_util');

async function checkAllIndoItems() {
  const queries = [
    'identifier:(*otakudesu*)',
    'identifier:(*samehadaku*)',
    'identifier:(*oploverz*)'
  ];

  for (const q of queries) {
    console.log(`\n=== QUERY: ${q} ===`);
    const docs = await searchArchive(q, 100);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)}`);
    }
  }
}

checkAllIndoItems();

