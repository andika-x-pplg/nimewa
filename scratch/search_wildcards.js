const { searchArchive, getItemMetadata } = require('./archive_util');

async function searchWildcardIdentifiers() {
  const patterns = [
    'identifier:(anime-pahe-bleach*)',
    'identifier:(anime-pahe-hunter*)',
    'identifier:(anime-pahe-death*)',
    'identifier:(anime-pahe-demon*)',
    'identifier:(anime-pahe-kimetsu*)',
    'identifier:(horriblesubs-hunter*)',
    'identifier:(horriblesubs-bleach*)',
    'identifier:(horriblesubs-death*)',
    'identifier:(horriblesubs-kimetsu*)',
    'identifier:(horriblesubs-demon*)',
    'identifier:(*otakudesu*)',
    'identifier:(*samehadaku*)',
    'identifier:(*oploverz*)'
  ];

  for (const p of patterns) {
    console.log(`\n=== PATTERN: ${p} ===`);
    const docs = await searchArchive(p, 50);
    console.log(`Found ${docs.length} items`);
    for (const d of docs.slice(0, 10)) {
      console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 50)} | ${d.downloads||0} dl`);
    }
  }
}

searchWildcardIdentifiers();

