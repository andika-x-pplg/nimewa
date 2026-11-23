const ffmpeg = require('ffmpeg-static');
const { execSync } = require('child_process');

try {
  const out = execSync(`"${ffmpeg}" -y -ss 105 -i "scratch/hxh_horrible_sample.mp4" -vframes 1 "scratch/hxh_105.jpg"`);
  console.log('Success:', out.toString());
} catch (e) {
  console.log('Stderr:', e.stderr ? e.stderr.toString() : e.message);
}

