const { searchArchive } = require('./archive_util');

async function main() {
  const indo = [
    'Bleach Samehadaku',
    'Bleach Otakudesu',
    'Bleach Oploverz',
    'Bleach Neonime',
    'Bleach Meownime',
    'Bleach Anoboy',
    'Bleach Sub Indo',
    'Bleach BD Sub Indo',
    'Bleach 720p Sub Indo'
  ];

  for (const q of indo) {
    const res = await searchArchive(q, 5);
    console.log(`\n=== ${q} (${res.length}) ===`);
    res.forEach(r => console.log(`  ${r.identifier} | ${r.title}`));
  }
}

main();

