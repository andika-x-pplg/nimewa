const { searchArchive } = require('./archive_util');

async function searchAnimePahe() {
  console.log('=== SEARCHING ANIMEPAHE ON ARCHIVE ===');
  const queries = [
    'AnimePahe Death Note',
    'AnimePahe Hunter x Hunter',
    'AnimePahe Bleach',
    'AnimePahe Kimetsu',
    'AnimePahe Demon Slayer',
    'AnimePahe Yuukaku',
    'AnimePahe Entertainment District'
  ];

  for (const q of queries) {
    console.log(`\nQuery: ${q}`);
    const docs = await searchArchive(q, 10);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
    }
  }
}

searchAnimePahe();

