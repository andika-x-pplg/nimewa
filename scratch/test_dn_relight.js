const ffmpeg = require('ffmpeg-static');
const { execSync } = require('child_process');
const fs = require('fs');

async function testRelight() {
  const url = 'https://archive.org/download/death-note-relight-1/Death%20Note%20Episode%201%20Rebirth.mp4';
  console.log('Downloading 8MB sample from:', url);
  try {
    execSync(`curl.exe -L -r 0-8000000 -s -o scratch/dn_relight_sample.mp4 "${url}"`);
    console.log('Downloaded size:', fs.statSync('scratch/dn_relight_sample.mp4').size);

    // Extract frames at 30s, 60s, 90s, 120s
    for (const s of [30, 60, 90, 120]) {
      const fpath = `scratch/dn_relight_${s}.jpg`;
      execSync(`"${ffmpeg}" -y -ss ${s} -i scratch/dn_relight_sample.mp4 -frames:v 1 -update 1 "${fpath}"`, { stdio: 'ignore' });
      if (fs.existsSync(fpath)) {
        console.log(`Extracted frame at ${s}s (${fs.statSync(fpath).size} bytes)`);
      }
    }
  } catch (e) {
    console.error('Error:', e.message);
  }
}

testRelight();

