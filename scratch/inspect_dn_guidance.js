const { getItemMetadata } = require('./archive_util');

async function inspectDeathNote() {
  const meta = await getItemMetadata('death-note-22-guidance');
  console.log('Title:', meta.metadata.title);
  console.log('Description:', (meta.metadata.description||'').slice(0, 300));
  const mp4s = meta.files.filter(f => f.name.endsWith('.mp4'));
  console.log('MP4 count:', mp4s.length);
  for (const f of mp4s) {
    console.log(`  ${f.name} (${(f.size/1024/1024).toFixed(1)} MB)`);
  }
}

inspectDeathNote();

