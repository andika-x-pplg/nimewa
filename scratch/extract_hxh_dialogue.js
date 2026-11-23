const ffmpeg = require('ffmpeg-static');
const { execSync } = require('child_process');
const fs = require('fs');

const sample = 'scratch/hxh_horrible_sample.mp4';

for (const sec of [100, 105, 110, 115, 120, 130]) {
  const outJpg = `scratch/hxh_dialogue_${sec}.jpg`;
  try {
    execSync(`"${ffmpeg}" -y -ss ${sec} -i "${sample}" -vframes 1 "${outJpg}"`, { stdio: 'ignore' });
    if (fs.existsSync(outJpg)) {
      console.log(`Extracted ${outJpg}`);
    }
  } catch (e) {
    console.error(`Error at ${sec}:`, e.message);
  }
}

