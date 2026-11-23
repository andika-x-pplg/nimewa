const { getItemMetadata } = require('./archive_util');

async function inspectClaro() {
  const meta = await getItemMetadata('claro-video-anime-series-pack-web-dl');
  if (meta && meta.files) {
    const targets = ['bleach', 'death', 'hunter', 'slayer', 'kimetsu'];
    for (const t of targets) {
      const matches = meta.files.filter(f => f.name.toLowerCase().includes(t) && (f.name.endsWith('.mp4') || f.name.endsWith('.mkv')));
      console.log(`\nMatches for "${t}": ${matches.length}`);
      for (const m of matches.slice(0, 10)) {
        console.log(`  ${m.name} (${m.size} bytes)`);
      }
    }
  }
}

inspectClaro();

