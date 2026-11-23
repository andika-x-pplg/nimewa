const { getItemMetadata } = require('./archive_util');

async function checkMkv() {
  const meta = await getItemMetadata('DeathNoteTV');
  const mkv = meta.files.find(f => f.name === '01 - Rebirth.mkv');
  console.log('MKV info:', mkv);
}

checkMkv();

