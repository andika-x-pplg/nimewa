const { execSync } = require('child_process');

const ffmpeg = 'E:\\laragon\\www\\node_modules\\ffmpeg-static\\ffmpeg.exe';

console.log('Extracting frames from Claro Ep 1...');
try {
  // Extract frames at 10s, 20s, 30s
  execSync(`"${ffmpeg}" -y -i scratch/claro_ep1.mp4 -ss 00:00:15 -vframes 1 scratch/claro_frame_15.jpg`, { stdio: 'inherit' });
  execSync(`"${ffmpeg}" -y -i scratch/claro_ep1.mp4 -ss 00:00:35 -vframes 1 scratch/claro_frame_35.jpg`, { stdio: 'inherit' });
  execSync(`"${ffmpeg}" -y -i scratch/claro_ep1.mp4 -ss 00:00:45 -vframes 1 scratch/claro_frame_45.jpg`, { stdio: 'inherit' });
  console.log('Frames extracted.');
  
  // Extract audio
  execSync(`"${ffmpeg}" -y -i scratch/claro_ep1.mp4 -ss 00:00:10 -t 15 -vn -acodec pcm_s16le -ar 16000 scratch/claro_audio.wav`, { stdio: 'inherit' });
  console.log('Audio extracted.');
} catch(e) {
  console.error(e.message);
}

