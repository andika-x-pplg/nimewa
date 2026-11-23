const { searchArchive, getItemMetadata } = require('./archive_util');

async function searchKnyYh() {
  console.log('=== SEARCHING KNY YUUKAKU-HEN ON OTAKUDESU ===');
  const queries = [
    'identifier:(*kn-y*yh*)',
    'identifier:(*kn-y*)',
    'identifier:(*yuukaku*)',
    'Kn Y. Yh',
    'Kn Y Yh'
  ];

  for (const q of queries) {
    console.log(`\nQuery: ${q}`);
    const docs = await searchArchive(q, 30);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${d.title}`);
    }
  }
}

searchKnyYh();

