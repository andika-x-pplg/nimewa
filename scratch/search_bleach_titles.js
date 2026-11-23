const { searchArchive } = require('./archive_util');

async function run() {
  const qList = [
    'title:"Bleach Episode"',
    'title:"Bleach - 01"',
    'title:"Bleach Season 1"',
    'title:"Bleach 01"',
    'title:"Bleach 001"',
    'bleach anime sub',
    'bleach anime english sub',
    'bleach substitute shinigami'
  ];
  for (const q of qList) {
    console.log(`\n=== ${q} ===`);
    const list = await searchArchive(q, 10);
    list.forEach(x => console.log(`  ${x.identifier} | ${x.title}`));
  }
}

run();

