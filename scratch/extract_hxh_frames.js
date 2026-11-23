const ffmpeg = require('ffmpeg-static');
const { execSync } = require('child_process');
const fs = require('fs');

const sample = 'scratch/hxh_horrible_sample.mp4';

// Extract frames at various seconds
for (const sec of [30, 45, 60, 90, 110]) {
  const outJpg = `scratch/hxh_frame_${sec}.jpg`;
  try {
    execSync(`"${ffmpeg}" -y -ss ${sec} -i "${sample}" -vframes 1 "${outJpg}"`, { stdio: 'ignore' });
    if (fs.existsSync(outJpg)) {
      console.log(`Extracted ${outJpg} (${fs.statSync(outJpg).size} bytes)`);
    }
  } catch (e) {
    console.error(`Error at ${sec}:`, e.message);
  }
}

