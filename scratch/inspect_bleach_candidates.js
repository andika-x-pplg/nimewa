const { getItemMetadata } = require('./archive_util');

async function inspectItem(id) {
  console.log(`\n================ ${id} ================`);
  const meta = await getItemMetadata(id);
  if (!meta || !meta.files) {
    console.log('No files');
    return;
  }
  console.log('Title:', meta.metadata ? meta.metadata.title : '');
  console.log('Description:', (meta.metadata ? meta.metadata.description : '').slice(0, 200));
  const mp4s = meta.files.filter(f => f.name.endsWith('.mp4') && !f.name.includes('.thumbs'));
  console.log(`MP4 count: ${mp4s.length}`);
  for (const f of mp4s.slice(0, 10)) {
    console.log(`  ${f.name} (${(f.size/1024/1024).toFixed(1)} MB) format=${f.format}`);
  }
}

async function run() {
  await inspectItem('bleach-episode-05');
  await inspectItem('my-japanese-animes-bleach');
  await inspectItem('bleach-001_202210');
}

run();

