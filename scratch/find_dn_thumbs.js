const { getItemMetadata } = require('./archive_util');

async function findSeriesThumbs() {
  const meta = await getItemMetadata('death-note-complete');
  if (meta && meta.files) {
    const thumbs = meta.files.filter(f => f.name.includes('Series/Death Note - 01') && f.name.endsWith('.jpg'));
    console.log('Death Note 01 thumbs:');
    for (const t of thumbs) {
      console.log(`  ${t.name}`);
    }
  }
}

findSeriesThumbs();

