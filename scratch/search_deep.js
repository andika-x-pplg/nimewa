const { searchArchive } = require('./archive_util');

async function searchDeep() {
  const queries = [
    { name: 'Hunter x Hunter 2011', q: '("Hunter x Hunter" OR "HunterHunter" OR "HxH") AND 2011' },
    { name: 'Death Note', q: '"Death Note" AND (episode OR anime OR series OR sub OR complete OR 2006)' },
    { name: 'Bleach Season 1', q: 'Bleach AND (sub OR subbed OR subs OR "season 1" OR s01 OR "001" OR animepahe OR judas)' }
  ];

  for (const item of queries) {
    console.log(`\n================ ${item.name} ================`);
    const docs = await searchArchive(item.q, 50);
    console.log(`Found ${docs.length} items`);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
    }
  }
}

searchDeep();

