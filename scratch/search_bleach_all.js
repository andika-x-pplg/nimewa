const { searchArchive, getItemMetadata } = require('./archive_util');

async function searchAllBleachAnimepahe() {
  console.log('=== SEARCHING AnimePahe Bleach ===');
  const queries = [
    'AnimePahe Bleach',
    'AnimePahe_Bleach',
    'AnimePahe Bleach Judas',
    'AnimePahe Bleach 1080p',
    'Bleach Judas 1080p',
    'Bleach Judas',
    'Bleach BD Judas'
  ];

  const seen = new Set();
  for (const q of queries) {
    const docs = await searchArchive(q, 50);
    for (const d of docs) {
      if (!seen.has(d.identifier)) {
        seen.add(d.identifier);
        console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
      }
    }
  }
}

searchAllBleachAnimepahe();

