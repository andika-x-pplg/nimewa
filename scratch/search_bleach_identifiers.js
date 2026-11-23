const { searchArchive, getItemMetadata } = require('./archive_util');

async function main() {
  console.log('Checking Bleach002, Bleach003...');
  for (const id of ['Bleach002', 'Bleach003', 'Bleach005']) {
    const meta = await getItemMetadata(id);
    console.log(`- ${id}: title=${meta.metadata?.title}, uploader=${meta.metadata?.uploader}`);
    const files = meta.files || [];
    for (const f of files.filter(f => f.name.endsWith('.mp4'))) {
      console.log(`    ${f.name}`);
    }
  }

  console.log('\nSearching identifier:(*bleach*) AND mediatype:(movies)...');
  const results = await searchArchive('identifier:(*bleach*) AND mediatype:(movies)', 50);
  for (const r of results) {
    console.log(`  ${r.identifier} | ${r.title}`);
  }
}

main();

