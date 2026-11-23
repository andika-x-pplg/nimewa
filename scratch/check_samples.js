const { execSync } = require('child_process');
const fs = require('fs');

const items = [
  {
    name: 'dn_guidance',
    url: 'https://archive.org/download/death-note-22-guidance/Death%20Note%20-%2001%20-%20Rebirth.mp4'
  },
  {
    name: 'hxh_horrible',
    url: 'https://archive.org/download/horrible-subs-hunter-x-hunter-135-480p/%5BHorribleSubs%5D%20Hunter%20x%20Hunter%20-%2001%20%5B480p%5D.mp4'
  },
  {
    name: 'bleach_complete',
    url: 'https://archive.org/download/bleach-complete/Bleach/S01/Bleach%20-%20S01E01.mp4'
  }
];

for (const item of items) {
  const name = item.name;
  const url = item.url;
  const outMp4 = `scratch/${name}_sample.mp4`;
  console.log(`\n================ Testing ${name} ================`);
  try {
    execSync(`curl.exe -L -r 0-12000000 -s -o "${outMp4}" "${url}"`, { timeout: 30000 });
    const size = fs.existsSync(outMp4) ? fs.statSync(outMp4).size : 0;
    console.log(`Downloaded size: ${size} bytes`);
    if (size > 1000) {
      try {
        const probe = execSync(`ffprobe -v error -show_entries stream=index,codec_type,codec_name:stream_tags=language,title -of json "${outMp4}"`).toString();
        const data = JSON.parse(probe);
        for (const s of data.streams || []) {
          console.log('  Stream:', s);
        }
      } catch (pe) {
        console.log('  ffprobe error:', pe.message);
      }

      for (const ss of ['00:02:00', '00:04:30']) {
        const fpath = `scratch/${name}_${ss.replace(/:/g, '_')}.jpg`;
        try {
          execSync(`ffmpeg -y -ss ${ss} -i "${outMp4}" -vframes 1 "${fpath}"`);
          if (fs.existsSync(fpath)) {
            console.log(`  Frame at ${ss}: ${fs.statSync(fpath).size} bytes`);
          }
        } catch (fe) {
          console.log(`  ffmpeg error at ${ss}:`, fe.message);
        }
      }
    }
  } catch (e) {
    console.error('Error:', e.message);
  }
}

