const { searchArchive, getItemMetadata } = require('./archive_util');

async function main() {
  const queries = [
    'Dattebayo',
    'DB Bleach',
    'Lunar Bleach',
    '[Lunar] Bleach',
    'Bleach Season 1 Japanese',
    'Bleach ep 01',
    'Bleach 01 mp4'
  ];

  for (const q of queries) {
    console.log(`\n=== Query: ${q} ===`);
    const res = await searchArchive(q, 10);
    for (const r of res) {
      console.log(`- ${r.identifier} | ${r.title} | ${r.downloads}`);
    }
  }
}

main();

