const { getItemMetadata } = require('./archive_util');

async function check() {
  const ids = [
    'AnimeRGHunterXHunter2011COMPLETEBD720pHEVCx265KaMi_201811',
    'vodes-hunter-x-hunter-2011-v-2'
  ];
  for (const id of ids) {
    try {
      const meta = await getItemMetadata(id);
      console.log(`=== ${id} ===`);
      console.log('Title:', meta.metadata?.title);
      console.log('Desc:', meta.metadata?.description);
      const files = meta.files || [];
      const mp4s = files.filter(f => f.name.endsWith('.mp4'));
      const mkvs = files.filter(f => f.name.endsWith('.mkv'));
      console.log(`Total files: ${files.length}, MP4s: ${mp4s.length}, MKVs: ${mkvs.length}`);
      if (mp4s.length > 0) {
        console.log('Sample MP4s:', mp4s.slice(0, 3).map(f => f.name));
        console.log('Last MP4:', mp4s[mp4s.length - 1].name);
      }
      if (mkvs.length > 0) {
        console.log('Sample MKVs:', mkvs.slice(0, 3).map(f => f.name));
        console.log('Last MKV:', mkvs[mkvs.length - 1].name);
      }
    } catch (e) {
      console.log(`Error ${id}:`, e.message);
    }
  }
}
check();

