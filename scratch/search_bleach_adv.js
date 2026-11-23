const { searchArchive, getItemMetadata } = require('./archive_util');

async function main() {
  const queries = [
    'Bleach AND collection:(anime)',
    'Bleach AND mediatype:(movies) AND (sub OR subbed OR subs)',
    'Bleach AND collection:(feature_films)',
    'subject:(Bleach) AND mediatype:(movies)'
  ];

  for (const q of queries) {
    console.log(`\n=================== Query: ${q} ===================`);
    const results = await searchArchive(q, 15);
    for (const r of results) {
      console.log(`- ${r.identifier} | ${r.title} | downloads: ${r.downloads}`);
    }
  }
}

main();

