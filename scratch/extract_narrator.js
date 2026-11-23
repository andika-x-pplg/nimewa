const ffmpeg = require('ffmpeg-static');
const { execSync } = require('child_process');

for (const s of [110, 115, 120, 125]) {
  try {
    execSync(`"${ffmpeg}" -y -ss ${s} -i "scratch/hxh_horrible_sample.mp4" -vframes 1 "scratch/hxh_${s}.jpg"`, { stdio: 'ignore' });
    console.log('Done', s);
  } catch (e) {
    console.log('Error', s, e.message);
  }
}

