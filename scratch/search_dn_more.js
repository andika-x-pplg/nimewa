const { searchArchive, getItemMetadata } = require('./archive_util');

async function searchDeathNote() {
  const queries = [
    'title:("Death Note") AND (horriblesubs OR animepahe OR judas OR subbed OR subtitled)',
    '"Death Note" AND "01" AND (720p OR 480p OR 1080p) AND mediatype:movies',
    'title:("Death Note") AND mediatype:movies AND (japanese OR sub)'
  ];

  for (const q of queries) {
    console.log(`\n=== QUERY: ${q} ===`);
    const docs = await searchArchive(q, 15);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
    }
  }
}

searchDeathNote().catch(console.error);

