const { getItemMetadata } = require('./archive_util');

async function checkBleachEps() {
  for (let i = 1; i <= 20; i++) {
    const id = `Bleach${String(i).padStart(3, '0')}`;
    const meta = await getItemMetadata(id);
    if (!meta || !meta.files) {
      console.log(`${id}: NOT FOUND`);
    } else {
      const vids = meta.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv') || f.name.endsWith('.avi'));
      console.log(`${id} (${meta.metadata ? meta.metadata.title : ''}): ${vids.map(v => v.name).join(', ')}`);
    }
  }
}

checkBleachEps().catch(console.error);

