const { getItemMetadata } = require('./archive_util');

async function checkMetadata(id) {
  const meta = await getItemMetadata(id);
  const ep1 = meta.files.find(f => f.name.includes('01') && f.name.endsWith('.mp4'));
  console.log(`Metadata for ${id} ep1:`, ep1);
}

checkMetadata('DeathNoteTV');
checkMetadata('death-note_1080p_2007');

