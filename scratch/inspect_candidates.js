const { getItemMetadata, searchArchive } = require('./archive_util');

async function inspectCandidate(id) {
  console.log(`\n================ ${id} ================`);
  const meta = await getItemMetadata(id);
  if (!meta || !meta.files) {
    console.log('No files');
    return;
  }
  console.log('Title:', meta.metadata ? meta.metadata.title : '');
  console.log('Description:', (meta.metadata ? meta.metadata.description : '').slice(0, 150));
  const mp4s = meta.files.filter(f => f.name.endsWith('.mp4') && !f.name.includes('.thumbs'));
  console.log(`MP4 count: ${mp4s.length}`);
  for (const f of mp4s.slice(0, 5)) {
    console.log(`  ${f.name} (${(f.size/1024/1024).toFixed(1)} MB)`);
  }
  if (mp4s.length > 5) {
    console.log(`  ...`);
    console.log(`  ${mp4s[mp4s.length-1].name} (${(mp4s[mp4s.length-1].size/1024/1024).toFixed(1)} MB)`);
  }
}

async function run() {
  // Death Note candidates
  await inspectCandidate('DeathNoteTV');
  await inspectCandidate('Death_Note1');
  await inspectCandidate('death-note_1080p_2007');
  
  // Bleach candidates
  await inspectCandidate('bleach001_20190808');
  await inspectCandidate('claro-video-anime-series-pack-web-dl');
}

run().catch(console.error);

