const { searchArchive } = require('./archive_util');

async function searchBleachFansubs() {
  const queries = [
    'Bleach AND (Samehadaku OR Otakudesu OR Oploverz OR Animeindo OR Meownime OR Kusonime OR AWSubs OR Wardhanime)',
    'Bleach AND "sub indo"',
    'Bleach AND "subtitle indonesia"',
    'title:(Bleach) AND (Samehadaku OR Otakudesu OR AWSubs)',
    'description:(Bleach) AND ("sub indo" OR "subtitle indonesia")',
    'Bleach AND ("Judas" OR "AnimePahe" OR "HorribleSubs" OR "SubsPlease" OR "Erai-raws")'
  ];

  for (const q of queries) {
    console.log(`\n=== QUERY: ${q} ===`);
    const docs = await searchArchive(q, 20);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 65)} | ${d.downloads||0} dl`);
    }
  }
}

searchBleachFansubs().catch(console.error);

