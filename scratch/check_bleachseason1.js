const { getItemMetadata } = require('./archive_util');

async function checkBleachSeason1() {
  const meta = await getItemMetadata('bleachseason1');
  console.log('Title:', meta.metadata ? meta.metadata.title : '');
  console.log('Description:', meta.metadata ? meta.metadata.description : '');
  const files = meta.files ? meta.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv')) : [];
  console.log('Files count:', files.length);
  for (const f of files) {
    console.log(`  ${f.name} (${(f.size/1024/1024).toFixed(1)} MB)`);
  }
}

checkBleachSeason1();

