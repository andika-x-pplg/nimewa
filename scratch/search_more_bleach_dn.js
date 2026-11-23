const { searchArchive } = require('./archive_util');

async function searchMore() {
  const queries = [
    'Bleach AND ("season 1" OR "season 01" OR "substitute") AND mediatype:movies',
    'Bleach AND ("episodes 1" OR "episodes 01" OR "01-20" OR "001-020") AND mediatype:movies',
    'title:(Bleach) AND mediatype:(movies) AND (720p OR 480p OR 1080p)',
    'Death Note AND ("complete" OR "all episodes" OR "01-37" OR "season 1") AND mediatype:movies',
    'title:("Death Note") AND (720p OR 480p OR 1080p) AND mediatype:movies'
  ];

  for (const q of queries) {
    console.log(`\n=== QUERY: ${q} ===`);
    const docs = await searchArchive(q, 20);
    console.log(`Found ${docs.length} items:`);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
    }
  }
}

searchMore().catch(console.error);

