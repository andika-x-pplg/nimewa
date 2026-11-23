const http = require('https');
const fs = require('fs');
const { execSync } = require('child_process');

const ffmpeg = 'E:\\laragon\\www\\node_modules\\ffmpeg-static\\ffmpeg.exe';
// Check ffprobe or use ffmpeg -i
const url = 'https://archive.org/download/claro-video-anime-series-pack-web-dl/Claro%20Video%2FBleach%20%282004%29%2Fs1%20%281%29%2FBleach%20S01E01%20The%20Day%20I%20Became%20a%20Shinigami.mp4';

console.log('Downloading initial 2MB chunk of Claro Bleach S01E01...');
const cmd = `curl.exe -L -s -r 0-2000000 -o scratch/claro_bleach_chunk.mp4 "${url}"`;
execSync(cmd);
console.log('Chunk downloaded, inspecting with ffmpeg...');
try {
  const out = execSync(`"${ffmpeg}" -i scratch/claro_bleach_chunk.mp4`, { stdio: 'pipe' }).toString();
  console.log(out);
} catch (e) {
  console.log(e.stderr ? e.stderr.toString() : e.message);
}
