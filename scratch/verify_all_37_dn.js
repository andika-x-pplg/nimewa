const { getItemMetadata } = require('./archive_util');

async function verifyAll37() {
  const meta = await getItemMetadata('death-note-relight-1');
  const mp4s = meta.files.filter(f => f.name.endsWith('.mp4') && !f.name.includes('.thumbs') && !f.name.endsWith('.ia.mp4'));
  console.log(`Original MP4 files count: ${mp4s.length}`);
  
  const episodes = [];
  for (let i = 1; i <= 37; i++) {
    // Find file matching Episode ${i}
    const match = mp4s.find(f => {
      const reg = new RegExp(`^Death Note Episode ${i}\\b`, 'i');
      return reg.test(f.name);
    });
    if (match) {
      episodes.push({ ep: i, file: match.name, sizeMB: (match.size/1024/1024).toFixed(1) });
    } else {
      console.log(`MISSING EPISODE ${i}`);
    }
  }

  console.log(`Found ${episodes.length} / 37 episodes:`);
  for (const e of episodes) {
    console.log(`  Ep ${e.ep}: ${e.file} (${e.sizeMB} MB)`);
  }
}

verifyAll37().catch(console.error);

