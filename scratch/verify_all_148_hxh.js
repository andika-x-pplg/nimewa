const { getItemMetadata } = require('./archive_util');

async function verifyAll148HxH() {
  const meta = await getItemMetadata('horrible-subs-hunter-x-hunter-135-480p');
  const mp4s = meta.files.filter(f => f.name.endsWith('.mp4') && !f.name.includes('.thumbs'));
  console.log(`HxH MP4 files count: ${mp4s.length}`);
  
  const missing = [];
  const episodes = [];
  for (let i = 1; i <= 148; i++) {
    const epStr = i < 10 ? `0${i}` : `${i}`;
    const targetName = `[HorribleSubs] Hunter x Hunter - ${epStr} [480p].mp4`;
    const found = mp4s.find(f => f.name.toLowerCase() === targetName.toLowerCase());
    if (found) {
      episodes.push({ ep: i, name: found.name, sizeMB: (found.size/1024/1024).toFixed(1) });
    } else {
      missing.push(i);
    }
  }

  console.log(`Matched ${episodes.length} / 148 episodes.`);
  if (missing.length > 0) {
    console.log(`Missing episodes:`, missing);
  } else {
    console.log('ALL 148 EPISODES ARE PERFECTLY PRESENT AND SEQUENTIAL!');
    console.log('Sample Ep 1:', episodes[0]);
    console.log('Sample Ep 50:', episodes[49]);
    console.log('Sample Ep 100:', episodes[99]);
    console.log('Sample Ep 148:', episodes[147]);
  }
}

verifyAll148HxH().catch(console.error);

