const ffmpeg = require('ffmpeg-static');
const { execSync } = require('child_process');

for (let s = 110; s <= 150; s += 5) {
  try {
    execSync(`"${ffmpeg}" -y -ss ${s} -i "scratch/hxh_horrible_sample.mp4" -frames:v 1 -update 1 "scratch/hxh_${s}.jpg"`, { stdio: 'ignore' });
    console.log('Success at', s);
  } catch (e) {
    console.log('Failed at', s);
    break;
  }
}

