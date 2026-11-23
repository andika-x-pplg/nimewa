const { getItemMetadata } = require('./archive_util');

async function checkBleach001() {
  console.log('=== CHECKING Bleach001 ===');
  const meta = await getItemMetadata('Bleach001');
  if (meta && meta.files) {
    console.log('Files:');
    for (const f of meta.files) {
      console.log(`  ${f.name} (${f.size} bytes)`);
    }
  }

  console.log('\n=== CHECKING claro-video-anime-series-pack-web-dl ===');
  const metaClaro = await getItemMetadata('claro-video-anime-series-pack-web-dl');
  if (metaClaro && metaClaro.files) {
    const vids = metaClaro.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
    console.log(`Claro video count: ${vids.length}`);
    for (const v of vids.slice(0, 10)) {
      console.log(`  ${v.name} (${v.size} bytes)`);
    }
  }
}

checkBleach001();

