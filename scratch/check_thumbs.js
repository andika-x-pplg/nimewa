const { getItemMetadata } = require('./archive_util');

async function checkThumbs() {
  const meta = await getItemMetadata('death-note-complete');
  if (meta && meta.files) {
    const thumbs = meta.files.filter(f => f.name.includes('.thumbs') || f.name.endsWith('.jpg'));
    console.log(`Found ${thumbs.length} thumbs:`);
    for (const t of thumbs.slice(0, 10)) {
      console.log(`  ${t.name}`);
    }
  }
}

checkThumbs();

