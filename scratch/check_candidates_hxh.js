const { getItemMetadata } = require('./archive_util');

async function check() {
  const ids = ['hxh075', 'hxh-Completa', 'b-hxh-s-01-e-04'];
  for (const id of ids) {
    try {
      const meta = await getItemMetadata(id);
      console.log(`=== ${id} ===`);
      console.log('Title:', meta.metadata?.title);
      console.log('Desc:', meta.metadata?.description);
      const files = meta.files || [];
      const mp4s = files.filter(f => f.name.endsWith('.mp4'));
      console.log(`Total files: ${files.length}, MP4s: ${mp4s.length}`);
      if (mp4s.length > 0) {
        console.log('Sample MP4s:', mp4s.slice(0, 3).map(f => f.name));
        console.log('Last MP4:', mp4s[mp4s.length - 1].name);
      }
    } catch (e) {
      console.log(`Error ${id}:`, e.message);
    }
  }
}
check();

