const { searchArchive } = require('./archive_util');

async function main() {
  const groups = [
    'Dattebayo Bleach',
    'Lunar Bleach',
    'Judas Bleach',
    'Kuro-Hana Bleach',
    'Erai Bleach',
    'Bleach Season 1 Sub',
    'Bleach English Subbed',
    'Bleach Ep 1 Sub',
    'Bleach Episode 1 Sub',
    'Bleach S01 Sub'
  ];

  for (const g of groups) {
    const res = await searchArchive(g, 5);
    console.log(`\n=== Query: ${g} (${res.length}) ===`);
    res.forEach(r => console.log(`  ${r.identifier} | ${r.title}`));
  }
}

main();
