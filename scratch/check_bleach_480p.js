const { getItemMetadata } = require('./archive_util');

async function checkBleach480p() {
  const meta = await getItemMetadata('Bleach-480p');
  console.log('Title:', meta.metadata ? meta.metadata.title : '');
  console.log('Description:', meta.metadata ? meta.metadata.description : '');
  const files = meta.files ? meta.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv')) : [];
  console.log(`Video files: ${files.length}`);
  for (const f of files.slice(0, 25)) {
    console.log(`  ${f.name} (${(f.size/1024/1024).toFixed(1)} MB) format=${f.format}`);
  }
}

checkBleach480p();

