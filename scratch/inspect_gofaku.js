const { getItemMetadata } = require('./archive_util');

async function inspectItem(id) {
  console.log(`\n=== Inspecting: ${id} ===`);
  const meta = await getItemMetadata(id);
  if (!meta || !meta.files) {
    console.log('No metadata or files found');
    return;
  }
  const files = meta.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
  console.log(`Total video files: ${files.length}`);
  for (const f of files.slice(0, 40)) {
    console.log(`- ${f.name} (${(f.size / 1024 / 1024).toFixed(1)} MB, title: ${f.title || ''})`);
  }
}

inspectItem('gofaku.com-dn-04-720p');

