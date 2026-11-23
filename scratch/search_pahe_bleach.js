const { searchArchive } = require('./archive_util');

async function searchPaheBleach() {
  const queries = [
    'identifier:(*bleach*judas*)',
    'identifier:(*anime-pahe-bleach*)',
    'identifier:(*bleach*1080p*)',
    'identifier:(*bleach*720p*)',
    'title:(Bleach) AND (HorribleSubs OR "Erai-raws" OR AnimePahe OR Judas)'
  ];

  const seen = new Set();
  for (const q of queries) {
    console.log(`\n=== QUERY: ${q} ===`);
    const docs = await searchArchive(q, 30);
    for (const d of docs) {
      if (!seen.has(d.identifier)) {
        seen.add(d.identifier);
        console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 70)} | ${d.downloads||0} dl`);
      }
    }
  }
}

searchPaheBleach().catch(console.error);

