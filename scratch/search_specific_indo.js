const { searchArchive } = require('./archive_util');

async function searchSpecificIndo() {
  const queries = [
    'title:("Death Note") AND ("sub indo" OR "subtitle indonesia" OR "indonesia" OR "otakudesu" OR "samehadaku" OR "meownime")',
    'description:("Death Note") AND ("sub indo" OR "subtitle indonesia" OR "otakudesu")',
    'title:(Bleach) AND ("sub indo" OR "subtitle indonesia" OR "indonesia" OR "otakudesu" OR "samehadaku" OR "meownime")',
    'description:(Bleach) AND ("sub indo" OR "subtitle indonesia" OR "otakudesu")',
    '("Hunter x Hunter" OR "HxH") AND ("sub indo" OR "subtitle indonesia" OR "otakudesu" OR "samehadaku")'
  ];

  for (const q of queries) {
    console.log(`\n=== QUERY: ${q} ===`);
    const docs = await searchArchive(q, 20);
    console.log(`Found ${docs.length} items`);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
    }
  }
}

searchSpecificIndo().catch(console.error);

