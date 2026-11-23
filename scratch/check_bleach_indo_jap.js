const { getItemMetadata } = require('./archive_util');

async function check() {
  for (const id of ['bleach-dub-indo_20240802', 'bleach-dual-upscaled-ftw']) {
    console.log(`\n=== Checking ${id} ===`);
    const meta = await getItemMetadata(id);
    console.log('Title:', meta?.metadata?.title);
    console.log('Description:', meta?.metadata?.description);
    const files = meta?.files || [];
    console.log('Files count:', files.length);
    const vids = files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
    console.log('Video count:', vids.length);
    for (const v of vids.slice(0, 25)) {
      console.log('  ', v.name, (v.size/1024/1024).toFixed(1), 'MB');
    }
  }
}

check().catch(console.error);

