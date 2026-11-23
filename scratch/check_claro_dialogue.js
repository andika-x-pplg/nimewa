const https = require('https');
const http = require('http');
const fs = require('fs');
const { execSync } = require('child_process');

function downloadPartial(url, dest, maxBytes = 15 * 1024 * 1024) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const client = parsed.protocol === 'https:' ? https : http;
    const req = client.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return resolve(downloadPartial(res.headers.location, dest, maxBytes));
      }
      if (res.statusCode !== 200 && res.statusCode !== 206) {
        return reject(new Error(`HTTP ${res.statusCode}`));
      }
      const out = fs.createWriteStream(dest);
      let received = 0;
      res.on('data', (chunk) => {
        received += chunk.length;
        out.write(chunk);
        if (received >= maxBytes) {
          res.destroy();
          out.end();
          resolve();
        }
      });
      res.on('end', () => {
        out.end();
        resolve();
      });
      res.on('error', reject);
    });
    req.on('error', reject);
  });
}

async function main() {
  const file = 'Claro Video/Bleach (2004)/s1 (1)/Bleach S01E01 The Day I Became a Shinigami.mp4';
  const url = `https://archive.org/download/claro-video-anime-series-pack-web-dl/${encodeURIComponent(file).replace(/%2F/g, '/')}`;
  console.log('Downloading 15MB...');
  await downloadPartial(url, 'scratch/claro_ep1_15mb.mp4', 15 * 1024 * 1024);
  console.log('Downloaded size:', fs.statSync('scratch/claro_ep1_15mb.mp4').size);

  const ffmpeg = 'E:\\laragon\\www\\node_modules\\ffmpeg-static\\ffmpeg.exe';
  execSync(`"${ffmpeg}" -y -i scratch/claro_ep1_15mb.mp4 -ss 00:02:15 -vframes 1 scratch/claro_dialogue1.jpg`, { stdio: 'inherit' });
  execSync(`"${ffmpeg}" -y -i scratch/claro_ep1_15mb.mp4 -ss 00:02:30 -vframes 1 scratch/claro_dialogue2.jpg`, { stdio: 'inherit' });
  execSync(`"${ffmpeg}" -y -i scratch/claro_ep1_15mb.mp4 -ss 00:02:45 -vframes 1 scratch/claro_dialogue3.jpg`, { stdio: 'inherit' });
  execSync(`"${ffmpeg}" -y -i scratch/claro_ep1_15mb.mp4 -ss 00:02:10 -t 30 -vn -acodec pcm_s16le -ar 16000 scratch/claro_dialogue.wav`, { stdio: 'inherit' });
  console.log('Done extracting.');
}

main().catch(console.error);

