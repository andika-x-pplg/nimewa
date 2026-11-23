const https = require('https');
const fs = require('fs');
const { execSync } = require('child_process');

function downloadPartial(url, outputPath, bytes = 15 * 1024 * 1024) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'Range': `bytes=0-${bytes}` } }, (res) => {
      if (res.statusCode === 302 || res.statusCode === 301) {
        return resolve(downloadPartial(res.headers.location, outputPath, bytes));
      }
      const file = fs.createWriteStream(outputPath);
      res.pipe(file);
      file.on('finish', () => {
        file.close();
        resolve();
      });
    }).on('error', reject);
  });
}

async function testVideo(url, label) {
  console.log(`\nTesting: ${label}`);
  const samplePath = `scratch/${label}_sample.mp4`;
  try {
    await downloadPartial(url, samplePath, 15 * 1024 * 1024);
    console.log(`Downloaded sample to ${samplePath}`);
    const probe = execSync(`ffprobe -v error -show_entries stream=index,codec_type,codec_name:stream_tags=language,title -of json "${samplePath}"`).toString();
    console.log('Streams:', probe);

    // Extract a frame
    const framePath = `scratch/${label}_frame.jpg`;
    execSync(`ffmpeg -y -ss 00:03:00 -i "${samplePath}" -vframes 1 "${framePath}" 2>&1`);
    console.log(`Frame extracted to ${framePath}`);
  } catch (e) {
    console.error('Error:', e.message);
  }
}

async function run() {
  await testVideo('https://archive.org/download/death-note-22-guidance/Death%20Note%20-%2001%20-%20Rebirth.mp4', 'dn_guidance_01');
}

run();

