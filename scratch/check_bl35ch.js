const { getMetadata } = require('./archive_util');

async function check() {
  const meta = await getMetadata('bl35ch-s35s0ns-1');
  console.log('Title:', meta.metadata?.title);
  console.log('Description:', meta.metadata?.description);
  const files = meta.files || [];
  console.log(`Total files: ${files.length}`);
  const mp4s = files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
  console.log(`Video files: ${mp4s.length}`);
  for (const f of mp4s.slice(0, 25)) {
    console.log(`- ${f.name} (${(f.size / 1024 / 1024).toFixed(1)} MB)`);
  }
}

check().catch(console.error);
