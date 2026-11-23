const { searchArchive } = require('./archive_util');

async function searchSubbed() {
  const queries = [
    'Bleach AND (subbed OR "eng sub" OR "english subtitles" OR "japanese audio") AND mediatype:movies',
    'title:(Bleach) AND (subbed OR "eng sub" OR "english sub" OR sub)',
    '"Death Note" AND ("eng sub" OR "english sub" OR subbed OR "japanese audio") AND mediatype:movies',
    'title:("Death Note") AND (subbed OR "eng sub" OR "english sub")'
  ];

  for (const q of queries) {
    console.log(`\n=== QUERY: ${q} ===`);
    const docs = await searchArchive(q, 25);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 65)} | ${d.downloads||0} dl`);
    }
  }
}

searchSubbed().catch(console.error);

