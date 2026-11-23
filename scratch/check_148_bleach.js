const { getItemMetadata } = require('./archive_util');

async function check() {
  const meta = await getItemMetadata('148-bleach-720p-sub');
  console.log('Title:', meta?.metadata?.title);
  console.log('Description:', meta?.metadata?.description);
  const files = meta?.files || [];
  console.log('Files count:', files.length);
  for (const f of files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'))) {
    console.log(' ', f.name);
  }
}

check().catch(console.error);

