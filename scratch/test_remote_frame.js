const ffmpeg = require('ffmpeg-static');
const { execSync } = require('child_process');
const fs = require('fs');

async function testRemote(url, label) {
  console.log(`\nTesting ${label}: ${url}`);
  const outJpg = `scratch/${label}.jpg`;
  try {
    execSync(`"${ffmpeg}" -y -ss 00:03:30 -i "${url}" -frames:v 1 -update 1 "${outJpg}"`, { stdio: 'inherit' });
    if (fs.existsSync(outJpg)) {
      console.log(`Frame created: ${outJpg} (${fs.statSync(outJpg).size} bytes)`);
    }
  } catch (e) {
    console.error('Frame error:', e.message);
  }

  // Extract 5 seconds of audio to wav
  const outWav = `scratch/${label}.wav`;
  try {
    execSync(`"${ffmpeg}" -y -ss 00:03:30 -t 5 -i "${url}" -ac 1 -ar 16000 "${outWav}"`, { stdio: 'inherit' });
    if (fs.existsSync(outWav)) {
      console.log(`Audio created: ${outWav} (${fs.statSync(outWav).size} bytes)`);
    }
  } catch (e) {
    console.error('Audio error:', e.message);
  }
}

async function run() {
  await testRemote('https://archive.org/download/death-note-complete-2006-2007/E01%20-%20Rebirth.mp4', 'dn_comp_e01');
}

run();

