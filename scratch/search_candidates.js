const { searchArchive, getItemMetadata } = require('./archive_util');

async function main() {
  const queries = [
    // Bleach
    'bleach otakudesu',
    'bleach samehadaku',
    'bleach animepahe',
    'bleach "sub indo"',
    'title:(bleach) AND mediatype:(movies) AND "sub indo"',
    'title:(bleach) AND mediatype:(movies) AND (judas OR animepahe OR otakudesu OR samehadaku)',
    // Death Note
    'death note otakudesu',
    'death note samehadaku',
    'death note animeindo',
    'death note "sub indo"',
    'title:("death note") AND mediatype:(movies) AND "sub indo"',
    'title:("death note") AND mediatype:(movies) AND (judas OR animepahe OR animeindo OR samehadaku OR otakudesu)',
    // Hunter x Hunter 2011
    'hunter x hunter 2011 otakudesu',
    'hunter x hunter 2011 samehadaku',
    'hunter x hunter 2011 animeindo',
    'hunter x hunter 2011 "sub indo"',
    'title:("hunter x hunter") AND mediatype:(movies) AND "sub indo"',
    'title:("hunter x hunter") AND mediatype:(movies) AND (2011) AND (judas OR animepahe OR samehadaku OR otakudesu)'
  ];

  for (const q of queries) {
    const results = await searchArchive(q, 10);
    console.log(`\n=== QUERY: ${q} (${results.length} results) ===`);
    for (const r of results) {
      console.log(`- ${r.identifier} | ${r.title} | downloads: ${r.downloads}`);
    }
  }
}

main().catch(console.error);

